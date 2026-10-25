extends Control

var total : int = 0
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
var prestige_cost :int = 10000

# --- Crit settings ---
var crit_chance: float = 0.05   # 15% chance to crit
var crit_multiplier: float = 2.0
var crit_cost: int
var crit_compound: String
var crit_count : int


var _shake_tween: Tween
var _shake_start: Vector2

# --- Save / Prestige ---
var SAVE_PATH := "user://savegame.json"

var prestige_points : int = 0
var prestige_level  : int = 0
var lifetime_total  : int = 0
var prestige_compound : String 

var autosave_timer : float = 0.0
const AUTOSAVE_INTERVAL := 30.0  # seconds


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Start.visible = true
	%Clickers.hide()
	%Click_power.hide()
	%Prestige.hide()
	%Crit.hide()
	
	call_deferred("_set_button_pivots")
	randomize()
	load_game() 
	
func _exit_tree() -> void:
	save_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"total": total,
			"clickers_count": clickers_count,
			"clickers_cost": clickers_cost,
			"clickpowers_count": clickpowers_count,
			"clickpowers_cost": clickpowers_cost,
			"unlocked_state": unlocked_state,
			"prestige_points": prestige_points,
			"prestige_level": prestige_level,
			"prestige_cost": prestige_cost,
			"lifetime_total": lifetime_total,
			"crit_chance": crit_chance,
			"crit_multiplier": crit_multiplier
		}
		file.store_var(data)
		file.close()

func load_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		
		total = data.get("total", 0)
		clickers_count = data.get("clickers_count", 0)
		clickers_cost = data.get("clickers_cost", 20)
		clickpowers_count = data.get("clickpowers_count", 0)
		clickpowers_cost = data.get("clickpowers_cost", 50)
		unlocked_state = data.get("unlocked_state", 0)
		prestige_points = data.get("prestige_points", 0)
		prestige_level = data.get("prestige_level", 0)
		prestige_cost = data.get("prestige_cost", 1000)
		lifetime_total = data.get("lifetime_total", 0)
		crit_chance = data.get("crit_chance", 0.15)
		crit_multiplier = data.get("crit_multiplier", 2.0)
		
		# Refresh UI labels
		%Total.text = str(total)
		clickers_compound = "level: " + str(clickers_count) + ", cost: " + str(clickers_cost)
		clickpowers_compound = "level: " + str(clickpowers_count) + ", cost: " + str(clickpowers_cost)
		clickers_stat.text = clickers_compound
		click_power_stat.text = clickpowers_compound

func _set_button_pivots() -> void:
	if %Clicker:
		%Clicker.pivot_offset = %Clicker.size / 2.0
	if %Upgrade1:
		%Upgrade1.pivot_offset = %Upgrade1.size / 2.0
	if %Upgrade2:
		%Upgrade2.pivot_offset = %Upgrade2.size / 2.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	clickpowers_compound = "level: " + str(clickpowers_count) + ", " + "cost: " + str(clickpowers_cost)
	clickers_compound = "level: " + str(clickers_count) + ", " + "cost: " + str(clickers_cost)
	prestige_compound = "level: " + str(prestige_level) + ", " + "cost: " + str(prestige_cost)
	crit_compound = "level: " + str(crit_count) + ", " + "cost: " + str(crit_cost)
	click_power_stat.text = clickpowers_compound
	clickers_stat.text = clickers_compound
	%Cost_level_crit.text = crit_compound
	%Cost_level_p.text = prestige_compound
	%Upgrade1.disabled = clickers_cost > total
	%Upgrade2.disabled = clickpowers_cost > total
	%Upgrade3.disabled = clickers_cost > total
	%Upgrade4.disabled = prestige_cost > total
	%Total.text = str(total)
	time_accumulator += delta
	if time_accumulator >= 1.0:
		time_accumulator -= 1.0
		agg_total = (clickpowers_count+1)*clickers_count
		total += agg_total
		lifetime_total += agg_total
		spawn_confetti(Vector2(576,321), agg_total)
	autosave_timer += delta
	if autosave_timer >= AUTOSAVE_INTERVAL:
		autosave_timer -= AUTOSAVE_INTERVAL
		save_game()



