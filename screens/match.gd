extends Control

var selected_team := -1
var editing_index := -1
var editing_team := -1
var _edit_syncing := false
var _sanitizing := false
var _edit_hand_total := 162
var _edit_calls_mi := 0
var _edit_calls_vi := 0

@onready var points_input: LineEdit = %PointsInput
@onready var info_label: Label = %InfoLabel
@onready var score_label: Label = %ScoreLabel
@onready var history_list: VBoxContainer = %HistoryList
@onready var history_scroll: ScrollContainer = %HistoryScroll

@onready var edit_dialog: ConfirmationDialog = %EditDialog
@onready var edit_mi: LineEdit = %EditMiInput
@onready var edit_vi: LineEdit = %EditViInput
@onready var edit_error: Label = %EditErrorLabel
@onready var calls_mi: LineEdit = %CallsMiInput
@onready var calls_vi: LineEdit = %CallsViInput

func _ready() -> void:
	%TargetLabel.text = "Igra se do: %d" % GameState.target
	update_score_ui()
	info_label.text = "Odaberi Mi/Vi, upiši broj i dodaj."
	render_history()
	edit_dialog.confirmed.connect(_on_edit_confirmed)
	sync_finish_ui()
	
	_setup_numeric_only(points_input, GameState.BASE_POINTS) # 162
	_setup_numeric_only(points_input, 5000)
	_setup_numeric_only(edit_mi, 5000)
	_setup_numeric_only(edit_vi, 5000)
	edit_mi.text_changed.connect(_on_edit_points_changed.bind(0))
	edit_vi.text_changed.connect(_on_edit_points_changed.bind(1))
	_setup_numeric_only(calls_mi, 5000)
	_setup_numeric_only(calls_vi, 5000)

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
	var hand_total: int = GameState.BASE_POINTS + int(entry.get("calls_a", 0)) + int(entry.get("calls_b", 0))

	label.text = "Mi %d (+%d) | Vi %d (+%d)   [Ruka: %d]" % [
		int(entry.get("base_a", 0)),
		int(entry.get("calls_a", 0)),
		int(entry.get("base_b", 0)),
		int(entry.get("calls_b", 0)),
		hand_total
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

	var cmi_raw := calls_mi.text.strip_edges()
	var cvi_raw := calls_vi.text.strip_edges()
	var cmi := 0
	var cvi := 0

	if cmi_raw != "":
		if not cmi_raw.is_valid_int():
			info_label.text = "Zvanja Mi moraju biti broj."
			return
		cmi = int(cmi_raw)

	if cvi_raw != "":
		if not cvi_raw.is_valid_int():
			info_label.text = "Zvanja Vi moraju biti broj."
			return
		cvi = int(cvi_raw)
		
		# pts je BAZA (0..162)
	var base_pts: int = pts

	# ukupno po ruci
	var hand_total: int = GameState.BASE_POINTS + cmi + cvi

	# koliko ukupno ima odabrani tim (baza + njegova zvanja)
	var team_total: int = base_pts + (cmi if selected_team == 0 else cvi)

	# validacija: team_total mora biti u granicama (da druga strana ne padne ispod svojih zvanja)
	var min_total: int = (cmi if selected_team == 0 else cvi)
	var max_total: int = hand_total - (cvi if selected_team == 0 else cmi)
	team_total = clampi(team_total, min_total, max_total)

	var entry: Dictionary = GameState.add_hand_with_calls(selected_team, team_total, cmi, cvi)

	var min_pts := cmi if selected_team == 0 else cvi
	var max_pts := hand_total - (cvi if selected_team == 0 else cmi)

	if pts < min_pts or pts > max_pts:
		info_label.text = "Mora biti %d–%d (ukupno po ruci %d)." % [min_pts, max_pts, hand_total]
		return

		calls_mi.text = ""
	calls_vi.text = ""
	points_input.text = ""
	update_score_ui()
	render_history()
	sync_finish_ui()

	# Ako je igra završila, sync_finish_ui će već postaviti "KRAJ..." poruku,
	# pa nemoj to pregaziti.
	if not GameState.is_finished():
		info_label.text = "Dodano: Mi +%d | Vi +%d (ruka=%d)" % [
			int(entry.get("delta_a", 0)),
			int(entry.get("delta_b", 0)),
			GameState.BASE_POINTS + int(entry.get("calls_a", 0)) + int(entry.get("calls_b", 0))
		]

	await get_tree().process_frame
	history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)

func _on_edit_row_pressed(index: int) -> void:
	editing_index = index
	var entry: Dictionary = GameState.history[index]

	_edit_calls_mi = int(entry.get("calls_a", 0))
	_edit_calls_vi = int(entry.get("calls_b", 0))
	_edit_hand_total = GameState.BASE_POINTS + _edit_calls_mi + _edit_calls_vi

	_edit_syncing = true
	edit_mi.text = str(int(entry.get("delta_a", 0)))
	edit_vi.text = str(int(entry.get("delta_b", 0)))
	_edit_syncing = false

	edit_error.text = ""
	edit_dialog.popup_centered()

func _on_edit_confirmed() -> void:
	if editing_index == -1:
		return

	if edit_mi.text == "" or edit_vi.text == "":
		edit_error.text = "Upiši broj."
		edit_dialog.popup_centered()
		return

	var mi_total := int(edit_mi.text)
	var vi_total := int(edit_vi.text)

	if mi_total + vi_total != _edit_hand_total:
		edit_error.text = "Zbroj mora biti %d." % _edit_hand_total
		edit_dialog.popup_centered()
		return

	var team_total := mi_total if editing_team == 0 else vi_total
	GameState.update_points_with_team(editing_index, editing_team, team_total)

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

func _on_edit_points_changed(_t: String, side: int) -> void:
	if _edit_syncing:
		return

	var src := edit_mi if side == 0 else edit_vi
	var other := edit_vi if side == 0 else edit_mi
	if not src.has_focus():
		return

	editing_team = side
	_edit_syncing = true

	var v := 0
	if src.text != "":
		v = int(src.text)

	var min_v := _edit_calls_mi if side == 0 else _edit_calls_vi
	var max_v := _edit_hand_total - (_edit_calls_vi if side == 0 else _edit_calls_mi)
	v = clamp(v, min_v, max_v)

	src.text = str(v)
	other.text = str(_edit_hand_total - v)

	_edit_syncing = false
