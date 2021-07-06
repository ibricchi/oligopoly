extends KinematicBody

onready var anim: AnimationPlayer = $anim
onready var body: Spatial = $body_cont/body
onready var smoke_particles: Node = $body_cont/body/ParticleBody/Smoke
onready var spark_particles: Node = $body_cont/body/ParticleBody/Spark
onready var player_mesh: Node = $body_cont/body/player

var idx: int
var time: int
var tile: int
var continuity: int
var money: int
var leases: Array

var target_queue: Array

export var gravity: float = 5
export var speed: float = 2.5
export var min_dist: float = 0.1

var first_frame: bool = true
var velocity: Vector3 = Vector3.ZERO
var just_frame: bool = false
var has_hit_floor: bool = false

signal player_first_land(idx)
signal player_landed(idx)
signal player_vanished(idx)

func _ready():
	player_mesh.visible = true
	smoke_particles.one_shot = true
	spark_particles.one_shot = true

	
func _physics_process(delta):	
	if not target_queue.empty():
		if not target_queue.front().empty():
			just_frame = true
			if first_frame:
				first_frame = false
				anim.stop()
				anim.play("step")
				velocity.y = 2
				
			var target: Spatial = target_queue.front().front()
			var dir: Vector3 = Vector3.ZERO
			dir.x = target.translation.x - translation.x
			dir.z = target.translation.z - translation.z
			
			if abs(dir.x) < min_dist and abs(dir.z) < min_dist:
				velocity.x = 0
				velocity.z = 0
				translation.x = target.translation.x
				translation.z = target.translation.z
				
				target_queue.front().pop_front()
				
				if target_queue.front().empty():
					target.player_lands(idx)
				else:
					target.player_passes(idx)
				
				first_frame = true
			else:
				dir = dir.normalized()
				velocity.x = speed * dir.x
				velocity.z = speed * dir.z
				body.look_at(translation + dir, Vector3.UP)
		else:
			just_frame = false
			target_queue.pop_front()
			emit_signal("player_landed", idx)
	
	velocity.y -= gravity * delta
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if not has_hit_floor and is_on_floor():
		has_hit_floor = true
		emit_signal("player_first_land", idx)
	
func queue_target(target: Array):
	target_queue.push_back(target)

func step():
	time += 1
	var new_leases: Array = []
	for lease in leases:
		lease["ttl"] -= 1
		if lease["ttl"] > 0:
			new_leases.push_back(lease)
		else:
			print("Player %d lost lease for tile %d" % [idx, lease["tile"]])
	leases = new_leases

func force_land():
	emit_signal("player_landed", idx)

func vanish():
	emit_signal("player_vanished", idx)
	
func emit_particles():
	smoke_particles.emitting = true
	spark_particles.emitting = true
