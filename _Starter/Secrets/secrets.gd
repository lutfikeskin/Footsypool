@abstract class_name Secrets

static func get_verification_number(name: String, score: int, secondary: int):
    return (score % 456 + len(name) * secondary * 123) % 79971;
