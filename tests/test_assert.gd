extends RefCounted
class_name TestAssert

static func assert_true(condition: bool, message: String) -> Array[String]:
	return [] if condition else [message]

static func assert_eq(actual, expected, message: String) -> Array[String]:
	if actual == expected:
		return []
	return ["%s | expected=%s actual=%s" % [message, expected, actual]]

static func assert_in(value, options: Array, message: String) -> Array[String]:
	return [] if options.has(value) else ["%s | value=%s options=%s" % [message, value, options]]
