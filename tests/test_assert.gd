extends RefCounted
class_name TestAssert

static func assert_true(condition: bool, message: String) -> Array[String]:
	var failures: Array[String] = []
	if not condition:
		failures.append(message)
	return failures

static func assert_eq(actual, expected, message: String) -> Array[String]:
	var failures: Array[String] = []
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
	return failures

static func assert_in(value, options: Array, message: String) -> Array[String]:
	var failures: Array[String] = []
	if not options.has(value):
		failures.append("%s | value=%s options=%s" % [message, value, options])
	return failures
