@tool
extends EditorPlugin

var dock
var copy_indicator: Control
var colors: PackedStringArray

func _enter_tree():
    dock = preload("res://addons/palette/palette.tscn").instantiate()
    add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)

    copy_indicator = dock.get_node("CopyIndicator")
    copy_indicator.hide()

    load_colors()

    for col in colors:
        create_button(col)

    var adder = dock.get_node("VBoxContainer/HBoxContainer/Button")
    if adder is Button:
        adder.button_down.connect(add)

    var picker = dock.get_node("VBoxContainer/HBoxContainer/Picker")
    if picker is ColorPickerButton:
        picker.color_changed.connect(_color_picked)

func _color_picked(color: Color):
    var edit = dock.get_node("VBoxContainer/HBoxContainer/LineEdit")
    if edit is LineEdit:
        edit.text = color.to_html(false)

func load_colors():
    var file: = FileAccess.open("res://addons/palette/colors.txt", FileAccess.READ)
    var content: = file.get_as_text()
    file.close()
    colors = content.split("\n")

func save_colors():
    var file: = FileAccess.open("res://addons/palette/colors.txt", FileAccess.WRITE)
    var contents: = "\n".join(colors)
    file.store_string(contents)
    file.close()

func _exit_tree():
    remove_control_from_docks(dock)
    dock.free()

func create_button(hex: String):
    if len(hex) > 1:
        var btn: = preload("res://addons/palette/button.tscn").instantiate()
        var container = dock.get_node("VBoxContainer/Colors")
        if container is Control:
            container.add_child(btn)
        if btn is Button:
            btn.modulate = Color.html(hex)
            btn.button_up.connect(_change_color.bind(hex, btn))

func add():
    var edit = dock.get_node("VBoxContainer/HBoxContainer/LineEdit")
    if edit is LineEdit:
        create_button(edit.text)
        if len(edit.text) > 0: colors.push_back(edit.text)
        save_colors()
        edit.clear()

func _change_color(hex: String, button: Button) -> void :
    var current: = get_editor_interface().get_selection().get_selected_nodes()
    if Input.is_key_pressed(KEY_SHIFT):
        DisplayServer.clipboard_set(hex if hex.contains("#") else "#" + hex)
        copy_indicator.show()
        await get_tree().create_timer(1).timeout
        copy_indicator.hide()
        return
    if Input.is_key_pressed(KEY_ALT):
        colors.remove_at(colors.find(hex))
        button.queue_free()
        save_colors()
        return
    var color: = Color.html(hex)
    for node in current:
        if node is ColorRect:
            node.color = color
            return
        if node is Node2D or node is Control:
            node.self_modulate = color
