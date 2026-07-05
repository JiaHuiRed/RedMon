extends Node
# RedMon – 脚本引擎
# 自动加载，执行事件脚本。场景通过信号与引擎交互。
# 脚本格式: [{"type": "dialog", "key": "section.key"}, {"type": "end"}, ...]

signal dialog_requested(text: String)
signal battle_requested(trainer_data: Dictionary)
signal wild_battle_requested(species: String, level: int, return_scene: String)
signal warp_requested(target_scene: String, data: Dictionary)
signal shop_requested()
signal heal_requested()
signal script_ended()

var _script: Array = []
var _idx: int = 0
var _running: bool = false
var _waiting: bool = false

func run(script_data: Array) -> void:
	_script = script_data.duplicate()
	_idx = 0
	_running = true
	_waiting = false
	_advance()

func advance() -> void:
	if _running and _waiting:
		_waiting = false
		_advance()

func is_running() -> bool:
	return _running

func stop() -> void:
	_running = false
	_waiting = false
	_script = []

func _advance() -> void:
	while _running and _idx < _script.size():
		var cmd = _script[_idx]
		_idx += 1
		match _exec(cmd):
			"wait":  _waiting = true; return
			"done":  _running = false; script_ended.emit(); return
			"stop":  _running = false; _waiting = false; return

func _exec(cmd: Dictionary) -> String:
	match cmd.get("type", ""):
		"dialog":
			var text = cmd.get("text", "")
			if text.is_empty():
				var key = cmd.get("key", "")
				var parts = key.split(".")
				if parts.size() >= 2:
					text = MonDB.dlg(parts[0], parts[1])
			dialog_requested.emit(text)
			return "wait"

		"end":
			return "done"

		"battle":
			var trainer_id = cmd.get("trainer_id", "")
			var return_scene = cmd.get("return_scene", "")
			var data = {"return_scene": return_scene, "from_scene": return_scene}
			# 尝试从 npcs.json 读取训练师数据
			var npc_def = MonDB.npcs.get(trainer_id, {})
			var tr = npc_def.get("trainer", {})
			if not tr.is_empty():
				battle_requested.emit({
					"id": trainer_id,
					"name": npc_def.get("name", ""),
					"team": tr.get("team", []),
					"reward": tr.get("reward", 0),
					"dialog_before": tr.get("dialog_before", ""),
					"dialog_win": tr.get("dialog_win", ""),
				})
			else:
				data["trainer"] = {"id": trainer_id, "name": trainer_id}
				battle_requested.emit(data)
			return "wait"

		"wild_battle":
			wild_battle_requested.emit(
				cmd.get("species", "坤仔"),
				cmd.get("level", 5),
				cmd.get("return_scene", "")
			)
			return "wait"

		"warp":
			warp_requested.emit(
				cmd.get("target", ""),
				cmd.get("data", {})
			)
			return "stop"

		"set_flag":
			var key = cmd.get("flag", "")
			var val = cmd.get("value", true)
			if key in GameState:
				GameState.set(key, val)
			elif key.begins_with("flag_"):
				GameState.flags[key] = val
			GameState.save_game()
			return "continue"

		"give_item":
			var item = cmd.get("item", "")
			var count = cmd.get("count", 1)
			GameState.items[item] = GameState.items.get(item, 0) + count
			return "continue"

		"heal":
			for mon in GameState.player_team:
				mon["current_hp"] = mon["max_hp"]
			heal_requested.emit()
			return "continue"

		"shop":
			shop_requested.emit()
			return "wait"

		_:
			push_warning("[ScriptEngine] 未知命令: ", cmd.get("type", ""))
			return "continue"
