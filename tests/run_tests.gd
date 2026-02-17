extends SceneTree
## Studio OS contract test runner for Monster Catcher.
## Runs existing test suite as subprocess, extracts JSON, writes contract output.
## Usage: godot --headless --path <project> --script res://tests/run_tests.gd

func _init() -> void:
	var start_time := Time.get_ticks_msec()
	var godot_path := OS.get_executable_path()
	var project_path := ProjectSettings.globalize_path("res://")

	var output: Array = []
	OS.execute(godot_path, [
		"--headless", "--path", project_path,
		"res://scenes/tests/test_runner.tscn",
	], output, true)

	var stdout_text: String = output[0] if output.size() > 0 else ""

	# Extract JSON between sentinels
	var json_str := ""
	var in_json := false
	for line in stdout_text.split("\n"):
		var clean := line.strip_edges()
		if clean == "===JSON_REPORT_END===":
			in_json = false
		elif in_json:
			json_str += line + "\n"
		elif clean == "===JSON_REPORT_START===":
			in_json = true

	var duration := Time.get_ticks_msec() - start_time
	var result: Dictionary

	if json_str.strip_edges() != "":
		var parsed = JSON.parse_string(json_str.strip_edges())
		if parsed is Dictionary:
			# Convert from game format to contract format
			result = {
				"status": parsed.get("status", "fail"),
				"testsTotal": parsed.get("total", 0),
				"testsPassed": parsed.get("passed", 0),
				"durationMs": duration,
				"timestamp": Time.get_datetime_string_from_system(true),
				"details": parsed.get("details", []),
			}
		else:
			result = _fallback("Failed to parse test JSON output", duration)
	else:
		result = _fallback("Test subprocess produced no JSON output", duration)

	var out_json := JSON.stringify(result, "\t")

	var f := FileAccess.open("res://tests/test-results.json", FileAccess.WRITE)
	if f:
		f.store_string(out_json)
		f.close()

	print(out_json)
	quit(0 if result.get("status") == "pass" else 1)


func _fallback(message: String, duration_ms: int) -> Dictionary:
	return {
		"status": "fail",
		"testsTotal": 0,
		"testsPassed": 0,
		"durationMs": duration_ms,
		"timestamp": Time.get_datetime_string_from_system(true),
		"details": [{"name": "runner", "status": "fail", "message": message}],
	}
