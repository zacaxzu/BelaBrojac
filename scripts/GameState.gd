extends Node

const BASE_POINTS: int = 162

var team_a := "Mi"
var team_b := "Vi"
var target := 1001

var score_a := 0
var score_b := 0

var history: Array[Dictionary] = []  # entry: {"mode","team","points","delta_a","delta_b","total_a","total_b"}

func new_match(target_score: int) -> void:
	team_a = "Mi"
	team_b = "Vi"
	target = target_score
	score_a = 0
	score_b = 0
	history.clear()

func is_finished() -> bool:
	return score_a >= target or score_b >= target

func add_hand_with_calls(team: int, team_total_points: int, calls_a: int, calls_b: int) -> Dictionary:
	var ca: int = maxi(calls_a, 0)
	var cb: int = maxi(calls_b, 0)

	var hand_total: int = BASE_POINTS + ca + cb

	# minimalno: tim mora imati barem svoja zvanja (da baza ne bude negativna)
	var min_a: int = ca
	var min_b: int = cb
	var max_a: int = hand_total - cb
	var max_b: int = hand_total - ca

	if team == 0:
		team_total_points = clampi(team_total_points, min_a, max_a)
	else:
		team_total_points = clampi(team_total_points, min_b, max_b)

	var delta_a: int = team_total_points if team == 0 else (hand_total - team_total_points)
	var delta_b: int = (hand_total - team_total_points) if team == 0 else team_total_points

	var base_a: int = maxi(delta_a - ca, 0)
	var base_b: int = maxi(delta_b - cb, 0)

	var entry: Dictionary = {
		"team": team,
		"points": team_total_points, # UKUPNO za odabrani tim (baza + zvanja)
		"calls_a": ca,
		"calls_b": cb,
		"base_a": base_a,
		"base_b": base_b,
		"delta_a": delta_a,
		"delta_b": delta_b,
		"total_a": 0,
		"total_b": 0
	}

	history.append(entry)
	recompute_totals_from_history()
	return history[history.size() - 1]

func recompute_totals_from_history() -> void:
	score_a = 0
	score_b = 0

	for entry: Dictionary in history:
		var team: int = int(entry.get("team", 0))
		var team_total: int = int(entry.get("points", 0))

		var ca: int = maxi(int(entry.get("calls_a", 0)), 0)
		var cb: int = maxi(int(entry.get("calls_b", 0)), 0)
		var hand_total: int = BASE_POINTS + ca + cb

		var min_a: int = ca
		var min_b: int = cb
		var max_a: int = hand_total - cb
		var max_b: int = hand_total - ca

		if team == 0:
			team_total = clampi(team_total, min_a, max_a)
		else:
			team_total = clampi(team_total, min_b, max_b)

		var delta_a: int = team_total if team == 0 else (hand_total - team_total)
		var delta_b: int = (hand_total - team_total) if team == 0 else team_total

		entry["calls_a"] = ca
		entry["calls_b"] = cb
		entry["delta_a"] = delta_a
		entry["delta_b"] = delta_b
		entry["base_a"] = maxi(delta_a - ca, 0)
		entry["base_b"] = maxi(delta_b - cb, 0)

		score_a += delta_a
		score_b += delta_b
		entry["total_a"] = score_a
		entry["total_b"] = score_b

func update_points(index: int, team: int, new_team_total: int) -> void:
	if index < 0 or index >= history.size():
		return

	history[index]["team"] = team
	history[index]["points"] = new_team_total
	recompute_totals_from_history()

func update_hand(index: int, new_delta_a: int, new_delta_b: int) -> void:
	if index < 0 or index >= history.size():
		return

	history[index]["manual"] = true
	history[index]["delta_a"] = max(new_delta_a, 0)
	history[index]["delta_b"] = max(new_delta_b, 0)

	recompute_totals_from_history()

func add_hand_base_with_calls(team: int, base_points_for_team: int, calls_a: int, calls_b: int) -> Dictionary:
	base_points_for_team = clamp(base_points_for_team, 0, BASE_POINTS)
	calls_a = max(calls_a, 0)
	calls_b = max(calls_b, 0)

	var other := BASE_POINTS - base_points_for_team

	var base_a := base_points_for_team if team == 0 else other
	var base_b := other if team == 0 else base_points_for_team

	var delta_a := base_a + calls_a
	var delta_b := base_b + calls_b

	var entry := {
		"manual": false,          # baza se računa iz team/points
		"team": team,
		"points": base_points_for_team,

		"base_a": base_a,
		"base_b": base_b,

		"calls_a": calls_a,
		"calls_b": calls_b,

		"delta_a": delta_a,
		"delta_b": delta_b,

		"total_a": 0,
		"total_b": 0
	}

	history.append(entry)
	recompute_totals_from_history()
	return history[history.size() - 1]

func update_points_with_team(index: int, team: int, new_team_total: int) -> void:
	if index < 0 or index >= history.size():
		return

	history[index]["team"] = team
	history[index]["points"] = new_team_total
	recompute_totals_from_history()
