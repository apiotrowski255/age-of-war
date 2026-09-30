extends Control


enum menu {root, unit, turret, sell_turret, add_turret_spot}

var current_menu
var queue : Array = []
var loading_unit = false
var load_finish = false

signal spawn_melee
signal spawn_range
signal spawn_tank
signal spawn_super_soldier

# Called when the node enters the scene tree for the first time.
func _ready():
	current_menu = menu.root
	$default_menu/root_hbox_container.show()
	$units_menu.hide()
	$turret_menu.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_queue_hud()
	if queue.size() != 0 and loading_unit == false:
		loading_unit = true
		load_first_unit_in_queue()
	if queue.size() != 0 and loading_unit == true and get_node("/root/main_game").unable_to_spawn == false and load_finish == true:
		_tween_queue_finished(queue[0][0], queue[0][2])
	if loading_unit == true and load_finish == true:
		$sublabel_queue.text = tr("Waiting for space")
	elif loading_unit == true:
		$sublabel_queue.show()
	else:
		$sublabel_queue.hide()


func _on_unit_pressed():
	# Enter unit menu
	$default_menu/root_hbox_container.hide()
	$units_menu.show()
	current_menu = menu.unit
	pass # Replace with function body.


func _on_back_pressed():
	if current_menu != menu.root:
		$units_menu/Label.text = ""
		current_menu = menu.root
		$default_menu/root_hbox_container.show()
		$units_menu.hide()
		$turret_menu.hide()


func _on_advance_pressed():
	if GlobalVariables.player_exp >= GlobalVariables.get_exp_to_next_age():
		GlobalVariables.current_stage += 1
		update_sprites_with_age()
		get_node("/root/main_game/player_base").advance_base_sprite()
		if GlobalVariables.current_stage == GlobalVariables.stage.future:
			$units_menu/HBoxContainer/special.disabled = false
	else:
		$root_label.show()
		$root_label.text = tr("Not enough XP!")
		
	
	


func _on_turret_pressed():
	$default_menu/root_hbox_container.hide()
	$turret_menu.show()
	current_menu = menu.turret

func update_sprites_with_age():
	if GlobalVariables.current_stage == GlobalVariables.stage.knight:
		$units_menu/units_UI.texture = load("res://age of war sprites/ui/units_buttons0002.png")
		$turret_menu/AllTurretUi0001.texture = load("res://age of war sprites/ui/all_turret_UI0002.png")
		%SpecialButtonSprite.texture = load("res://age of war sprites/ui/special_buttons0002.png")
	elif GlobalVariables.current_stage == GlobalVariables.stage.medival:
		$units_menu/units_UI.texture = load("res://age of war sprites/ui/units_buttons0003.png")
		$turret_menu/AllTurretUi0001.texture = load("res://age of war sprites/ui/all_turret_UI0003.png")
		%SpecialButtonSprite.texture = load("res://age of war sprites/ui/special_buttons0003.png")
	elif GlobalVariables.current_stage == GlobalVariables.stage.miltary:
		$units_menu/units_UI.texture = load("res://age of war sprites/ui/units_buttons0004.png")
		$turret_menu/AllTurretUi0001.texture = load("res://age of war sprites/ui/all_turret_UI0004.png")
		%SpecialButtonSprite.texture = load("res://age of war sprites/ui/special_buttons0004.png")
	elif GlobalVariables.current_stage == GlobalVariables.stage.future:
		$units_menu/units_UI.texture = load("res://age of war sprites/ui/units_buttons0005.png")
		$turret_menu/AllTurretUi0001.texture = load("res://age of war sprites/ui/all_turret_UI0005.png")
		%SpecialButtonSprite.texture = load("res://age of war sprites/ui/special_buttons0005.png")
		$default_menu/root_hbox_container/advance.disabled = true

func add_to_queue(type: String, load_time: float, stage: String):
	if queue.size() >= 5:
		return
	queue.append([type, load_time, stage])

