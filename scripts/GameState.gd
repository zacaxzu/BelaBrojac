extends Node

const BASE_POINTS := 162

var team_a := "Mi"
var team_b := "Vi"
var target := 1001

var score_a := 0
var score_b := 0

var history: Array = []  # entry: {"mode","team","points","delta_a","delta_b","total_a","total_b"}

func new_match(target_score: int) -> void:
	team_a = "Mi"
	team_b = "Vi"
	target = target_score
	score_a = 0
	score_b = 0
	history.clear()

func is_finished() -> bool:
	return score_a >= target or score_b >= target

func add_points(team: int, points: int) -> Dictionary:
	# points = bodovi za odabrani tim iz baze 162
	points = clamp(points, 0, BASE_POINTS)
	var other := BASE_POINTS - points

	var delta_a := points if team == 0 else other
	var delta_b := other if team == 0 else points

	score_a += delta_a
	score_b += delta_b

	var entry := {
		"manual": false,
		"mode": "base162",
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
		var manual := bool(entry.get("manual", false))

		var delta_a := 0
		var delta_b := 0

		if manual:
			# ručno uređeni red: koristimo direktno delta vrijednosti
			delta_a = int(entry.get("delta_a", 0))
			delta_b = int(entry.get("delta_b", 0))
		else:
			# auto BASE 162: računamo iz team + points
			var team := int(entry.get("team", 0))
			var pts := int(entry.get("points", 0))

			pts = clamp(pts, 0, BASE_POINTS)
			var other := BASE_POINTS - pts

			delta_a = pts if team == 0 else other
			delta_b = other if team == 0 else pts

			entry["delta_a"] = delta_a
			entry["delta_b"] = delta_b

		score_a += delta_a
		score_b += delta_b
		entry["total_a"] = score_a
		entry["total_b"] = score_b

func update_points(index: int, new_points: int) -> void:
	if index < 0 or index >= history.size():
		return

	history[index]["points"] = clamp(new_points, 0, BASE_POINTS)
	recompute_totals_from_history()

func update_hand(index: int, new_delta_a: int, new_delta_b: int) -> void:
	if index < 0 or index >= history.size():
		return

	history[index]["manual"] = true
	history[index]["delta_a"] = max(new_delta_a, 0)
	history[index]["delta_b"] = max(new_delta_b, 0)

	recompute_totals_from_history()
