extends Area2D
#The brief shield is only meant to last for a few frames

var frames_to_live = 3
var frame = 0
signal set_orb_st

func _physics_process(_delta):
	frame += 1
	if frame == frames_to_live:
		queue_free()


func _on_tree_exiting():
	set_orb_st.emit(0)