func load_first_unit_in_queue():
	load_finish = false
	var unit = queue[0]
	var type = unit[0]
	var time_to_load = unit[1]
	var stage = unit[2]
	var tween = create_tween()
	tween.tween_property($queue/ColorRect7, "size", Vector2(432, 16), time_to_load)
	tween.connect("finished", _tween_queue_finished.bind(type, stage))
	tween.play()
	$sublabel_queue.text = tr("Training {unit}...").format({"unit": GlobalVariables.get_unit_name(type, stage)})
	

func queue_load(time, unit: String):
	if queue.size() != 0:
		return
	var tween = create_tween()
	tween.tween_property($queue/ColorRect7, "size", Vector2(432, 16), time)
	tween.connect("finished", _tween_queue_finished.bind(unit))
	tween.play()


func _tween_queue_finished(unit: String, stage: String):
	if get_node("/root/main_game").unable_to_spawn == false:
		emit_signal("spawn_" + unit, stage)
		$queue/ColorRect7.size.x = 0
		loading_unit = false
		queue.pop_front()
		load_finish = false
	else:
		load_finish = true
	

# TODO make money values and time to spawn dynamic based of current age
func _on_melee_pressed():
	if GlobalVariables.player_money >= GlobalVariables.get_unit_cost("melee", GlobalVariables.current_stage):
		if queue.size() < 5:
			GlobalVariables.player_money -= GlobalVariables.get_unit_cost("melee", GlobalVariables.current_stage)
			var stage = GlobalVariables.get_current_age_as_string()
			add_to_queue("melee", 0.5, stage)
	else:
		$units_menu/Label.show()
		$units_menu/Label.text = tr("Not enough money!")


func _on_range_pressed():
	if GlobalVariables.player_money >= GlobalVariables.get_unit_cost("range", GlobalVariables.current_stage):
		if queue.size() < 5:
			GlobalVariables.player_money -= GlobalVariables.get_unit_cost("range", GlobalVariables.current_stage)
			var stage = GlobalVariables.get_current_age_as_string()
			add_to_queue("range", 1, stage)
	else:
		$units_menu/Label.show()
		$units_menu/Label.text = tr("Not enough money!")


func _on_tank_pressed():
	if GlobalVariables.player_money >= GlobalVariables.get_unit_cost("tank", GlobalVariables.current_stage):
		if queue.size() < 5:
			GlobalVariables.player_money -= GlobalVariables.get_unit_cost("tank", GlobalVariables.current_stage)
			var stage = GlobalVariables.get_current_age_as_string()
			add_to_queue("tank", 2.0, stage)
	else:
		$units_menu/Label.show()
		$units_menu/Label.text = tr("Not enough money!")


func _on_special_button_pressed():
	if GlobalVariables.current_stage == GlobalVariables.stage.cave:
		get_node("/root/main_game").cave_special_attack()
		get_node("/root/main_game/Camera2D").apply_shake()
	elif GlobalVariables.current_stage == GlobalVariables.stage.knight:
		get_node("/root/main_game").knight_special_attack()
		get_node("/root/main_game/Camera2D").apply_shake()
	elif GlobalVariables.current_stage == GlobalVariables.stage.medival:
		get_node("/root/main_game").medival_special_attack()
	elif GlobalVariables.current_stage == GlobalVariables.stage.miltary:
		get_node("/root/main_game").miltary_special_attack()
		get_node("/root/main_game/Camera2D").apply_shake()
	elif GlobalVariables.current_stage == GlobalVariables.stage.future:
		get_node("/root/main_game").future_special_attack()
		get_node("/root/main_game/Camera2D").apply_shake()



