extends Node
class_name EnemySquadCoordinator
## Deterministic, encounter-local role and approach-slot coordination.
signal attack_slot_granted(member: Node3D, target: Node3D)
signal attack_slot_released(member: Node3D, target: Node3D)
signal tactical_role_assigned(member: Node3D, role: int)
signal approach_slot_assigned(member: Node3D, target: Node3D, slot_index: int)
signal member_retreat_changed(member: Node3D, target: Node3D, retreating: bool)

enum TacticalRole { PURSUER, SKIRMISHER, RANGED }

@export_range(1, 16, 1) var max_simultaneous_attackers_per_target: int = 2
@export_range(1, 16, 1) var max_pursuers: int = 4
@export_range(1, 8, 1) var max_skirmishers: int = 2
@export_range(1, 8, 1) var max_ranged: int = 2
@export_range(1.0, 20.0, 0.5) var approach_radius: float = 3.5
@export_range(4, 16, 1) var approach_sector_count: int = 8

var _role_by_member: Dictionary = {}
var _members_by_role: Dictionary = {}
var _attackers_by_target: Dictionary = {}
var _target_by_attacker: Dictionary = {}
var _approach_by_member: Dictionary = {}
var _approach_by_target: Dictionary = {}
var _retreating_by_target: Dictionary = {}

func register_member(member: Node3D, engagement_policy: int = 0) -> int:
	if not is_instance_valid(member):
		return TacticalRole.PURSUER
	var member_id := member.get_instance_id()
	if _role_by_member.has(member_id):
		return int(_role_by_member[member_id])
	var requested := clampi(engagement_policy, TacticalRole.PURSUER, TacticalRole.RANGED)
	var role := _select_role(requested)
	_role_by_member[member_id] = role
	var bucket: Array = _members_by_role.get(role, [])
	bucket.append(member_id)
	_members_by_role[role] = bucket
	tactical_role_assigned.emit(member, role)
	return role

func unregister_member(member: Node3D) -> void:
	if not is_instance_valid(member):
		return
	release_member_claims(member)
	var member_id := member.get_instance_id()
	if not _role_by_member.has(member_id):
		return
	var role := int(_role_by_member[member_id])
	_role_by_member.erase(member_id)
	var bucket: Array = _members_by_role.get(role, [])
	bucket.erase(member_id)
	if bucket.is_empty():
		_members_by_role.erase(role)
	else:
		_members_by_role[role] = bucket

func get_member_role(member: Node3D) -> int:
	if not is_instance_valid(member):
		return TacticalRole.PURSUER
	return int(_role_by_member.get(member.get_instance_id(), TacticalRole.PURSUER))

func has_member_claims(member: Node3D) -> bool:
	if not is_instance_valid(member):
		return false
	var member_id := member.get_instance_id()
	if _target_by_attacker.has(member_id) or _approach_by_member.has(member_id):
		return true
	for bucket: Array in _retreating_by_target.values():
		if bucket.has(member_id):
			return true
	return false

func get_role_count(role: int) -> int:
	_cleanup_all()
	return (_members_by_role.get(role, []) as Array).size()

func request_attack_slot(member: Node3D, target: Node3D) -> bool:
	if not is_instance_valid(member) or not is_instance_valid(target) or member == target:
		return false
	if max_simultaneous_attackers_per_target < 1:
		return false
	var member_id := member.get_instance_id()
	var target_id := target.get_instance_id()
	if _target_by_attacker.has(member_id):
		if int(_target_by_attacker[member_id]) == target_id:
			return true
		release_attack_slot(member)
	_cleanup_target(target_id)
	var bucket: Array = _attackers_by_target.get(target_id, [])
	if bucket.size() >= max_simultaneous_attackers_per_target:
		return false
	bucket.append(member_id)
	_attackers_by_target[target_id] = bucket
	_target_by_attacker[member_id] = target_id
	attack_slot_granted.emit(member, target)
	return true

