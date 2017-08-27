extends WorldEnvironment

onready var camroot = get_node("camroot")
onready var tween   = get_node("tween")
onready var timer   = get_node("timer")

var grid = []            # holds instaces of the circles
var grid_new = []        # holds booleans
var h = 64               # ring count
var w = 16               # ring divisions 
var last_hovered = null  # last hovered circle

func _ready():
	
	seed(OS.get_unix_time())
	
	# set up our 2d arrays	
	grid.resize(h)
	grid_new.resize(h)
	for y in range(h):
		grid[y] = []
		grid[y].resize(w)
		grid_new[y] = []
		grid_new[y].resize(w)
	
	# get mesh data
	var faces = get_node("torusmesh").mesh.get_faces()

	# start looping over all quads
	# a quad is 6 points (2 triangles)
	var x = 0
	var y = 0
	for i in range(0,faces.size(),6):
		
		# get 4 corners of the quad
		var p1 = faces[i]
		var p2 = faces[i+1]
		var p3 = faces[i+2]
		var p4 = faces[i+5] # this is highly topology dependent!
		
		# get center
		var pos = (p1+p2+p3+p4)/4
		
		# get sides of triangle
		var s1 = p2 - p1
		var s2 = p3 - p1
		
		# create a basis of this triangle/quad
		var basis_x = s1.normalized()
		var basis_y = s2.normalized()
		var basis_z = basis_x.cross(basis_y)
		var basis = Basis(basis_x, basis_y, basis_z) # this works perfectly so do not touch it
		
		# create circle object
		var circle = preload("res://scenes/circle.tscn").instance()
		circle.translate(pos) 
		circle.transform.basis = basis   # rotate it to face
		circle.scale = Vector3(s1.length()/2, s2.length()/2, 0.1) # length divided by 2 since by default size of circle is 1,1,1
		circle.connect("input_event", self, "circle_event", [circle])
		
		add_child(circle)
		grid[y][x] = circle
		
		# TODO use texture coordinates for this - right now this is hacky
		x += 1 
		if x >= w:
			x = 0
			y += 1
		
	
	set_process(true)
	set_process_input(true)
	
	# wait 1 frame to prevent resurrect() being called too early, then start GoL
	yield(get_tree(), "idle_frame")
	gen()
	
var generation = 0
func gen():
	
	generation += 1
	var frameskipper = 0
	
	for y in range(h):
		
		# divide every generation over 32 frames (based off of 60fps vsync, will go faster on 144hz monitors)
		frameskipper += 1
		if frameskipper > h/32: 
			yield(get_tree(), "idle_frame") # skip a frame
			frameskipper = 0
		
		for x in range(w):
			
			# do one generation of GoL
			
			if generation == 1:  # first generation is random
				grid_new[y][x] = randf()>0.8
				continue

			var alive = grid[y][x].alive
			var new_alive = false
			
			# count alive neighbors
			var neighbors = 0
			for y_add in range(-1,2):
				for x_add in range(-1,2):
					if y_add == 0 && x_add == 0:  # don't count ourselves
						continue
					if grid[fposmod(y+y_add,h)][fposmod(x+x_add,w)].alive:
						neighbors += 1
			
			if alive:
				if neighbors >= 2 && neighbors <= 3:
					new_alive = true
			else:
				if neighbors == 3:
					new_alive = true
			#
			grid_new[y][x] = new_alive
	
	# activate new tiles (this needs to be done in a second pass)
	for y in range(h):
		for x in range(w):
			grid[y][x].resurrect(grid_new[y][x]) 
	
	# continue
	gen()
	
func _process(delta):
	
	# rotate camera
	camroot.rotate_y(delta/10)
	
func _input(event):
	
	# quit when esc is pressed
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
func circle_event(camera, event, click_pos, click_normal, shape_idx, obj):
	
	# only keep 1 circle hovered at a time
	obj.hover(true)
	if last_hovered != null && last_hovered != obj:
		last_hovered.hover(false)
	last_hovered = obj
	
	# activate/deactivate circles when clicked
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		obj.resurrect(true)
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		obj.resurrect(false)


func _on_bg_input_event(camera, event, click_pos, click_normal, shape_idx):
	
	# nothing hovered
	if last_hovered != null:
		last_hovered.hover(false)
	last_hovered = null
