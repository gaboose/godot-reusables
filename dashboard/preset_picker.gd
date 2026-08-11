@tool
extends HBoxContainer

@onready var option_button: OptionButton = $'OptionButton'

@export var data: DashboardData:
	set(value):
		if data != null:
			data.changed.disconnect(_on_data_changed)
		data = value
		if data != null:
			data.changed.connect(_on_data_changed)
		_populate()

func _on_option_button_item_selected(index: int) -> void:
	var preset = data.presets[index]
	var ur := EditorInterface.get_editor_undo_redo()
	ur.create_action("Load preset %s" % preset.name, UndoRedo.MERGE_DISABLE, data)
	ur.add_do_property(data, "active_preset", index)
	ur.add_undo_property(data, "active_preset", data.active_preset)
	ur.add_do_method(data, "emit_changed")
	ur.add_undo_method(data, "emit_changed")
	ur.commit_action()

func _on_data_changed():
	_populate()

func _clear():
	option_button.clear()

func _populate():
	_clear()
	if data == null:
		visible = false
		return

	for i in data.presets.size():
		var p = data.presets[i]
		option_button.add_item(p.name)
		p.changed.connect(func():
			option_button.set_item_text(i, p.name)	
		)
	option_button.select(data.active_preset)
	visible = data.presets.size() > 1
