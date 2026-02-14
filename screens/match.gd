extends Control

@onready var points_input: LineEdit = %PointsInput
@onready var info_label: Label = %InfoLabel
@onready var score_label: Label = %ScoreLabel
@onready var history_list: VBoxContainer = %HistoryList
@onready var history_scroll: ScrollContainer = %HistoryScroll

var selected_team := -1  # -1 = ništa, 0 = Mi, 1 = Vi

func _ready() -> void:
	%TargetLabel.text = "Igra se do: %d" % GameState.target
	update_score_ui()
	%InfoLabel.text = "Odaberi tim i dodaj bodove."
	render_history()

func update_score_ui() -> void:
	%ScoreLabel.text = "%s: %d   |   %s: %d" % [
		GameState.team_a, GameState.score_a,
		GameState.team_b, GameState.score_b
	]

func render_history() -> void:
	for c in history_list.get_children():
		c.queue_free()

	for entry in GameState.history:
		add_history_row(entry)

func add_history_row(entry: Dictionary) -> void:
	var row := Label.new()
	row.text = "Mi +%d | Vi +%d   →   %d : %d" % [
		int(entry.get("delta_a", 0)),
		int(entry.get("delta_b", 0)),
		int(entry.get("total_a", 0)),
		int(entry.get("total_b", 0))
	]
	history_list.add_child(row)

func _on_mi_button_pressed() -> void:
	selected_team = 0
	%InfoLabel.text = "Odabrano: Mi"

func _on_vi_button_pressed() -> void:
	selected_team = 1
	%InfoLabel.text = "Odabrano: Vi"

func _on_add_button_pressed() -> void:
	if selected_team == -1:
		info_label.text = "Prvo odaberi tim (Mi ili Vi)."
		return

	var raw: String = points_input.text.strip_edges()
	if raw == "":
		info_label.text = "Upiši bodove."
		return

	if not raw.is_valid_int():
		info_label.text = "Bodovi moraju biti cijeli broj."
		return

	var pts: int = int(raw)
	if pts <= 0:
		info_label.text = "Bodovi moraju biti > 0."
		return

	var entry := GameState.add_points(selected_team, pts)

	points_input.text = ""
	update_score_ui()
	add_history_row(entry)

	await get_tree().process_frame
	history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)
