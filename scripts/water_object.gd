extends Area2D


func _on_body_entered(body):
	if body.is_in_group("player_character"):
		body.FSM.elem_vicinity = 1


func _on_body_exited(body):
	if body.is_in_group("player_character"):
		body.FSM.elem_vicinity = 0