func release_attack_slot(member: Node3D) -> void:
	if not is_instance_valid(member):
		return
	var member_id := member.get_instance_id()
	if not _target_by_attacker.has(member_id):
		return
	var target_id := int(_target_by_attacker[member_id])
	_target_by_attacker.erase(member_id)
	var bucket: Array = _attackers_by_target.get(target_id, [])
	bucket.erase(member_id)
	if bucket.is_empty():
		_attackers_by_target.erase(target_id)
	else:
		_attackers_by_target[target_id] = bucket
	var target := instance_from_id(target_id) as Node3D
	if is_instance_valid(target):
		attack_slot_released.emit(member, target)

func release_target_claim(member: Node3D) -> void:
	if not is_instance_valid(member):
		return
	release_attack_slot(member)
	var member_id := member.get_instance_id()
	if not _approach_by_member.has(member_id):
		return
	var claim: Dictionary = _approach_by_member[member_id]
	var target_id := int(claim.get("target_id", 0))
	var slot_index := int(claim.get("slot", -1))
	_approach_by_member.erase(member_id)
	var slots: Dictionary = _approach_by_target.get(target_id, {})
	if int(slots.get(slot_index, 0)) == member_id:
		slots.erase(slot_index)
	if slots.is_empty():
		_approach_by_target.erase(target_id)
	else:
		_approach_by_target[target_id] = slots

func release_member_claims(member: Node3D) -> void:
	if not is_instance_valid(member):
		return
	release_target_claim(member)
	var member_id := member.get_instance_id()
	for target_key: Variant in _retreating_by_target.keys():
		var bucket: Array = _retreating_by_target[target_key]
		bucket.erase(member_id)
		if bucket.is_empty():
			_retreating_by_target.erase(target_key)
		else:
			_retreating_by_target[target_key] = bucket

func get_approach_position(member: Node3D, target: Node3D, role: int, preferred_distance: float = -1.0) -> Vector3:
	if not is_instance_valid(member) or not is_instance_valid(target):
		return Vector3.ZERO
	var member_id := member.get_instance_id()
	if not _role_by_member.has(member_id):
		return target.global_position
	var target_id := target.get_instance_id()
	var slot_index := -1
	if _approach_by_member.has(member_id):
		var existing: Dictionary = _approach_by_member[member_id]
		if int(existing.get("target_id", 0)) == target_id:
			slot_index = int(existing.get("slot", -1))
		else:
			release_target_claim(member)
	if slot_index < 0:
		slot_index = _reserve_approach_slot(member_id, target_id, role)
		if slot_index < 0:
			return target.global_position
		_approach_by_member[member_id] = {"target_id": target_id, "slot": slot_index}
		approach_slot_assigned.emit(member, target, slot_index)
	var radius := approach_radius if preferred_distance <= 0.0 else maxf(preferred_distance, approach_radius)
	var sector_angle := TAU / float(maxi(approach_sector_count, 1))
	var forward := -target.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var angle := float(slot_index) * sector_angle
	var radial := Vector3(sin(angle), 0.0, -cos(angle))
	var facing_basis := Basis(Vector3.UP, target.global_rotation.y)
	var direction := facing_basis * radial
	return target.global_position + direction * radius

func set_member_retreating(member: Node3D, target: Node3D, retreating: bool) -> void:
	if not is_instance_valid(member) or not is_instance_valid(target):
		return
	var target_id := target.get_instance_id()
	var member_id := member.get_instance_id()
	var bucket: Array = _retreating_by_target.get(target_id, [])
	if retreating:
		if not bucket.has(member_id):
			bucket.append(member_id)
		_retreating_by_target[target_id] = bucket
	else:
		bucket.erase(member_id)
		if bucket.is_empty():
			_retreating_by_target.erase(target_id)
		else:
			_retreating_by_target[target_id] = bucket
	member_retreat_changed.emit(member, target, retreating)

func get_retreating_count(target: Node3D) -> int:
	if not is_instance_valid(target):
		return 0
	_cleanup_target(target.get_instance_id())
	return (_retreating_by_target.get(target.get_instance_id(), []) as Array).size()

func get_active_attacker_count(target: Node3D) -> int:
	if not is_instance_valid(target):
		return 0
	_cleanup_target(target.get_instance_id())
	return (_attackers_by_target.get(target.get_instance_id(), []) as Array).size()

func has_attack_slot(member: Node3D) -> bool:
	return is_instance_valid(member) and _target_by_attacker.has(member.get_instance_id())

