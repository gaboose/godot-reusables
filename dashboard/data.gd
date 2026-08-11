@tool
class_name DashboardData
extends Resource

@export var entries: Array[DashboardEntry] = []
@export var presets: Array[DashboardPreset]:
	get():
		if presets.size() == 0:
			presets.append(_new_preset("Default"))
		return presets
			
@export var active_preset: int

func add_entry(entry: DashboardEntry):
	_assert()
	entries.append(entry)
	for p in presets:
		p.values.append(entry.resolve_value())
	emit_changed()

func erase_entry(entry: DashboardEntry):
	_assert()
	var i = entries.find(entry)
	entries.remove_at(i)
	for p in presets:
		p.values.remove_at(i)
	emit_changed()

func set_value(i: int, value: Variant):
	_assert()
	var preset = presets[active_preset]
	preset.values[i] = value
	preset.emit_changed()

func get_active_preset() -> DashboardPreset:
	_assert()
	return presets[active_preset]

func add_preset(name: String):
	presets.append(_new_preset(name))
	emit_changed()

func erase_preset(preset: DashboardPreset):
	presets.erase(preset)
	if active_preset >= presets.size():
		active_preset = presets.size()-1
	emit_changed()

func _new_preset(name: String) -> DashboardPreset:
	var p = DashboardPreset.new()
	p.name = name
	for i in entries.size():
		p.values.append(entries[i].resolve_value())
	return p

func _assert():
	for i in presets.size():
		assert(
			len(entries) == len(presets[i].values),
			"parallel arrays of different length len(entries)=%d, len(presets[%d].values)=%d"
			% [len(entries), i, len(presets[i].values)]
		)
