extends Node

var team_a := "Mi"
var team_b := "Vi"
var target := 1001

var score_a := 0
var score_b := 0

var history: Array = []  # entry: {"team":0/1,"points":int,"delta_a":int,"delta_b":int,"total_a":int,"total_b":int}

func new_match(target_score: int) -> void:
	team_a = "Mi"
	team_b = "Vi"
	target = target_score
	score_a = 0
	score_b = 0
	history.clear()

func add_points(team: int, points: int) -> Dictionary:
	var delta_a := 0
	var delta_b := 0
	if team == 0:
		delta_a = points
		score_a += points
	else:
		delta_b = points
		score_b += points

	var entry := {
		"team": team,
		"points": points,
		"delta_a": delta_a,
		"delta_b": delta_b,
		"total_a": score_a,
		"total_b": score_b
	}
	history.append(entry)
	return entry

func recompute_totals_from_history() -> void:
	score_a = 0
	score_b = 0
	for entry in history:
		var team := int(entry.get("team", 0))
		var pts := int(entry.get("points", 0))

		entry["delta_a"] = (pts if team == 0 else 0)
		entry["delta_b"] = (pts if team == 1 else 0)

		score_a += int(entry["delta_a"])
		score_b += int(entry["delta_b"])

		entry["total_a"] = score_a
		entry["total_b"] = score_b

func update_points(index: int, new_points: int) -> void:
	if index < 0 or index >= history.size():
		return
	history[index]["points"] = new_points
	recompute_totals_from_history()
