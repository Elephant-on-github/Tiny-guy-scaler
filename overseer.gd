extends Control

var total : int =0
var unlocked_state:int = 0
@onready var clickers_stat : Label = %Cost_level
@onready var click_power_stat : Label = %Cost_level_c
var clickers_cost :int
var clickers_count :int
var clickers_compound : String
var clickpowers_cost :int 
var clickpowers_count :int
var clickpowers_compound : String
var time_accumulator: float = 0.0
var click_total: int
var agg_total : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Start.visible = true
	%Clickers.hide()
	%Click_power.hide()
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	clickpowers_compound = "level: " + str(clickpowers_count) + ", " + "cost: " + str(clickpowers_cost)
	clickers_compound = "level: " + str(clickers_count) + ", " + "cost: " + str(clickers_cost)
	click_power_stat.text = clickpowers_compound
	clickers_stat.text = clickers_compound
	%Upgrade1.disabled = clickers_cost > total
	%Upgrade2.disabled = clickpowers_cost > total
	%Total.text = str(total)
	time_accumulator += delta
	if time_accumulator >= 1.0:
		time_accumulator -= 1.0
		agg_total = (clickpowers_count+1)*clickers_count
		total += agg_total
		spawn_confetti(Vector2(576,321), agg_total)
func spawn_confetti(spawn_position: Vector2, _confetti_count) -> void:
	for i in range(_confetti_count):
		# 1. Create a TextureRect
		var confetti = TextureRect.new()
		confetti.texture = guy_texture
		
		# Set pivot point to center so rotations spin around its middle
		confetti.pivot_offset = guy_texture.get_size() / 2.0
		
		# Add to the current node
		add_child(confetti)
		
		# Center the texture on the click position
		confetti.position = spawn_position - (guy_texture.get_size() / 2.0)

		# 2. Calculate random burst trajectory
		var angle = randf_range(0.0, TAU)
		var speed = randf_range(200.0, 500.0)
		var velocity = Vector2(cos(angle), sin(angle)) * speed
		
		# Initial rotation and scale variation
		confetti.rotation = randf_range(0.0, TAU)
		var random_scale = randf_range(0.5, 1.2)
		confetti.scale = Vector2(random_scale, random_scale)
		
		# 3. Animate using a Tween
		var tween = create_tween().set_parallel(true)
		
		# Move outward and fall downwards with gravity
		var start_pos = confetti.position
		var target_pos = start_pos + velocity + Vector2(0, randf_range(150.0, 350.0))
		tween.tween_property(confetti, "position", target_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Spin while exploding
		tween.tween_property(confetti, "rotation", confetti.rotation + randf_range(-6.0, 6.0), 1.2)
		
		# Fade out near the end
		tween.chain().tween_property(confetti, "modulate:a", 0.0, 0.3)
		
		# Clean up after animation finishes
		tween.chain().tween_callback(confetti.queue_free)


func _on_button_pressed() -> void:
	%Start.visible = false
	


func _on_clicker_pressed() -> void:
	total += 1
	click_total = clickpowers_count+1
	%Total.text = str(total)
	var button_center = Vector2(576,321)
	spawn_confetti(button_center, click_total)
	if unlocked_state < 1 and total >= 50:
		%Clickers.show()
		unlocked_state = 1

	if unlocked_state < 2 and total >= 150:
		%Click_power.show()
		unlocked_state = 2

	


# Load your custom texture or scene
@export var guy_texture: Texture2D = preload("uid://dlhbiybs4wx4m") 
@export var confetti_count: int = 1


func _on_upgrade_2_pressed() -> void:
	total -= clickpowers_cost
	clickpowers_count += 1
	clickpowers_cost = (1.3**clickpowers_count) * 50


func _on_upgrade_1_pressed() -> void:
	total -= clickers_cost
	clickers_count += 1
	clickers_cost = (1.3**clickers_count) * 20
