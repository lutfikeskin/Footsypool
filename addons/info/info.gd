@tool
extends EditorPlugin

var dock
var button: Button
var label: Label

func _enter_tree():
    dock = preload("res://addons/info/info_inspector.gd").new()
    add_inspector_plugin(dock)





func _exit_tree():
    remove_inspector_plugin(dock)

func _update():
    label.text = "Effects:\n--------------------"
    var i: = 0
    for e in Effects.singleton.effects:
        label.text += "%d: %s" % [1, e.resource_name]
        i += 1
