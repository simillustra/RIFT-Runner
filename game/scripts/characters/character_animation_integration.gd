extends Node
class_name CharacterAnimationIntegration
## Optional scene adapter. Missing animation assets never block character gameplay.

@export_node_path("Node") var movement_controller_path: NodePath = NodePath("../MovementController")
@export_node_path("AnimationTree") var animation_tree_path: NodePath = NodePath("../AnimationTree")
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = NodePath("../AnimationPlayer")
@export var animation_profile: AnimationProfile
@export var runtime_controller_name: StringName = &"CharacterAnimationControllerRuntime"

var _runtime_controller: CharacterAnimationController
var _integration_enabled: bool = false


func _ready() -> void:
	var animation_tree := get_node_or_null(animation_tree_path) as AnimationTree
	var animation_player := get_node_or_null(animation_player_path) as AnimationPlayer
	if animation_tree == null and animation_player == null:
		return
	if animation_tree == null or animation_player == null:
		push_warning("CharacterAnimationIntegration disabled: both AnimationTree and AnimationPlayer are required.")
		return
	var movement := get_node_or_null(movement_controller_path) as CharacterMovementController
	if movement == null:
		push_warning("CharacterAnimationIntegration disabled: movement controller was not found at '%s'." % String(movement_controller_path))
		return
	if animation_profile == null:
		push_warning("CharacterAnimationIntegration disabled: animation_profile is not assigned.")
		return
	_runtime_controller = CharacterAnimationController.new()
	_runtime_controller.name = runtime_controller_name
	_runtime_controller.movement_controller = movement
	_runtime_controller.animation_tree = animation_tree
	_runtime_controller.animation_player = animation_player
	_runtime_controller.animation_profile = animation_profile
	add_child(_runtime_controller)
	_integration_enabled = true


func is_integration_enabled() -> bool:
	return _integration_enabled


func get_runtime_controller() -> CharacterAnimationController:
	return _runtime_controller
