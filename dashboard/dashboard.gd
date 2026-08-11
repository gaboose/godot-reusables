@tool
extends Control

const PROJECT_SETTING_NAME = &"gaboose/dashboard/resource_path"

@onready var _container: VBoxContainer = $'VBoxContainer/ScrollContainer/VBoxContainer'
@onready var _picker = $'VBoxContainer/HBoxPicker/EditorResourcePicker'
@onready var _edit_button = $'VBoxContainer/HBoxPicker/EditButton'
@onready var _preset_picker = $'VBoxContainer/PresetPicker'
@onready var _edit_presets = $'VBoxContainer/EditPresets'
@onready var _help_label = $'VBoxContainer/ScrollContainer/HelpLabel'
var _data: DashboardData:
	set(value):
		if _data != null:
			_data.changed.disconnect(_populate)
		_data = value
		_picker.edited_resource = _data
		_preset_picker.data = _data
		_edit_presets.data = _data
		if _data != null:
			ProjectSettings.set_setting(PROJECT_SETTING_NAME, _data.resource_path)
			_data.changed.connect(_populate)
		_populate()
var _last_active_preset: DashboardPreset
var _remove_buttons: Array[Button] = []
var _editor_plugin: EditorPlugin
var _object_to_entry_index: Dictionary[Object, int] = {}
var _editor_properties: Array[EditorProperty] = []

func _ready():
	_on_edit_button_toggled(_edit_button.button_pressed)
	var inspector := EditorInterface.get_inspector()
	inspector.property_edited.connect(_on_inspector_property_edited)
	
	var path = ProjectSettings.get_setting(PROJECT_SETTING_NAME)
	if ResourceLoader.exists(path):
		_data = load(path)

func _on_inspector_property_edited(property: String):
	var object = EditorInterface.get_inspector().get_edited_object()
	var i = _object_to_entry_index.get(object)
	if i == null:
		return
	_data.set_value(i, object.get(property))

func setup_plugin(ep: EditorPlugin):
	_editor_plugin = ep
	_editor_plugin.scene_changed.connect(_on_scene_changed)
	_editor_plugin.scene_closed.connect(_on_scene_closed)
	_editor_plugin.resource_saved.connect(_on_resource_saved)

func _on_scene_changed(root: Node):
	_populate()

func _on_scene_closed(path: String):
	_populate()

func _on_resource_saved(resource: Resource):
	if resource == _data:
		ProjectSettings.set_setting(PROJECT_SETTING_NAME, _data.resource_path)

func _on_edit_button_toggled(toggled_on: bool) -> void:
	for b in _remove_buttons:
		b.visible = toggled_on
	_edit_presets.visible = toggled_on

func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	_data = resource

func _clear():
	if _last_active_preset != null:
		_last_active_preset.changed.disconnect(_on_active_preset_changed)
		_last_active_preset = null

	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()
	_remove_buttons = []
	_object_to_entry_index.clear()
	_editor_properties.clear()
	_help_label.visible = true
	
func _populate():
	_clear()
	if _data == null:
		return

	_load_active_preset()
	for i in _data.entries.size():
		_add_entry(_data.entries[i])
	_help_label.visible = _data.entries.size() == 0

	_last_active_preset = _data.get_active_preset()
	_last_active_preset.changed.connect(_on_active_preset_changed)

func _on_active_preset_changed():
	for ep in _editor_properties:
		ep.update_property()

func _load_active_preset():
	var preset = _data.get_active_preset()
	for i in _data.entries.size():
		var entry = _data.entries[i]
		var object = entry.resolve_object()
		if object == null:
			continue
		object[entry.property] = preset.values[i]

class PropertyHolder extends RefCounted:
	var property: Variant

func _add_entry(entry: DashboardEntry):
	var object = entry.resolve_object()
	var i = _data.entries.find(entry)
	var property_holder: PropertyHolder
	if object == null:
		property_holder = PropertyHolder.new()
		property_holder.property = _data.get_active_preset().values[i]
	
	var box = HBoxContainer.new()
	var edprop = EditorInspector.instantiate_property_editor(
		object,
		entry.type,
		entry.property,
		entry.hint,
		entry.hint_string,
		entry.usage
	)
	edprop.label = entry.property.capitalize()
	_editor_properties.append(edprop)
	
	if object == null:
		edprop.set_object_and_property(property_holder, "property")
		edprop.read_only = true
	else:
		edprop.set_object_and_property(object, entry.property)
		_object_to_entry_index[object] = i
		edprop.property_changed.connect(
			func(p: StringName, value, field: StringName, changing: bool):
				var ur := EditorInterface.get_editor_undo_redo()
				ur.create_action("Set %s" % p, UndoRedo.MERGE_ENDS)
				var last_value = object.get(p)
				ur.add_do_property(object, p, value)
				ur.add_undo_property(object, p, last_value)
				ur.add_do_method(_data, "set_value", i, value)
				ur.add_undo_method(_data, "set_value", i, last_value)
				ur.commit_action()
				edprop.update_property()
		)
		
		# to catch changes not via inspector
		# it's either this or periodic polling
		edprop.mouse_entered.connect(func():
			edprop.update_property()
		)
	
	edprop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(edprop)
	
	var remove = Button.new()
	remove.flat = true
	remove.icon = EditorInterface.get_base_control().get_theme_icon(&"Remove", &"EditorIcons")
	remove.tooltip_text = "Remove from dashboard"
	remove.visible = _edit_button.button_pressed
	remove.pressed.connect(func() -> void:
		_remove_buttons.erase(remove)
		_data.erase_entry(entry)
		box.queue_free()
	)
	box.add_child(remove)
	_remove_buttons.append(remove)
	_container.add_child(box)
	edprop.update_property()

func _set_value():
	pass

func _can_drop_data(at_position: Vector2, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "obj_property"

func _drop_data(at_position: Vector2, data) -> void:
	if _data == null:
		_data = DashboardData.new()
		_picker.set_edited_resource(_data)
	var entry = DashboardEntry.new()
	entry.scene_path = data["object"].owner.scene_file_path
	entry.node_path = data["object"].get_path()
	entry.property = data["property"]
	
	var object = entry.resolve_object()
	for prop in object.get_property_list():
		if prop["name"] != entry.property:
			continue
		entry.type = prop["type"]
		entry.hint = prop["hint"]
		entry.hint_string = prop["hint_string"]
		entry.usage = prop["usage"]
		break
	_data.add_entry(entry)
