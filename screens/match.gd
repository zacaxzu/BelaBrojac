extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%TargetLabel.text = "Igra se do: %d" % GameState.target


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
