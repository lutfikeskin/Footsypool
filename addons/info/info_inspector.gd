extends EditorInspectorPlugin

var obj

func _can_handle(object: Object) -> bool:
    return object is Effects or object is SoundEffects

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide) -> bool:
    if type == 28:
        if object is Effects or object is SoundEffects:
            var i: = 0
            for e in object.effects:
                var button: = Button.new()
                button.text = "%s\n" % [e.resource_path.split("/")[-1]]
                add_property_editor(name, button)
                obj = object
                if button is Button:
                    button.button_up.connect(_copy_command.bind(i, "Effects" if object is Effects else "SoundEffects", button.text))
                i += 1
    return false

func _copy_command(i: int, root: String, comment: String):
    obj.notify_property_list_changed()
    var text: = "%s.singleton.add(%d, global_position)" % [root, i]
    DisplayServer.clipboard_set(text)
    print(text)