func update_queue_hud():
	if queue.size() == 0:
		$queue/HBoxContainer/ColorRect.hide()
		$queue/HBoxContainer/ColorRect2.hide()
		$queue/HBoxContainer/ColorRect3.hide()
		$queue/HBoxContainer/ColorRect4.hide()
		$queue/HBoxContainer/ColorRect5.hide()
	elif queue.size() == 1:
		$queue/HBoxContainer/ColorRect.show()
		$queue/HBoxContainer/ColorRect2.hide()
		$queue/HBoxContainer/ColorRect3.hide()
		$queue/HBoxContainer/ColorRect4.hide()
		$queue/HBoxContainer/ColorRect5.hide()
	elif queue.size() == 2: 
		$queue/HBoxContainer/ColorRect.show()
		$queue/HBoxContainer/ColorRect2.show()
		$queue/HBoxContainer/ColorRect3.hide()
		$queue/HBoxContainer/ColorRect4.hide()
		$queue/HBoxContainer/ColorRect5.hide()
	elif queue.size() == 3:
		$queue/HBoxContainer/ColorRect.show()
		$queue/HBoxContainer/ColorRect2.show()
		$queue/HBoxContainer/ColorRect3.show()
		$queue/HBoxContainer/ColorRect4.hide()
		$queue/HBoxContainer/ColorRect5.hide()
	elif queue.size() == 4:
		$queue/HBoxContainer/ColorRect.show()
		$queue/HBoxContainer/ColorRect2.show()
		$queue/HBoxContainer/ColorRect3.show()
		$queue/HBoxContainer/ColorRect4.show()
		$queue/HBoxContainer/ColorRect5.hide()
	elif queue.size() == 5:
		$queue/HBoxContainer/ColorRect.show()
		$queue/HBoxContainer/ColorRect2.show()
		$queue/HBoxContainer/ColorRect3.show()
		$queue/HBoxContainer/ColorRect4.show()
		$queue/HBoxContainer/ColorRect5.show()


func _on_melee_mouse_entered():
	# display melee cost and name
	$units_menu/Label.show()
	$units_menu/Label.text = tr("${price} - {unit}").format({"price" : GlobalVariables.get_unit_cost("melee", GlobalVariables.current_stage),
														"unit" : GlobalVariables.get_unit_name("melee", GlobalVariables.get_current_age_as_string())})


func _on_unit_button_mouse_exited():
	# hide text
	$units_menu/Label.hide()
	$units_menu/Label.text = ""


func _on_range_mouse_entered():
	$units_menu/Label.show()
	$units_menu/Label.text = tr("${price} - {unit}").format({"price" : GlobalVariables.get_unit_cost("range", GlobalVariables.current_stage),
														"unit" : GlobalVariables.get_unit_name("range", GlobalVariables.get_current_age_as_string())})


func _on_tank_mouse_entered():
	$units_menu/Label.show()
	$units_menu/Label.text = tr("${price} - {unit}").format({"price" : GlobalVariables.get_unit_cost("tank", GlobalVariables.current_stage),
														"unit" : GlobalVariables.get_unit_name("tank", GlobalVariables.get_current_age_as_string())})


func _on_turret_1_pressed():
	# change to a turret selected state? 
	# Check if the player has enough money to buy the turret
	if GlobalVariables.player_money >= GlobalVariables.get_turret_price(GlobalVariables.current_stage, 1):
		GlobalVariables.player_money -= GlobalVariables.get_turret_price(GlobalVariables.current_stage, 1)
	else:
		$root_label.show()
		$root_label.text = tr("Not enough money!")
		return
	
	# allow the player to choose where the want to spawn the turret
	# spawn the sprite_follow_mouse object
	var sprite_follow_mouse : Sprite2D = load("res://UI/sprite_follow_player_mouse.tscn").instantiate()
	sprite_follow_mouse.texture = load("res://age of war sprites/bases/" + GlobalVariables.get_current_age_as_string() + "/turret_1/" + GlobalVariables.get_current_age_as_string() + "_turret_1_attack0001.png")
	sprite_follow_mouse.self_modulate = Color(1,1,1, 0.5)
	sprite_follow_mouse.turret_name = GlobalVariables.get_current_age_as_string() + "_turret_1"
	get_node("/root/main_game").add_child(sprite_follow_mouse)
	
	# change context to cancel button
	$turret_menu.hide()
	$buy_turret_cancel.show()
	
	get_node("/root/main_game/player_base").activate_turret_buy_buttons()


