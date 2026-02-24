extends SceneTree
## Lightweight test runner. Discovers test_*.gd files and runs test_* methods.
## Usage: godot --headless --main-loop "res://tests/test_runner.gd"

var _total_passed: int = 0
var _total_failed: int = 0
var _total_tests: int = 0
var _results: Array[Dictionary] = []


func _init() -> void:
	print("\n========================================")
	print("  DIABLO — Test Suite")
	print("========================================\n")


func _initialize() -> void:
	var test_scripts := _discover_tests()
	for path in test_scripts:
		_run_test_file(path)
	_print_summary()
	quit(0 if _total_failed == 0 else 1)


func _discover_tests() -> Array[String]:
	var tests: Array[String] = []
	var dir := DirAccess.open("res://tests/")
	if not dir:
		push_error("Cannot open tests/ directory")
		return tests
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_runner.gd":
			tests.append("res://tests/" + file)
		file = dir.get_next()
	dir.list_dir_end()
	tests.sort()
	return tests


func _run_test_file(path: String) -> void:
	var script: GDScript = load(path)
	if not script:
		print("  SKIP  Could not load: %s" % path)
		return

	var file_name := path.get_file().replace(".gd", "")
	print("--- %s ---" % file_name)

	var instance = script.new()

	# Collect test method names
	var methods: Array[String] = []
	for m in instance.get_method_list():
		var name: String = m["name"]
		if name.begins_with("test_"):
			methods.append(name)
	methods.sort()

	for method_name in methods:
		# Call before_each if it exists
		if instance.has_method("before_each"):
			instance.call("before_each")

		var result: Dictionary = instance.call(method_name)
		_total_tests += 1
		if result.get("passed", false):
			_total_passed += 1
			print("  PASS  %s" % method_name)
		else:
			_total_failed += 1
			print("  FAIL  %s — %s" % [method_name, result.get("message", "no details")])
		_results.append({
			"file": file_name,
			"test": method_name,
			"passed": result.get("passed", false),
			"message": result.get("message", ""),
		})

	# Clean up
	if instance is RefCounted:
		pass  # auto-freed
	elif instance is Object and instance.has_method("free"):
		instance.free()

	print("")


func _print_summary() -> void:
	print("========================================")
	print("  Results: %d passed, %d failed, %d total" % [_total_passed, _total_failed, _total_tests])
	if _total_failed == 0:
		print("  ALL TESTS PASSED")
	else:
		print("  FAILURES:")
		for r in _results:
			if not r.passed:
				print("    %s::%s — %s" % [r.file, r.test, r.message])
	print("========================================\n")
