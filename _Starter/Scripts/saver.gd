class_name Saver

var filename: String

func _init(name: = "save.dat"):
    filename = "user://%s" % name

func save(data: Object):
    var file: = FileAccess.open(filename, FileAccess.WRITE)
    file.store_line(JSON.stringify(inst_to_dict(data)))

func load(creator: Callable) -> Object:
    if not FileAccess.file_exists(filename):
        return creator.call()
    var file = FileAccess.open(filename, FileAccess.READ)
    while file.get_position() < file.get_length():
        var data: Dictionary = JSON.parse_string(file.get_line())
        if data and data.has("@path"):
            return dict_to_inst(data)
    return creator.call()
