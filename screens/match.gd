extends Control

var selected_team := -1
var editing_index := -1
var editing_team := -1

@onready var points_input: LineEdit = %PointsInput
@onready var info_label: Label = %InfoLabel
@onready var score_label: Label = %ScoreLabel
@onready var history_list: VBoxContainer = %HistoryList
@onready var history_scroll: ScrollContainer = %HistoryScroll

@onready var edit_dialog: ConfirmationDialog = %EditDialog
@onready var edit_mi: LineEdit = %EditMiInput
@onready var edit_vi: LineEdit = %EditViInput
@onready var edit_error: Label = %EditErrorLabel

func _ready() -> void:
	%TargetLabel.text = "Igra se do: %d" % GameState.target
	update_score_ui()
	info_label.text = "Odaberi Mi/Vi, upiši broj i dodaj."
	render_history()
	edit_dialog.confirmed.connect(_on_edit_confirmed)

func update_score_ui() -> void:
	score_label.text = "%s: %d   |   %s: %d" % [
		GameState.team_a, GameState.score_a,
		GameState.team_b, GameState.score_b
	]

func render_history() -> void:
	for c in history_list.get_children():
		c.queue_free()
	for i in range(GameState.history.size()):
		add_history_row(GameState.history[i], i)

func add_history_row(entry: Dictionary, index: int) -> void:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = "Mi +%d | Vi +%d   →   %d : %d" % [
		int(entry.get("delta_a", 0)),
		int(entry.get("delta_b", 0)),
		int(entry.get("total_a", 0)),
		int(entry.get("total_b", 0))
	]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var edit_btn := Button.new()
	edit_btn.text = "Uredi"
	edit_btn.pressed.connect(_on_edit_row_pressed.bind(index))
	row.add_child(edit_btn)

	history_list.add_child(row)

func _on_mi_button_pressed() -> void:
	selected_team = 0
	info_label.text = "Odabrano: Mi"

func _on_vi_button_pressed() -> void:
	selected_team = 1
	info_label.text = "Odabrano: Vi"

func _on_add_button_pressed() -> void:
	if selected_team == -1:
		info_label.text = "Prvo odaberi Mi ili Vi."
		return

	var raw: String = points_input.text.strip_edges()
	if raw == "" or not raw.is_valid_int():
		info_label.text = "Upiši cijeli broj."
		return

	var pts: int = int(raw)
	if pts < 0 or pts > GameState.BASE_POINTS:
		info_label.text = "Bodovi moraju biti između 0 i %d." % GameState.BASE_POINTS
		return

	var entry := GameState.add_points(selected_team, pts)

	points_input.text = ""
	update_score_ui()
	render_history()

	info_label.text = "Dodano: Mi +%d | Vi +%d" % [
		int(entry.get("delta_a", 0)),
		int(entry.get("delta_b", 0))
	]

	await get_tree().process_frame
	history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)

func _on_edit_row_pressed(index: int) -> void:
	editing_index = index
	var entry: Dictionary = GameState.history[index]
	editing_team = int(entry.get("team", 0))
	var pts := int(entry.get("points", 0))

	edit_error.text = ""

	if editing_team == 0:
		edit_mi.text = str(pts)
		edit_vi.text = str(GameState.BASE_POINTS - pts)
		edit_mi.editable = true
		edit_vi.editable = false
	else:
		edit_vi.text = str(pts)
		edit_mi.text = str(GameState.BASE_POINTS - pts)
		edit_mi.editable = false
		edit_vi.editable = true

	edit_dialog.popup_centered()

func _on_edit_confirmed() -> void:
	if editing_index == -1:
		return

	var raw := (edit_mi.text.strip_edges() if editing_team == 0 else edit_vi.text.strip_edges())
	if raw == "" or not raw.is_valid_int():
		edit_error.text = "Upiši cijeli broj."
		edit_dialog.popup_centered()
		return

	var pts := int(raw)
	if pts < 0 or pts > GameState.BASE_POINTS:
		edit_error.text = "Mora biti 0–%d." % GameState.BASE_POINTS
		edit_dialog.popup_centered()
		return

	GameState.update_points(editing_index, pts)
	editing_index = -1
	editing_team = -1

	update_score_ui()
	render_history()
