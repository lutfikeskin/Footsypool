@tool
@icon("icon.svg")
class_name RhythmNotifier
extends Node
















































































































class _Rhythm:

    signal interval_changed(current_interval: int)

    var repeating: bool
    var beat_count: float
    var start_beat: float
    var last_frame_interval


    func _init(_repeating, _beat_count, _start_beat):
        repeating = _repeating
        beat_count = _beat_count
        start_beat = _start_beat


    const TOO_LATE = 0.1

    func emit_if_needed(position: float, secs_per_beat: float) -> void :
        var interval_secs = beat_count * secs_per_beat
        var interval_start_position = start_beat * secs_per_beat
        var current_interval = int(floor((position - interval_start_position) / interval_secs))
        var secs_past_interval = fmod(position - interval_start_position, interval_secs)
        var valid_interval = current_interval >= 0 and (repeating or current_interval == 0)
        var too_late = secs_past_interval >= TOO_LATE
        if not valid_interval or too_late:
            last_frame_interval = null
        elif last_frame_interval != current_interval:



            interval_changed.emit(current_interval)
            last_frame_interval = current_interval
        else:
            pass







signal beat(current_beat: int)



@export var bpm: float = 60.0:
    set(val):
        if val == 0: return
        bpm = val
        notify_property_list_changed()




@export var beat_length: float = 1.0:
    get:
        return 60.0 / bpm
    set(val):
        if val == 0: return
        bpm = 60.0 / val




@export var audio_stream_player: AudioStreamPlayer




@export var running: bool:
    get: return _silent_running or _stream_is_playing()
    set(val):
        if val == running:
            return
        if _stream_is_playing():
            return
        _silent_running = val
        _position = 0.0


var current_beat: int:
    get: return int(floor(_position / beat_length))





var current_position: float:
    get: return _position
    set(val):
        if _stream_is_playing():
            audio_stream_player.seek(val)
        elif _silent_running:
            _position = val
var _position: float = 0.0

var _cached_output_latency: float:
    get:
        if Time.get_ticks_msec() >= _invalidate_cached_output_latency_by:

            _cached_output_latency = AudioServer.get_output_latency()
            _invalidate_cached_output_latency_by = Time.get_ticks_msec() + 1000
        return _cached_output_latency
var _invalidate_cached_output_latency_by: = 0
var _silent_running: bool
var _rhythms: Array[_Rhythm] = []


func _ready():






    beats(1.0).connect( func(current_interval): beat.emit(current_interval))



func _physics_process(delta):
    if _silent_running and _stream_is_playing():
        _silent_running = false
    if not running:
        return
    if _silent_running:
        _position += delta
    else:
        _position = audio_stream_player.get_playback_position()
        _position += AudioServer.get_time_since_last_mix() - _cached_output_latency
    if Engine.is_editor_hint():
        return
    for rhythm in _rhythms:
        rhythm.emit_if_needed(_position, beat_length)































func beats(beat_count: float, repeating: = true, start_beat: = 0.0) -> Signal:
    if not repeating:


        beat_count = 100.0
    for rhythm in _rhythms:
        if (rhythm.beat_count == beat_count
            and rhythm.repeating == repeating
            and rhythm.start_beat == start_beat):
            return rhythm.interval_changed
    var new_rhythm = _Rhythm.new(repeating, beat_count, start_beat)
    _rhythms.append(new_rhythm)
    return new_rhythm.interval_changed


func _stream_is_playing():
    return audio_stream_player != null and audio_stream_player.playing
