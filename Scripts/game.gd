extends Node

# UI data
onready var UI: MarginContainer = $UI

# board data
onready var board: Spatial = $board
var current_tile: int
var board_tiles: Array

# player data
var player: KinematicBody
var player_scene: Resource = preload("res://Scenes/Player/player.tscn")

# dice data
onready var dice: RigidBody = $dice

# memory data
var memory: Dictionary = {}
var global_time: int = 0
var player_time: int = 0
var players: Array = []

func _ready():
	# setup UI
	UI.connect("roll", self, "_on_roll_dice")
	UI.connect("add_player", self, "_on_add_player")
	
	# setup board
	board_tiles = board.request_board_tiles()
	
	# setup player
	player = initiate_player(board_tiles.front().translation)
	player.connect("player_landed", self, "_on_player_landed")
	
	# setup dice
	dice.connect("rolled_value", self, "_on_rolled_value")

var can_roll: bool = true
func _on_roll_dice():
	if can_roll:
		can_roll = false
		dice.roll_dice()

func _on_add_player(time: int):
	if !memory.has(time):
		print("player has not been in this time period yet")
	else:
		print(memory[time])
		var player_data = memory[time][0]
		var pos = player_data.position
		var player = initiate_player(board_tiles[pos].translation)

func _on_rolled_value(val: int):	
	if memory.has(global_time):
		memory[global_time].push_back({
			"player_time": player_time,
			"position": current_tile
		})
	else:
		memory[global_time] = [{
			"player_time": player_time,
			"position": current_tile
		}]
	
	var target: int = (current_tile + val)%board_tiles.size()
	var path: Array = [board_tiles[current_tile]]
	while current_tile != target:
		current_tile = (current_tile + 1) % board_tiles.size()
		path.append(board_tiles[current_tile])
	player.queue_target(path)

func _on_player_landed(idx: int):
	if idx == 0: # if main player
		can_roll = true
		player_time += 1
		global_time += 1
		board_tiles[current_tile].player_lands() ## calls node function
	else:
		simulate_player(idx + 1)

func initiate_player(initial_position: Vector3) -> KinematicBody:
	var player: KinematicBody = player_scene.instance()
	
	player.translation = initial_position + Vector3.UP * 3
	player.scale *= 0.4
	
	var rand_offset: Vector3 = Vector3(rand_range(-1.5,1.5),0,rand_range(-1.5,1.5))
	player.get_node("col").translation += rand_offset
	player.get_node("body_cont").translation += rand_offset
	
	player.set_idx(players.size())
	add_child(player)
	return player

func simulate_player(idx: int) -> void:
	var player: KinematicBody = players[idx]
	var player_time: int = player.get_time()
