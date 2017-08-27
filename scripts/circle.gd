extends StaticBody
onready var tween = get_node("tween")
onready var mesh = get_node("mesh")
onready var mesh_hover = get_node("mesh_hover")

var alive = false
var epsilon = 1e-6  # do not use 0 here or it becomes weird
var scale_alive = Vector3(1,1,1)
var scale_dead = Vector3(1,1,1) * epsilon

func _ready():
	mesh.scale = scale_dead

func hover(should_hover):
	mesh_hover.visible = should_hover
	
func resurrect(should_resurrect):
	
	if alive == should_resurrect: # only tween if we're actually changing state
		return
		
	alive = should_resurrect
	
	var trans_time = 0.6
	tween.interpolate_property(mesh, "scale", mesh.scale, scale_alive if should_resurrect else scale_dead, trans_time, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start()