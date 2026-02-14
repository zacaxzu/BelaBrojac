extends Node

var team_a := "Mi"
var team_b := "Vi"
var target := 1001

var score_a := 0
var score_b := 0

var history: Array = []  # svaki entry je Dictionary

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
		score_a += points
		delta_a = points
	else:
		score_b += points
		delta_b = points

	var entry := {
		"delta_a": delta_a,
		"delta_b": delta_b,
		"total_a": score_a,
		"total_b": score_b
	}

	history.append(entry)
	return entry
