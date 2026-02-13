extends Node

var team_a := "Mi"
var team_b := "Vi"
var target := 1001

var score_a := 0
var score_b := 0

func new_match(target_score: int) -> void:
	team_a = "Mi"
	team_b = "Vi"
	target = target_score
	score_a = 0
	score_b = 0

func add_points(team: int, points: int) -> void:
	# team: 0 = Mi (A), 1 = Vi (B)
	if team == 0:
		score_a += points
	else:
		score_b += points
