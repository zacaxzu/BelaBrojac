extends Control

func _on_button_pressed() -> void:
	var target_score: int = %TargetOption.get_item_id(%TargetOption.selected)
	GameState.new_match(target_score)
	get_tree().change_scene_to_file("res://screens/Match.tscn")

func _ready() -> void:
	%TargetOption.clear()
	%TargetOption.add_item("701", 701)
	%TargetOption.add_item("1001", 1001)
	%TargetOption.select(1) # default 1001 (druga stavka)
