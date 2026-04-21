@abstract class_name Utils

static func distinct_array(array: Array) -> Array:
    var unique: = []
    for item in array:
        if not unique.has(item):
            unique.push_back(item)
    return unique

static func as_score(num: int, separator: String = " ") -> String:
    var text: = str(num)
    var output: Array[String] = []
    var length = text.length()
    for i in length:
        var idx = i + 1
        output.append(text[length - idx])
        if i < length - 1 and idx % 3 == 0:
            output.append(separator)
    output.reverse()
    return "".join(output)

static func as_wavy(text: String) -> String:
    return "[wave]%s[/wave]" % [text]

static func colorize(text: String, color: String) -> String:
    return text.replace("(", "[color=%s]" % [color]).replace(")", "[/color]")
