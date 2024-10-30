extends Control

@onready var button_controller: Control = $ButtonController
@onready var button: Button = $ButtonController/Button
@onready var button_color: ColorRect = $ButtonController/Button/ColorRect
@onready var button_steam_particles: GPUParticles2D = $ButtonController/Button/GPUParticles2D

@onready var combo_fill: ColorRect = $ComboMeter/Fill
@onready var combo_background: ColorRect = $ComboMeter/Background
@onready var combo_text: RichTextLabel = $ComboText
@onready var combo_level_text: RichTextLabel = $ComboMeter/ComboLevel

@onready var orig_button_controller_pos: Vector2 = Vector2(button_controller.global_position)

@onready var fireA: Control = $ButtonController/FireA
@onready var fireB: Control = $ButtonController/FireB
@onready var fireC: Control = $ButtonController/FireC
@onready var fireD: Control = $ButtonController/FireD

@onready var fireAButton: Button = $ButtonController/FireA/Button
@onready var fireBButton: Button = $ButtonController/FireB/Button
@onready var fireCButton: Button = $ButtonController/FireC/Button
@onready var fireDButton: Button = $ButtonController/FireD/Button

@onready var win_screen: Control = $WinScreen

@onready var ghostA: Button = $GhostA
@onready var ghostB: Button = $GhostB

@onready var click_particles: PackedScene = preload("res://click_particles.tscn")
@onready var fire_extinguish_particles: PackedScene = preload("res://smoke.tscn")
@onready var ghost_dispel_particles: PackedScene = preload("res://ghost_dispel.tscn")

var combo_template_text: String = "[outline_color={olcolor}][outline_size=10][center][font_size={fsize}][color=black]x{amt}"

var combo: float = 0

var combo_levels = {
	50: "[color=salmon]OKAY",
	75: "[color=tomato]DECENT",
	100: "[color=maroon]ALRIGHT",
	125: "[color=crimson]SOMEWHAT SKILLED",
	150: "[color=lime]GOOD",
	175: "[color=spring_green]SKILLED",
	200: "[color=turquoise]GREAT",
	225: "[color=cyan]AWESOME",
	250: "[color=royal_blue]GOATED",
	275: "[color=medium_blue]EXCELLENT",
	300: "[color=dark_blue]INCREDIBLE",
	325: "[color=indigo]GODLIKE",
}

var combo_level_template_text: String = "[font_size=50][outline_color=black][outline_size=10][shake rate={sr} level={sl} connected=1] {txt} "
var prev_level: String = ""

@onready var click_sounds_player: AudioStreamPlayer2D = $ClickSoundsPlayer
@onready var explosion_sounds_player: AudioStreamPlayer2D = $ExplosionSoundsPlayer
@onready var extinguish_sounds_player: AudioStreamPlayer2D = $ExtinguishSoundsPlayer
@onready var ghost_jumpscare_sounds_player: AudioStreamPlayer2D = $DeathSoundsPlayer

@onready var color_heat_gradient: Gradient = preload("res://color_heat_gradient.tres").gradient

func _ready() -> void:
	fireA.hide()
	fireB.hide()
	fireC.hide()
	fireD.hide()
	fireAButton.get_child(0).play("default")
	fireBButton.get_child(0).play("default")
	fireCButton.get_child(0).play("default")
	fireDButton.get_child(0).play("default")
	
	ghostA.hide()
	ghostB.hide()
	
	ghostA.get_child(0).play("default")
	ghostB.get_child(0).play("default")

func _on_button_pressed() -> void:
	
	if fireA.visible or fireB.visible or fireC.visible or fireD.visible:
		return

	combo += 1
	time_since_last_click = 0
	
	if combo > 50:
		click_sounds_player.pitch_scale = 1 - combo / 500
	else:
		click_sounds_player.pitch_scale = 1
	click_sounds_player.play()
	
	var new_click_particles: GPUParticles2D = click_particles.instantiate()
	add_child(new_click_particles)
	new_click_particles.process_material.color.b8 = 255 - combo * 2
	new_click_particles.process_material.color.g8 = 255 - combo * 2
	new_click_particles.global_position = get_viewport().get_mouse_position()
	new_click_particles.emitting = true
	new_click_particles.finished.connect(func (): new_click_particles.queue_free())

	button.release_focus()

var time_since_last_click: float = 0.0

@onready var combo_text_original_pos = Vector2(combo_text.position)

var time_since_new_combo_level_achieved: float = 0.0

