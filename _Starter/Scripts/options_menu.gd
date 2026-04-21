class_name OptionsMenu
extends SlidingPanel

@export var toggle_button: Button
@export var music: Slider
@export var sounds: Slider
@export var extra_panel: SlidingPanel

var saver = Saver.new("settings.json")
var data: SettingsData

func _ready():
    super._ready()
    show()
    toggle_button.pressed.connect(close)
    data = saver.load( func(): return SettingsData.new(0.5, 0.5)) as SettingsData

    music.value = data.music
    sounds.value = data.sounds
    prepare_slider(music)
    prepare_slider(sounds)
    volumes_changed(0)
    music.value_changed.connect(volumes_changed)
    sounds.value_changed.connect(volumes_changed)

func prepare_slider(slider: Slider):
    slider.max_value = 1.0
    slider.min_value = 0

func volumes_changed(_val):
    AudioServer.set_bus_volume_linear(1, music.value * 2)
    AudioServer.set_bus_volume_linear(2, sounds.value * 2)
    data.music = music.value
    data.sounds = sounds.value
    pass

func close():
    toggle()
    if extra_panel and extra_panel.open:
        extra_panel.toggle()
    saver.save(data)

func _input(_event):
    if Input.is_action_just_pressed("escape"):
        close()

func restart():
    close()
    Blinders.singleton.close()
    await Blinders.singleton.closed
    get_tree().reload_current_scene()

func toggle_fullscreen():
    var full: = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
