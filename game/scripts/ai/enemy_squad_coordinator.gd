extends Node
class_name EnemySquadCoordinator
## Deterministic per-target melee attack-slot arbitration for a local enemy squad.
signal attack_slot_granted(member: Node3D, target: Node3D)
signal attack_slot_released(member: Node3D, target: Node3D)
signal role_assigned(member: Node3D, target: Node3D, role: int)
signal member_retreat_changed(member: Node3D, target: Node3D, retreating: bool)

@export_range(1, 16, 1) var max_simultaneous_attackers_per_target: int = 2

var _attackers_by_target: Dictionary = {}
var _target_by_member: Dictionary = {}
var _roles_by_target: Dictionary = {}
var _target_by_role_member: Dictionary = {}
var _retreating_by_target: Dictionary = {}
@export_range(1, 8, 1) var max_flankers_per_target: int = 1
@export_range(1, 8, 1) var max_support_per_target: int = 1

func request_attack_slot(member: Node3D, target: Node3D) -> bool:
	if not is_instance_valid(member) or not is_instance_valid(target) or member == target:
		return false
	if max_simultaneous_attackers_per_target < 1:
		return false
	var member_id: int = member.get_instance_id()
	var target_id: int = target.get_instance_id()
	if _target_by_member.has(member_id):
		if int(_target_by_member[member_id]) == target_id:
			return true
		release_attack_slot(member)
	_cleanup_target(target_id)
	var bucket: Array = _attackers_by_target.get(target_id, [])
	if bucket.size() >= max_simultaneous_attackers_per_target:
		return false
	bucket.append(member_id)
	_attackers_by_target[target_id] = bucket
	_target_by_member[member_id] = target_id
	attack_slot_granted.emit(member, target)
	return true

func release_attack_slot(member: Node3D) -> void:
	if not is_instance_valid(member):
		return
	var member_id: int = member.get_instance_id()
	if not _target_by_member.has(member_id):
		return
	var target_id: int = int(_target_by_member[member_id])
	_target_by_member.erase(member_id)
	var bucket: Array = _attackers_by_target.get(target_id, [])
	for index: int in range(bucket.size() - 1, -1, -1):
		if int(bucket[index]) == member_id:
			bucket.remove_at(index)
	if bucket.is_empty():
		_attackers_by_target.erase(target_id)
	else:
		_attackers_by_target[target_id] = bucket
	var target := instance_from_id(target_id) as Node3D
	if is_instance_valid(target):
		attack_slot_released.emit(member, target)

func get_active_attacker_count(target: Node3D) -> int:
	if not is_instance_valid(target):
		return 0
	_cleanup_target(target.get_instance_id())
	var bucket: Array = _attackers_by_target.get(target.get_instance_id(), [])
	return bucket.size()

func has_attack_slot(member: Node3D) -> bool:
	return is_instance_valid(member) and _target_by_member.has(member.get_instance_id())

func assign_role(member: Node3D, target: Node3D, preferred_role: int) -> int:
	if not is_instance_valid(member) or not is_instance_valid(target): return 0
	release_role(member)
	var member_id := member.get_instance_id()
	var target_id := target.get_instance_id()
	var roles: Dictionary = _roles_by_target.get(target_id, {})
	var role := preferred_role
	if role == 1 and _count_role(roles, 1) >= max_flankers_per_target: role = 0
	elif role == 2 and _count_role(roles, 2) >= max_support_per_target: role = 0
	roles[member_id] = role
	_roles_by_target[target_id] = roles
	_target_by_role_member[member_id] = target_id
	role_assigned.emit(member, target, role)
	return role

func release_role(member: Node3D) -> void:
	if not is_instance_valid(member): return
	var member_id := member.get_instance_id()
	if not _target_by_role_member.has(member_id): return
	var target_id := int(_target_by_role_member[member_id])
	_target_by_role_member.erase(member_id)
	var roles: Dictionary = _roles_by_target.get(target_id, {})
	roles.erase(member_id)
	if roles.is_empty(): _roles_by_target.erase(target_id)
	else: _roles_by_target[target_id] = roles

func set_member_retreating(member: Node3D, target: Node3D, retreating: bool) -> void:
	if not is_instance_valid(member) or not is_instance_valid(target): return
	var target_id := target.get_instance_id()
	var members: Dictionary = _retreating_by_target.get(target_id, {})
	var member_id := member.get_instance_id()
	if retreating: members[member_id] = true
	else: members.erase(member_id)
	if members.is_empty(): _retreating_by_target.erase(target_id)
	else: _retreating_by_target[target_id] = members
	member_retreat_changed.emit(member, target, retreating)

func get_retreating_count(target: Node3D) -> int:
	if not is_instance_valid(target): return 0
	return (_retreating_by_target.get(target.get_instance_id(), {}) as Dictionary).size()

func _count_role(roles: Dictionary, role: int) -> int:
	var count := 0
	for value: Variant in roles.values():
		if int(value) == role: count += 1
	return count

func _cleanup_target(target_id: int) -> void:
	var bucket: Array = _attackers_by_target.get(target_id, [])
	for index: int in range(bucket.size() - 1, -1, -1):
		var member_id: int = int(bucket[index])
		var occupant := instance_from_id(member_id) as Node3D
		if not is_instance_valid(occupant) or not _target_by_member.has(member_id) or int(_target_by_member[member_id]) != target_id:
			bucket.remove_at(index)
			_target_by_member.erase(member_id)
	if bucket.is_empty():
		_attackers_by_target.erase(target_id)
	else:
		_attackers_by_target[target_id] = bucket