func spawn_confetti(spawn_position: Vector2, count: int, scale_mult: float = 1.0) -> void:
	for i in range(count):
		var confetti = TextureRect.new()
		confetti.texture = guy_texture
		confetti.pivot_offset = guy_texture.get_size() / 2.0
		add_child(confetti)
		confetti.position = spawn_position - (guy_texture.get_size() / 2.0)
		
		var angle = randf_range(0.0, TAU)
		var speed = randf_range(200.0, 500.0) * scale_mult
		var velocity = Vector2(cos(angle), sin(angle)) * speed
		
		confetti.rotation = randf_range(0.0, TAU)
		var random_scale = randf_range(0.5, 1.2) * scale_mult
		confetti.scale = Vector2(random_scale, random_scale)
		
		var tween = create_tween().set_parallel(true)
		var start_pos = confetti.position
		var target_pos = start_pos + velocity + Vector2(0, randf_range(150.0, 350.0) * scale_mult)
		tween.tween_property(confetti, "position", target_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(confetti, "rotation", confetti.rotation + randf_range(-6.0, 6.0), 1.2)
		tween.chain().tween_property(confetti, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(confetti.queue_free)

func _spawn_float_text(sp_position: Vector2, text: String, is_crit: bool = false) -> void:
	var offset = Vector2(randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	var spawn_pos = sp_position + offset

	var label = Label.new()
	label.text = text
	label.position = spawn_pos
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if is_crit:
		label.add_theme_font_size_override("font_size", 72)
		label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))  # red
	else:
		label.add_theme_font_size_override("font_size", 48)
	
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position", spawn_pos - Vector2(0, 60), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(label.queue_free)

func _tween_button_press(btn: Button, degrees: float = 6.0) -> void:
	var rad = deg_to_rad(degrees)
	var tween = create_tween()
	tween.tween_property(btn, "rotation", rad, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "rotation", 0.0, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _screenshake(target: Node, magnitude: float = 14.0, duration: float = 0.25) -> void:
	if _shake_tween:
		_shake_tween.kill()
		target.position = _shake_start

	var start = target.position
	_shake_start = start
	_shake_tween = create_tween()

	var shakes = 8
	var step = duration / shakes
	for i in range(shakes):
		var off = Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
		_shake_tween.tween_property(target, "position", start + off, step).set_trans(Tween.TRANS_LINEAR)
		if i < shakes - 1:
			_shake_tween.tween_property(target, "position", start, step).set_trans(Tween.TRANS_LINEAR)

	_shake_tween.tween_callback(func(): target.position = start)

func _on_button_pressed() -> void:
	%Start.visible = false

func _on_clicker_pressed() -> void:
	var is_crit = randf() < crit_chance
	var base_gain = clickpowers_count + 1
	var prestige_bonus = 1.0 + (prestige_level * 0.1)   # +10% per prestige level
	var gain = int(base_gain * prestige_bonus)
	
	if is_crit:
		gain = int(base_gain * crit_multiplier)
	
	total += gain
	lifetime_total += gain   
	click_total = gain
	%Total.text = str(total)
	var button_center = Vector2(576, 321)
	
	if is_crit:
		# Big confetti burst on crit
		spawn_confetti(button_center, max(click_total, 5), 2.5)
		_spawn_float_text(button_center, "+" + str(click_total) + " CRIT!", true)
		_screenshake(get_parent().get_node("Main"), 12.0, 0.2)
	else:
		spawn_confetti(button_center, click_total, 1.0)
		_spawn_float_text(button_center, "+" + str(click_total), false)
	
	_tween_button_press(%Clicker, randf_range(-6.0, 6.0))

	if unlocked_state < 1 and total >= 50:
		%Clickers.show()
		unlocked_state = 1
		_screenshake(get_parent().get_node("Main"), 16.0, 0.3)

	if unlocked_state < 2 and total >= 150:
		%Click_power.show()
		unlocked_state = 2
		_screenshake(get_parent().get_node("Main"), 20.0, 0.4)
	if unlocked_state < 3 and total >= 1000:
		%Crit.show()
		unlocked_state = 3
		_screenshake(get_parent().get_node("Main"), 20.0, 0.4)
	if unlocked_state < 4 and total >= 5000:
		%Prestige.show()
		unlocked_state = 4
		_screenshake(get_parent().get_node("Main"), 20.0, 0.4)

@export var guy_texture: Texture2D = preload("uid://dlhbiybs4wx4m")
@export var confetti_count: int = 1

func _on_upgrade_2_pressed() -> void:
	total -= clickpowers_cost
	clickpowers_count += 1
	clickpowers_cost = (1.3**clickpowers_count) * 50
	_tween_button_press(%Upgrade2, randf_range(-4.0, 4.0))

func _on_upgrade_1_pressed() -> void:
	total -= clickers_cost
	clickers_count += 1
	clickers_cost = (1.3**clickers_count) * 20
	_tween_button_press(%Upgrade1, randf_range(-4.0, 4.0))


func _on_upgrade_4_pressed() -> void:
	if total < prestige_cost:
		return  # not enough yet
	
	# Calculate prestige points gained this run
	var gained = max(1, floor(lifetime_total / 1000))
	
	prestige_points += gained
	prestige_level += 1
	prestige_cost = int(prestige_cost * 1.5)  # gets more expensive each time
	
	# Reset the run
	total = 0
	clickers_count = 0
	clickers_cost = 20
	clickpowers_count = 0
	clickpowers_cost = 50
	unlocked_state = 0
	lifetime_total = 0
	
	# Hide unlock panels again
	%Clickers.hide()
	%Click_power.hide()
	%Crit.hide()
	%Prestige.hide()
	
	# Refresh UI
	%Total.text = str(total)
	clickers_compound = "level: " + str(clickers_count) + ", cost: " + str(clickers_cost)
	clickpowers_compound = "level: " + str(clickpowers_count) + ", cost: " + str(clickpowers_cost)
	clickers_stat.text = clickers_compound
	click_power_stat.text = clickpowers_compound
	%Upgrade1.disabled = true
	%Upgrade2.disabled = true
	
	save_game()
	_tween_button_press(%Upgrade4, randf_range(-4.0, 4.0))

func _on_upgrade_3_pressed() -> void:
	total -= crit_cost
	crit_count += 1
	crit_chance = crit_chance * 1.1
	crit_multiplier = crit_multiplier * 1.05
	crit_cost = (1.3**crit_count) * 150
	_tween_button_press(%Upgrade3, randf_range(-4.0, 4.0))
