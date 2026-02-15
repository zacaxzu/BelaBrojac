extends Control

var selected_team := -1
var editing_index := -1
var editing_team := -1
var _edit_syncing := false
var _sanitizing := false

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
	sync_finish_ui()
	
	_setup_numeric_only(points_input, GameState.BASE_POINTS)
	_setup_numeric_only(edit_mi, 5000)
	_setup_numeric_only(edit_vi, 5000)
	edit_mi.text_changed.connect(_on_edit_field_changed.bind(edit_mi, edit_vi))
	edit_vi.text_changed.connect(_on_edit_field_changed.bind(edit_vi, edit_mi))


func _setup_numeric_only(le: LineEdit, max_value: int) -> void:
	# Na Androidu/ iOS-u pokušaj otvoriti numeričku tipkovnicu
	le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER

	# Filtriraj svaki put kad se tekst promijeni
	le.text_changed.connect(_on_number_text_changed.bind(le, max_value))

func _on_number_text_changed(new_text: String, le: LineEdit, max_value: int) -> void:
	if _sanitizing:
		return
	_sanitizing = true

	# 1) ostavi samo znamenke
	var filtered := ""
	for ch in new_text:
		if ch >= "0" and ch <= "9":
			filtered += ch

	if filtered != new_text:
		le.text = filtered
		le.caret_column = le.text.length()

	# 2) opcionalno: ograniči raspon (npr. 0..162)
	if le.text != "":
		var v := int(le.text)
		if v > max_value:
			le.text = str(max_value)
			le.caret_column = le.text.length()

	_sanitizing = false

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
	if GameState.is_finished():
		sync_finish_ui()
		return

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
	sync_finish_ui()

	# Ako je igra završila, sync_finish_ui će već postaviti "KRAJ..." poruku,
	# pa nemoj to pregaziti.
	if not GameState.is_finished():
		info_label.text = "Dodano: Mi +%d | Vi +%d" % [
			int(entry.get("delta_a", 0)),
			int(entry.get("delta_b", 0))
		]

	await get_tree().process_frame
	history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)

func _on_edit_row_pressed(index: int) -> void:
	editing_index = index
	var entry: Dictionary = GameState.history[index]

	edit_error.text = ""
	edit_mi.editable = true
	edit_vi.editable = true

	edit_mi.text = str(int(entry.get("delta_a", 0)))
	edit_vi.text = str(int(entry.get("delta_b", 0)))

	edit_dialog.popup_centered()

func _on_edit_confirmed() -> void:
	if editing_index == -1:
		return

	var mi_raw := edit_mi.text.strip_edges()
	var vi_raw := edit_vi.text.strip_edges()

	if mi_raw == "" or vi_raw == "":
		edit_error.text = "Upiši broj."
		edit_dialog.popup_centered()
		return
	if not mi_raw.is_valid_int() or not vi_raw.is_valid_int():
		edit_error.text = "Moraju biti cijeli brojevi."
		edit_dialog.popup_centered()
		return

	var mi_pts := int(mi_raw)
	var vi_pts := int(vi_raw)

	if mi_pts < 0 or mi_pts > GameState.BASE_POINTS or vi_pts < 0 or vi_pts > GameState.BASE_POINTS:
		edit_error.text = "0–%d" % GameState.BASE_POINTS
		edit_dialog.popup_centered()
		return

	if mi_pts + vi_pts != GameState.BASE_POINTS:
		edit_error.text = "Zbroj mora biti %d." % GameState.BASE_POINTS
		edit_dialog.popup_centered()
		return

	GameState.update_hand(editing_index, mi_pts, vi_pts)
	editing_index = -1

	update_score_ui()
	render_history()
	sync_finish_ui()

func sync_finish_ui() -> void:
	var finished := GameState.is_finished()

	%AddButton.disabled = finished
	%PointsInput.editable = not finished
	%MiButton.disabled = finished
	%ViButton.disabled = finished

	if finished:
		var winner := GameState.team_a if GameState.score_a >= GameState.target else GameState.team_b
		info_label.text = "KRAJ! Pobijedio je %s (%d:%d). Možeš urediti retke da ispraviš grešku." % [
			winner, GameState.score_a, GameState.score_b
		]
	else:
		# vrati normalnu poruku (po želji)
		if selected_team == 0:
			info_label.text = "Odabrano: Mi"
		elif selected_team == 1:
			info_label.text = "Odabrano: Vi"
		else:
			info_label.text = "Odaberi Mi/Vi, upiši broj i dodaj."

func _on_edit_field_changed(new_text: String, source: LineEdit, other: LineEdit) -> void:
	# spriječi petlju (jer mi programatski mijenjamo drugo polje)
	if _edit_syncing:
		return

	# reagiraj samo na polje koje korisnik trenutno tipka (ima fokus)
	if not source.has_focus():
		return

	_edit_syncing = true

	if new_text == "":
		# ako korisnik obriše, obriši i drugo (ili možeš staviti "0")
		other.text = ""
	else:
		var v := int(new_text)
		v = clamp(v, 0, GameState.BASE_POINTS)
		other.text = str(GameState.BASE_POINTS - v)
		other.caret_column = other.text.length()

	_edit_syncing = false