func _on_cancel_buy_turret_pressed():
	get_node("/root/main_game/sprite_follow_player_mouse").queue_free()
	$turret_menu.show()
	$buy_turret_cancel.hide()
	get_node("/root/main_game/player_base").deactivate_buttons()
	# refund the price of the turret
	var turret_name = get_node("/root/main_game/sprite_follow_player_mouse").turret_name
	var stage = turret_name.split("_")[0]
	var turret_number = int(turret_name.split("_")[2])
	var refund = GlobalVariables.get_turret_price(GlobalVariables.get_stage_from_string(stage), turret_number)
	GlobalVariables.player_money += refund
	
func hide_turret_cancel_button_and_show_turret_menu():
	$turret_menu.show()
	$buy_turret_cancel.hide()


func _on_unit_mouse_entered():
	$root_label.show()
	$root_label.text = tr("Train units menu")


func _on_unit_mouse_exited():
	$root_label.text = ""


func _on_back_mouse_entered():
	$units_menu/Label.show()
	$units_menu/Label.text = tr("Return to previous menu")


func _on_add_turret_spot_pressed():
	if GlobalVariables.player_money >= get_node("/root/main_game/player_base").get_price_of_new_turret_slot():
		GlobalVariables.player_money -= get_node("/root/main_game/player_base").get_price_of_new_turret_slot()
	elif get_node("/root/main_game/player_base").get_price_of_new_turret_slot() == INF:
		$root_label.show()
		$root_label.text = tr("Already at Max turret spots")
		return
	else:
		$root_label.show()
		$root_label.text = tr("Not enough money to add a new turret spot")
		return
	var player_base = get_node("/root/main_game/player_base").add_turret_spot()
	pass # Replace with function body.


func _on_turret_1_mouse_entered():
	$root_label.show()
	$root_label.text = tr("${price} - {name}").format({"price": GlobalVariables.get_turret_price(GlobalVariables.current_stage, 1),
													"name": GlobalVariables.get_turret_name(GlobalVariables.current_stage, 1)})


func _on_back_mouse_entered_from_turret():
	$root_label.show()
	$root_label.text = tr("Return to previous menu")


func _on_back_mouse_exited_from_turret():
	$root_label.hide()
	$root_label.text = ""


func _on_turret_mouse_entered():
	$root_label.show()
	$root_label.text = tr("Build turrets menu")


func _on_turret_2_mouse_entered():
	$root_label.show()
	$root_label.text = tr("${price} - {name}").format({"price": GlobalVariables.get_turret_price(GlobalVariables.current_stage, 2),
													"name": GlobalVariables.get_turret_name(GlobalVariables.current_stage, 2)})


func _on_add_turret_spot_mouse_entered():
	$root_label.show()
	if get_node("/root/main_game/player_base").get_price_of_new_turret_slot() == INF:
		$root_label.text = tr("Cannot add any more turret spots")
	else:
		$root_label.text = tr("${price} - Add a turret spot").format({"price" : get_node("/root/main_game/player_base").get_price_of_new_turret_slot()})


func _on_sell_turret_pressed():
	var sprite_follow_mouse : Sprite2D = load("res://UI/sprite_follow_player_mouse.tscn").instantiate()
	sprite_follow_mouse.texture = load("res://age of war sprites/ui/sell.png")
	sprite_follow_mouse.self_modulate = Color(1,1,1, 0.5)
	get_node("/root/main_game").add_child(sprite_follow_mouse)
	get_node("/root/main_game/player_base").activate_turret_sell_buttons()
	$default_menu/root_hbox_container.hide()
	$sell_turret_cancel.show()


