@tool
extends FoldableContainer

@onready var box: Container = $'VBoxContainer/VBoxContainer'

@export var data: DashboardData:
	set(value):
		if data != null:
			data.changed.disconnect(_on_data_changed)
		data = value
		if data != null:
			data.changed.connect(_on_data_changed)
		_populate()

func _on_data_changed():
	_populate()

func _clear():
	for c in box.get_children():
		c.queue_free()

func _populate():
	_clear()
	if data == null:
		return
	
	for i in data.presets.size():
		var c = _build_preset(data.presets[i], i)
		box.add_child(c)

func _on_add_preset_pressed() -> void:
	data.add_preset("Preset %d" % (data.presets.size()+1))

func _build_preset(preset: DashboardPreset, i: int) -> Control:
	for prop in preset.get_property_list():
		if prop["name"] != "name":
			continue
		
		var hbox = HBoxContainer.new()
		
		var edprop = EditorInspector.instantiate_property_editor(
			preset,
			prop["type"],
			prop["name"],
			prop["hint"],
			prop["hint_string"],
			prop["usage"]
		)
		edprop.label = "Name"
		edprop.set_object_and_property(preset, "name")
		edprop.property_changed.connect(
			func(p: StringName, value, field: StringName, changing: bool):
				#var ur := EditorInterface.get_editor_undo_redo()
				#ur.create_action("Set %s" % p, UndoRedo.MERGE_ENDS)
				#ur.add_do_property(object, p, value)
				#ur.add_undo_property(object, p, object.get(p))
				#ur.commit_action()
				preset.name = value
				preset.emit_changed()
				#edprop.update_property()
		)
		
		edprop.update_property()
		edprop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(edprop)
		
		var remove = Button.new()
		remove.flat = true
		remove.icon = EditorInterface.get_base_control().get_theme_icon(&"Remove", &"EditorIcons")
		if i == 0:
			remove.disabled = true
		else:
			remove.pressed.connect(func() -> void:
				data.erase_preset(preset)
				hbox.queue_free()
			)
		hbox.add_child(remove)
		
		return hbox
	return null
