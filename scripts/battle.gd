extends Control

signal battle_ended

@onready var player_hp = $PlayerHP
@onready var enemy_hp = $EnemyHP
@onready var log = $Log
@onready var actions = $Actions

var player_health = 100
var enemy_health = 100
var player_turn = true

func start():
	player_health = 100
	enemy_health = 100
	player_turn = true
	log.text = "野生的 绿肥虫 出现了！\n该怎么做？"
	actions.visible = true

func _on_attack_pressed():
	if not player_turn:
		return
	var dmg = randi_range(10, 20)
	enemy_health = max(0, enemy_health - dmg)
	log.text = "你使用了 撞击！\n造成 %d 点伤害！" % dmg
	if enemy_health <= 0:
		log.text += "\n\n绿肥虫倒下了！\n获得 50 经验值！"
		actions.visible = false
		await get_tree().create_timer(2.0).timeout
		battle_ended.emit()
		return
	player_turn = false
	await get_tree().create_timer(1.0).timeout
	enemy_turn()

func enemy_turn():
	var dmg = randi_range(5, 15)
	player_health = max(0, player_health - dmg)
	log.text += "\n\n绿肥虫使用了 吐丝！\n造成 %d 点伤害！" % dmg
	if player_health <= 0:
		log.text += "\n\n你倒下了……"
		actions.visible = false
		await get_tree().create_timer(2.0).timeout
		battle_ended.emit()
		return
	player_turn = true

func _on_run_pressed():
	log.text = "你逃跑了！"
	actions.visible = false
	await get_tree().create_timer(1.5).timeout
	battle_ended.emit()