func _on_turret_2_pressed():
	if GlobalVariables.player_money >= GlobalVariables.get_turret_price(GlobalVariables.current_stage, 2):
		GlobalVariables.player_money -= GlobalVariables.get_turret_price(GlobalVariables.current_stage, 2)
	else:
		$root_label.show()
		$root_label.text = tr("Not enough money!")
		return
	
	# allow the player to choose where the want to spawn the turret
	# spawn the sprite_follow_mouse object
	var sprite_follow_mouse : Sprite2D = load("res://UI/sprite_follow_player_mouse.tscn").instantiate()
	sprite_follow_mouse.texture = load("res://age of war sprites/bases/" + GlobalVariables.get_current_age_as_string() + "/turret_2/" + GlobalVariables.get_current_age_as_string() + "_turret_2_attack0001.png")
	sprite_follow_mouse.self_modulate = Color(1,1,1, 0.5)
	sprite_follow_mouse.turret_name = GlobalVariables.get_current_age_as_string() + "_turret_2"
	get_node("/root/main_game").add_child(sprite_follow_mouse)
	
	# change context to cancel button
	$turret_menu.hide()
	$buy_turret_cancel.show()
	
	get_node("/root/main_game/player_base").activate_turret_buy_buttons()


func _on_sell_turret_mouse_entered():
	$root_label.show()
	$root_label.text = tr("Sell a turret")


func _on_advance_mouse_entered():
	$root_label.show()
	if GlobalVariables.get_exp_to_next_age() == INF:
		$root_label.text = tr("Already at max age!")
	else:
		$root_label.text = tr("{exp} Xp - Evolve to next age").format({"exp": GlobalVariables.get_exp_to_next_age()})


func _on_cancel_sell_turret_pressed():
	get_node("/root/main_game/sprite_follow_player_mouse").queue_free()
	$default_menu/root_hbox_container.show()
	$sell_turret_cancel.hide()
	get_node("/root/main_game/player_base").deactivate_buttons()


func _on_turret_3_mouse_entered():
	$root_label.show()
	$root_label.text = tr("${price} - {name}").format({"price": GlobalVariables.get_turret_price(GlobalVariables.current_stage, 3),
													"name": GlobalVariables.get_turret_name(GlobalVariables.current_stage, 3)})


func _on_turret_3_pressed():
	if GlobalVariables.player_money >= GlobalVariables.get_turret_price(GlobalVariables.current_stage, 3):
		GlobalVariables.player_money -= GlobalVariables.get_turret_price(GlobalVariables.current_stage, 3)
	else:
		$root_label.show()
		$root_label.text = tr("Not enough money!")
		return
	
	# allow the player to choose where the want to spawn the turret
	# spawn the sprite_follow_mouse object
	var sprite_follow_mouse : Sprite2D = load("res://UI/sprite_follow_player_mouse.tscn").instantiate()
	sprite_follow_mouse.texture = load("res://age of war sprites/bases/" + GlobalVariables.get_current_age_as_string() + "/turret_3/" + GlobalVariables.get_current_age_as_string() + "_turret_3_attack0001.png")
	sprite_follow_mouse.self_modulate = Color(1,1,1, 0.5)
	sprite_follow_mouse.turret_name = GlobalVariables.get_current_age_as_string() + "_turret_3"
	get_node("/root/main_game").add_child(sprite_follow_mouse)
	
	# change context to cancel button
	$turret_menu.hide()
	$buy_turret_cancel.show()
	
	get_node("/root/main_game/player_base").activate_turret_buy_buttons()


func _on_special_pressed():
	if GlobalVariables.player_money >= 150000 and queue.size() < 5:
		GlobalVariables.player_money -= 150000
		var stage = GlobalVariables.get_current_age_as_string()
		add_to_queue("super_soldier", 10.0, stage)
	else:
		$units_menu/Label.show()
		$units_menu/Label.text = tr("Not enough money!")


func _on_special_mouse_entered():
	if GlobalVariables.current_stage != GlobalVariables.stage.future:
		return
	$units_menu/Label.show()
	$units_menu/Label.text = tr("${price} - {unit}").format({"price" : 150000,
														"unit" : tr("super soldier")})


func _on_special_mouse_exited():
	$units_menu/Label.hide()
	$units_menu/Label.text = ""