func _select_role(requested: int) -> int:
	if _role_count(requested) < _role_capacity(requested):
		return requested
	var fallback_order: Array[int] = []
	match requested:
		TacticalRole.PURSUER: fallback_order = [TacticalRole.SKIRMISHER, TacticalRole.RANGED, TacticalRole.PURSUER]
		TacticalRole.SKIRMISHER: fallback_order = [TacticalRole.PURSUER, TacticalRole.RANGED, TacticalRole.SKIRMISHER]
		_: fallback_order = [TacticalRole.SKIRMISHER, TacticalRole.PURSUER, TacticalRole.RANGED]
	for candidate: int in fallback_order:
		if _role_count(candidate) < _role_capacity(candidate):
			return candidate
	var least_populated := requested
	for candidate: int in fallback_order:
		if _role_count(candidate) < _role_count(least_populated):
			least_populated = candidate
	return least_populated

func _role_count(role: int) -> int:
	return (_members_by_role.get(role, []) as Array).size()

func _role_capacity(role: int) -> int:
	match role:
		TacticalRole.SKIRMISHER: return maxi(max_skirmishers, 1)
		TacticalRole.RANGED: return maxi(max_ranged, 1)
		_: return maxi(max_pursuers, 1)

func _reserve_approach_slot(member_id: int, target_id: int, role: int) -> int:
	_cleanup_target(target_id)
	var occupied: Dictionary = _approach_by_target.get(target_id, {})
	var preferred: Array[int] = []
	match role:
		TacticalRole.SKIRMISHER: preferred = [2, 6, 1, 3, 5, 7, 0, 4]
		TacticalRole.RANGED: preferred = [4, 0, 2, 6, 1, 3, 5, 7]
		_: preferred = [0, 4, 2, 6, 1, 3, 5, 7]
	for index: int in range(approach_sector_count):
		var candidate := preferred[index % preferred.size()] % maxi(approach_sector_count, 1)
		if not occupied.has(candidate):
			occupied[candidate] = member_id
			_approach_by_target[target_id] = occupied
			return candidate
	return -1

func _cleanup_target(target_id: int) -> void:
	var attackers: Array = _attackers_by_target.get(target_id, [])
	for index: int in range(attackers.size() - 1, -1, -1):
		var member_id := int(attackers[index])
		var member := instance_from_id(member_id) as Node3D
		if not is_instance_valid(member) or int(_target_by_attacker.get(member_id, -1)) != target_id:
			attackers.remove_at(index)
			_target_by_attacker.erase(member_id)
	if attackers.is_empty():
		_attackers_by_target.erase(target_id)
	else:
		_attackers_by_target[target_id] = attackers
	var slots: Dictionary = _approach_by_target.get(target_id, {})
	for key: Variant in slots.keys():
		var member_id := int(slots[key])
		var member := instance_from_id(member_id) as Node3D
		if not is_instance_valid(member):
			slots.erase(key)
			_approach_by_member.erase(member_id)
	if slots.is_empty():
		_approach_by_target.erase(target_id)
	else:
		_approach_by_target[target_id] = slots
	var retreaters: Array = _retreating_by_target.get(target_id, [])
	for index: int in range(retreaters.size() - 1, -1, -1):
		var member := instance_from_id(int(retreaters[index])) as Node3D
		if not is_instance_valid(member):
			retreaters.remove_at(index)
	if retreaters.is_empty():
		_retreating_by_target.erase(target_id)
	else:
		_retreating_by_target[target_id] = retreaters

func _cleanup_all() -> void:
	for target_key: Variant in _attackers_by_target.keys():
		_cleanup_target(int(target_key))
	for target_key: Variant in _approach_by_target.keys():
		_cleanup_target(int(target_key))
	for role_key: Variant in _members_by_role.keys():
		var members: Array = _members_by_role[role_key]
		for index: int in range(members.size() - 1, -1, -1):
			var member_id := int(members[index])
			var member := instance_from_id(member_id) as Node3D
			if not is_instance_valid(member):
				members.remove_at(index)
				_role_by_member.erase(member_id)
		if members.is_empty():
			_members_by_role.erase(role_key)
		else:
			_members_by_role[role_key] = members
