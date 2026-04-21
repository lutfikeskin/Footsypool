class_name SlidingNotification extends SlidingPanel

@export var label: RichTextLabel

signal appear

var queue: = []

func display(message: String):
    queue.push_back(message)
    check_queue()

func check_queue():
    if queue.size() > 0 and not open:
        show_next()

func show_next():
    label.text = queue.pop_front()
    toggle()
    appear.emit()
    await get_tree().create_timer(2).timeout
    toggle()
    await get_tree().create_timer(1).timeout
    check_queue()
