@tool
extends EditorPlugin

var dock: EditorDock

func _enter_tree():
	var dock_scene = preload("res://addons/dashboard/dashboard.tscn").instantiate()
	dock_scene.setup_plugin(self)
	
	dock = EditorDock.new()
	dock.add_child(dock_scene)
	dock.title = "Dashboard"
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
	add_dock(dock)
	
	scene_changed

func _exit_tree():
	remove_dock(dock)
	dock.queue_free()