func _physics_process(delta: float) -> void:
	
	if fireA.visible or fireB.visible or fireC.visible or fireD.visible:
		button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	combo_fill.size.x = combo * 3
	
	if combo_fill.size.x > combo_background.size.x:
		win_screen.show()
		win_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	
	#button_color.color.b8 = 255 - combo
	#button_color.color.g8 = 255 - combo
	button_color.color = color_heat_gradient.sample(combo / 333)
	
	#combo_fill.color.b8 = 255 - combo / 4
	#combo_fill.color.g8 = 255 - combo / 4
	
	time_since_last_click += delta
	if time_since_last_click > 2.0:
		combo -= 0.7
		combo = maxf(0, combo)
		if combo > 50:
			button_steam_particles.emitting = true
		else:
			button_steam_particles.emitting = false
	else:
		button_steam_particles.emitting = false
	
	if combo < 50:
		combo_level_text.text = ""
		time_since_new_combo_level_achieved = 0.0
	else:
		for level in combo_levels:
			if combo > level and combo < level + 25:
				if prev_level != combo_levels[level]:
					prev_level = combo_levels[level]
					combo_level_text.visible_ratio = 0.0
					time_since_new_combo_level_achieved = 0.0
					var new_text = combo_level_template_text.replace("{txt}", combo_levels[level])
					new_text = new_text.replace("{sr}", str(20 * (1 + combo / 333)))
					new_text = new_text.replace("{sl}", str(5 * (1 + combo / 333)))
					combo_level_text.text = new_text
				else:
					combo_level_text.visible_ratio = clampf(time_since_new_combo_level_achieved * 2, 0, 1)
				break
	time_since_new_combo_level_achieved += delta
	
	if combo > 50:
		button_controller.position.x = orig_button_controller_pos.x + clampf(randf_range(-1 * (combo / 50), 1 * (combo / 50)), -5.0, 5.0)
		button_controller.position.y = orig_button_controller_pos.y + clampf(randf_range(-1 * (combo / 50), 1 * (combo / 50)), -5.0, 5.0)
	
	if combo > 50 and randi_range(0, maxi(int(800 - combo * 2), 1)) == 1:
		var randfire = randi_range(0, 3)
		if randfire == 3:
			fireA.show()
			fireAButton.mouse_filter = Control.MOUSE_FILTER_STOP
		elif randfire == 2:
			fireB.show()
			fireBButton.mouse_filter = Control.MOUSE_FILTER_STOP
		elif randfire == 1:
			fireC.show()
			fireCButton.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			fireD.show()
			fireDButton.mouse_filter = Control.MOUSE_FILTER_STOP
	
	#if fireA.visible or fireB.visible or fireC.visible or fireD.visible:
		#button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#else:
		#button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if combo > 150 and randi_range(1, maxi(int(800 - combo * 1.5), 1)) == 1:
		if randi_range(0, 1) == 1:
			ghostA.show()
		else:
			ghostB.show()

	if ghostA.visible:
		ghostA.global_position = ghostA.global_position.move_toward(Vector2(combo_fill.global_position.x + combo_fill.size.x, combo_text.global_position.y), delta * 150)
	if ghostB.visible:
		ghostB.global_position = ghostB.global_position.move_toward(Vector2(combo_fill.global_position.x + combo_fill.size.x, combo_text.global_position.y), delta * 150)
		
	if ghostA.global_position.distance_to(Vector2(combo_fill.global_position.x + combo_fill.size.x, combo_text.global_position.y)) < 10:
		combo = 0
		ghostA.hide()
		ghostA.global_position = ghostPosA
		ghost_jumpscare_sounds_player.play()
	if ghostB.global_position.distance_to(Vector2(combo_fill.global_position.x + combo_fill.size.x, combo_text.global_position.y)) < 10:
		combo = 0
		ghostB.hide()
		ghostB.global_position = ghostPosB
		ghost_jumpscare_sounds_player.play()

func _process(delta: float) -> void:
	if combo > 0:
		var new_text = combo_template_text.replace("{amt}", str(int(combo))) 
		if combo > 0:
			combo_text.position.x = combo_text_original_pos.x + clampf(randf_range(-1 * (combo / 100), 1 * (combo / 100)), -5.0, 5.0)
			combo_text.position.y = combo_text_original_pos.y + clampf(randf_range(-1 * (combo / 100), 1 * (combo / 100)), -5.0, 5.0)
			#new_text = new_text.replace("{shake}", "[shake rate=" + str(combo / 5) + ", level=" + str(combo / 5) + "]")
		else:
			combo_text.position = combo_text_original_pos
			#new_text = new_text.replace("{shake}", "")
		var color = button_color.color
		color.b8 = 255 - combo * 4
		color.g8 = 255 - combo * 4
		new_text = new_text.replace("{olcolor}", "#" + str(color.to_html()))
		new_text = new_text.replace("{fsize}", str(100 * maxf(2 - time_since_last_click * 3, 1)))
		combo_text.text = new_text
	else:
		combo_text.text = "[center][font_size=100]"

func spawn_extinguish_particles() -> void:
	var new_smoke: GPUParticles2D = fire_extinguish_particles.instantiate()
	add_child(new_smoke)
	new_smoke.global_position = get_viewport().get_mouse_position()
	new_smoke.emitting = true
	new_smoke.finished.connect(func (): new_smoke.queue_free())

func _on_fireD_pressed() -> void:
	fireD.hide()
	fireDButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spawn_extinguish_particles()
	extinguish_sounds_player.play()
	fireDButton.release_focus()

func _on_fireC_pressed() -> void:
	fireC.hide()
	fireCButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spawn_extinguish_particles()
	extinguish_sounds_player.play()
	fireCButton.release_focus()

func _on_fireB_pressed() -> void:
	fireB.hide()
	fireBButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spawn_extinguish_particles()
	extinguish_sounds_player.play()
	fireBButton.release_focus()

func _on_fireA_pressed() -> void:
	fireA.hide()
	fireAButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spawn_extinguish_particles()
	extinguish_sounds_player.play()
	fireAButton.release_focus()

func spawn_firework_particles() -> void:
	var new_fireworks: GPUParticles2D = ghost_dispel_particles.instantiate()
	add_child(new_fireworks)
	new_fireworks.global_position = get_viewport().get_mouse_position()
	new_fireworks.emitting = true
	new_fireworks.finished.connect(func (): new_fireworks.queue_free())

@onready var ghostPosA = Vector2(ghostA.global_position)
@onready var ghostPosB = Vector2(ghostB.global_position)

func _on_ghost_a_pressed() -> void:
	spawn_firework_particles()
	explosion_sounds_player.play()
	ghostA.hide()
	ghostA.global_position = ghostPosA
	ghostA.release_focus()

func _on_ghost_b_pressed() -> void:
	spawn_firework_particles()
	explosion_sounds_player.play()
	ghostB.hide()
	ghostB.global_position = ghostPosB
	ghostB.release_focus()
