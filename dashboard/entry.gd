@tool
class_name DashboardEntry
extends Resource

@export var scene_path: String
@export var node_path: NodePath

@export var property: StringName
@export var type: Variant.Type
@export var hint: int
@export var hint_string: StringName
@export var usage: int

func resolve_object() -> Object:
	var root = EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path != scene_path:
		return null
	return root.get_node_or_null(node_path)

func resolve_value() -> Variant:
	var object = resolve_object()
	if object == null:
		return null
	return object.get(property)
