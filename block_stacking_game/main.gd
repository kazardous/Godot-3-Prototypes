extends Node2D

const LEFT = -1
const RIGHT = 1
const BLOCK_SIZE = 8
const START_COL = 0

onready var cursor: Node2D = $Cursor
onready var cursor_timer: Timer = $CursorTimer
onready var bottom: Position2D = $Bottom
onready var place_timer: Timer = $PlaceTimer

var block_scene : PackedScene = preload("res://block_stacking_game/block.tscn")

var current_layer : int = 0 # Current layer cursor is on
var current_col : int = START_COL # Easy way to track where the cursor is
var move_dir : int = RIGHT
var cursor_size : int = 3

# Blocks per layer
var per_layer : Array = [5,3,3,2,2,2,2,2,2,1,1, # FIRST HURDLE
						 1,1,1,1] # SECOND HURDLE

# 2D array that stores block locations on a layer.
var block_positions : Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up where the blocks will store their locations
	for i in per_layer.size():
		block_positions.append([0,0,0,0,0,0,0])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		get_tree().reload_current_scene()
	
	if current_layer >= per_layer.size():
		return
	
	if place_timer.time_left <= 0:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.is_pressed()):
			set_block(current_layer, per_layer[current_layer])
			current_layer += 1
			
			cursor.hide()
			
			# TODO: Game win!
			if current_layer >= per_layer.size():
				return
			
			# TODO: Game over!
			if cursor_size == 0:
				print("GAME OVER!")
				return
			
			place_timer.start()


# Set blocks on layer
func set_block(layer: int, size: int) -> void:
	# For each tile in the size of the block
	var num_placed : int = 0
	for tile in size:
		# Check if block is out of bounds
		if current_col + tile < 0 or current_col + tile > 6:
			continue
		
		# Check below this block tile (skip on layer 0)
		if current_layer != 0:
			# If the block is floating, skip it
			if block_positions[layer - 1][current_col + tile] == 0:
				continue
		
		# Store tile data
		block_positions[layer][current_col + tile] = 1
		num_placed += 1
		
		# Create block tile
		var block = block_scene.instance()
		$Blocks.add_child(block)
		
		# Set the position of the block tile
		block.position.x = cursor.position.x + (BLOCK_SIZE * tile)
		block.position.y = bottom.position.y - (BLOCK_SIZE * layer)
	
	# Shrink the cursor size if block was misplaced
	cursor_size = num_placed


# Move the cursor up and change size
func move_cursor_up(layer: int) -> void:
	# Reduce cursor size if applicable
	var curr_size = cursor.get_child_count()
	var cursor_layer_size = per_layer[layer]
	
	cursor_size = min(cursor_layer_size, cursor_size)
	
	if cursor_size < curr_size:
		for i in curr_size - cursor_size: 
			cursor.get_child(cursor.get_child_count() - i - 1).queue_free()
	
	# Snap the cursor to either side
	if current_col < 3:
		cursor.position.x = bottom.position.x - BLOCK_SIZE
		move_dir = RIGHT
		current_col = -1
	else:
		cursor.position.x = bottom.position.x + (BLOCK_SIZE * 6)
		move_dir = LEFT
		current_col = 6
		
	cursor.position.y = bottom.position.y - (layer * BLOCK_SIZE)
	cursor_timer.start()


# Move cursor side-to-side
func _on_CursorTimer_timeout() -> void:
	# Switch movement direction at the edges
	if current_col >= 6:
		# Switch left
		move_dir = LEFT
	elif current_col < (-cursor_size + 2):
		# Switch right
		move_dir = RIGHT
	
	# Move in dir
	cursor.position.x += move_dir * BLOCK_SIZE
	current_col += move_dir

# Allow moving the cursor again after delay
func _on_PlaceTimer_timeout() -> void:
	cursor.show()
	move_cursor_up(current_layer)
	cursor_timer.wait_time -= 0.04
