extends Node
class_name Map_Decider

# 这个脚本负责“解析地图文本 → 遍历字符 → 计算像素坐标 → 通过 spawning 信号发出去”。
# 关键改动（相对最初版）：
# 1) 新增异步生成（_emit_chunk_async + *_async 系列），按预算分帧发射，避免一帧实例化过多导致卡顿。
# 2) 横向拼块无缝：根据 strip_left/strip_right 计算实际“可见列数”，推进 off_set_x 不再固定 +CHUNK_W，彻底消除块与块之间的空列。
# 3) 锁竖向锚点时，锁到“最后一个横向块的起始 x”，保证下一段竖向从正确的 x 开始（配合 Master 的 off_set_x = vertical_origin_x）。

var file_path = "res://Data/easy_map.txt"

class Grid:
	var cells: Array
	
	func _init(chunk : Array):
		cells = []
		for line in chunk:
			cells.append(line.split(""))
			
	func get_cell(row:int, col:int) -> String:
		return cells[row][col]

	func set_cell(row:int, col: int, value: String):
		cells[row][col] = value
	
	func print_grid():
		for row in cells:
			print("".join(row))
			
	# 遍历时把 col 传成 (col-1)，这样文本最左边的“|”列就是 -1，对齐 x=0（配合 off_set_x=16）
	func for_each_cell(callback : Callable):
		for row in range(cells.size()):
			for col in range(cells[row].size()):
				callback.call(row, col - 1, cells[row][col])
				
	func for_each_inner_cell(callback:Callable):
		for row in range(cells.size()):
			for col in range(1, cells[row].size() - 1):
				callback.call(row, col - 1, cells[row][col])

# 读取并按“=”分段，这段和你原来一样（有点脆弱但够用）
func read_and_split_file(in_file_path: String) -> Dictionary:
	var file = FileAccess.open(in_file_path, FileAccess.READ)
	var result := {}
	var current_key := ""
	var current_array := []
	var key_index = 0
	if file:
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if "=" in line:
				if not current_key.is_empty():
					result[current_key] = current_array
				current_key = str(key_index)
				key_index += 1
				result[current_key] = current_array
				var parts = line.split("=", true, 1)
				current_key = parts[0]
				current_array = []
				if parts.size() > 1 and !parts[1].is_empty():
					current_array.append(parts[1])
			else:
				current_array.append(line)
		if not current_key.is_empty():
			result[current_key] = current_array
		file.close()
	return result
	
func get_random_chunk(in_data: Dictionary):
	if in_data.is_empty():
		return null
	# 注意：这个随机从 keys 的索引范围里取，并不保证键名 >=5。
	# 你段内随机块用的是 make_one_chunk(_async)，那边已经做了过滤，这个就保持兼容了。
	var keys = in_data.keys()
	var random_number_range = randi_range(5, keys.size() - 1)
	var random_key = keys[random_number_range]
	return in_data[random_key]
	
func get_specific_chunk(in_data : Dictionary, key : String):
	if in_data.is_empty():
		return null
	return in_data[key]
	
func parse_chunk_to_grid(chunk:Array) -> Array:
	var grid = []
	for line in chunk:
		grid.append(line.split(""))
	return grid

signal spawning(value_of_cell, pos)

var data : Dictionary

func _ready():
	randomize() # 保证每次运行随机不同；如果你希望“可复现”，可以改成独立 RNG + set_seed
	data = read_and_split_file(file_path)

# ===== 全局尺寸/偏移 =====
var off_set_y : int = 0

const TILE : int = 16
const CHUNK_W : int = 17 * TILE  # 一个块 17 列
const CHUNK_H : int = 5 * TILE   # 一个块 5 行

var off_set_x : int = 16  # 和 (col-1) 机制配合，让左墙刚好对齐 x=0

# 竖向锚点：后续所有“竖向发射”的 X 基于它（Master 会在横向后锁到正确的起点）
var vertical_origin_x: int = 0

# 记录“最后一个横向块的起始 x”，锁竖向锚点用
var _last_right_chunk_start_x: int = 0

func set_vertical_origin_x(px: int) -> void:
	vertical_origin_x = px

# 关键点：锁竖向 X 到“最后一个横向块的起始 x”
func lock_vertical_to_last_right_chunk() -> void:
	vertical_origin_x = _last_right_chunk_start_x

# ===== 竖向（同步版，保留） =====
func make_specific_chunk(in_number: int ):
	var first = get_specific_chunk(data, str(in_number))	
	var grid = Grid.new(first)
	grid.for_each_cell(func(row, col, value):
		var cell_pos : Vector2i = Vector2i(vertical_origin_x + col * TILE, row * TILE + off_set_y)
		spawning.emit(value, cell_pos))

func make_starting_chunk():
	var first = get_specific_chunk(data, "1")
	var grid = Grid.new(first)
	grid.for_each_cell(func(row, col, value):
		var cell_pos : Vector2i = Vector2i(vertical_origin_x + col * TILE, row * TILE + off_set_y)
		spawning.emit(value, cell_pos))

func make_ending_chunk():
	var first = get_specific_chunk(data, "2")
	var grid = Grid.new(first)
	grid.for_each_cell(func(row, col, value):
		var cell_pos : Vector2i = Vector2i(vertical_origin_x + col * TILE, row * TILE + off_set_y)
		spawning.emit(value, cell_pos))

func make_blank_chunk():
	var first = get_specific_chunk(data, "0")
	var grid = Grid.new(first)
	grid.for_each_cell(func(row, col, value):
		var cell_pos : Vector2i = Vector2i(vertical_origin_x + col * TILE, row * TILE + off_set_y)
		spawning.emit(value, cell_pos))

func make_one_chunk():
	# 随机候选：键名是数字且 >=5；排除 5 这个键
	if data.is_empty():
		return
	var candidates: Array[String] = []
	for k in data.keys():
		var n: int = int(k)
		if n >= 5 and n != 5:
			candidates.append(String(k))
	var chunk: Array = []
	if not candidates.is_empty():
		var pick_key: String = candidates[randi() % candidates.size()]
		if data.has(pick_key):
			var picked: Variant = data[pick_key]
			if picked is Array:
				chunk = picked as Array
	else:
		var fallback: Variant = get_specific_chunk(data, "0")
		if fallback is Array:
			chunk = fallback as Array
	var grid = Grid.new(chunk)
	grid.for_each_cell(func(row: int, col: int, value: String):
		var cell_pos: Vector2i = Vector2i(vertical_origin_x + col * TILE, row * TILE + off_set_y)
		spawning.emit(value, cell_pos))

# ===== 横向（同步版，无缝拼接关键逻辑） =====
func _emit_chunk(chunk: Array, origin_x: int, origin_y: int, strip_left: bool=false, strip_right: bool=false) -> void:
	if chunk == null:
		return
	var grid := Grid.new(chunk)
	var width_cells := 0
	if grid.cells.size() > 0:
		width_cells = grid.cells[0].size()
	grid.for_each_cell(func(row: int, col: int, value: String):
		# 根据 strip_left/strip_right 决定是否丢掉左右边界“|”
		if value == "|":
			var is_left_border := (col == -1)
			var is_right_border := (width_cells > 0 and col == width_cells - 2)
			if (strip_left and is_left_border) or (strip_right and is_right_border):
				return
		var cell_pos: Vector2i = Vector2i(origin_x + col * TILE, origin_y + row * TILE)
		spawning.emit(value, cell_pos))

# side 语义：
# "left"  保留左墙，去右墙
# "mid"   去左右墙（横向中间用）
# "right" 去左墙，保留右墙（横向收尾用）
func make_specific_chunk_right(in_number: int, side: String="mid") -> void:
	var strip_left: bool = (side != "left")
	var strip_right: bool = (side != "right")
	var chunk = get_specific_chunk(data, str(in_number))

	# 这里是无缝的关键：算出“本块实际可见的列范围”（col 从 -1..15）
	var min_col: int = 0  if strip_left  else -1  # 去左墙的话，最左可见从 0 开始；否则保留到 -1
	var max_col: int = 14 if strip_right else 15  # 去右墙的话，最右可见到 14；否则保留到 15
	var visible_cols: int = max_col - min_col + 1 # 可见列数

	# 让“本块最左可见列”的世界 x 刚好对齐 off_set_x
	# 注意，我们发射时还是以 (col-1) 的坐标算，所以需要减掉 min_col*TILE 做个偏移。
	var origin_x_for_emit: int = off_set_x - (min_col * TILE)

	# 记录一下“这块的起点 x”，横向结束后“锁竖向锚点”要用它
	_last_right_chunk_start_x = off_set_x

	_emit_chunk(chunk, origin_x_for_emit, off_set_y, strip_left, strip_right)

	# 按实际可见列宽推进，不再固定 +CHUNK_W，这样块与块之间就不会留出被剔掉的边墙空列
	off_set_x += visible_cols * TILE

func make_random_chunk_right(side: String="mid") -> void:
	var strip_left: bool = (side != "left")
	var strip_right: bool = (side != "right")
	var chunk = get_random_chunk(data)

	var min_col: int = 0  if strip_left  else -1
	var max_col: int = 14 if strip_right else 15
	var visible_cols: int = max_col - min_col + 1
	var origin_x_for_emit: int = off_set_x - (min_col * TILE)

	_last_right_chunk_start_x = off_set_x
	_emit_chunk(chunk, origin_x_for_emit, off_set_y, strip_left, strip_right)
	off_set_x += visible_cols * TILE

func make_blank_chunk_right(side: String="mid") -> void:
	var strip_left: bool = (side != "left")
	var strip_right: bool = (side != "right")
	var chunk = get_specific_chunk(data, "0")

	var min_col: int = 0  if strip_left  else -1
	var max_col: int = 14 if strip_right else 15
	var visible_cols: int = max_col - min_col + 1
	var origin_x_for_emit: int = off_set_x - (min_col * TILE)

	_last_right_chunk_start_x = off_set_x
	_emit_chunk(chunk, origin_x_for_emit, off_set_y, strip_left, strip_right)
	off_set_x += visible_cols * TILE

func new_row_right() -> void:
	off_set_x = 16
	off_set_y += CHUNK_H

# ===== 异步生成（分帧预算） =====
var SPAWN_BUDGET := 400
var _spawned_in_frame := 0

func _emit_cell_async(value: String, px: int, py: int) -> void:
	# 每发射一个 cell 就计数；到预算就让一帧，避免一帧太多实例化卡顿
	spawning.emit(value, Vector2i(px, py))
	_spawned_in_frame += 1
	if _spawned_in_frame >= SPAWN_BUDGET:
		await get_tree().process_frame
		_spawned_in_frame = 0

func _emit_chunk_async(chunk: Array, origin_x: int, origin_y: int, strip_left: bool=false, strip_right: bool=false) -> void:
	if chunk == null:
		return
	var grid := Grid.new(chunk)
	var width_cells := 0
	if grid.cells.size() > 0:
		width_cells = grid.cells[0].size()
	for row in range(grid.cells.size()):
		for col0 in range(grid.cells[row].size()):
			var col := col0 - 1
			var value = grid.cells[row][col0]
			if value == "|":
				var is_left_border := (col == -1)
				var is_right_border := (width_cells > 0 and col == width_cells - 2)
				if (strip_left and is_left_border) or (strip_right and is_right_border):
					continue
			await _emit_cell_async(value, origin_x + col * TILE, origin_y + row * TILE)

# ===== 竖向/横向异步版本（Master 用这些） =====
func make_starting_chunk_async() -> void:
	var first = get_specific_chunk(data, "1")
	await _emit_chunk_async(first, vertical_origin_x, off_set_y)

func make_blank_chunk_async() -> void:
	var first = get_specific_chunk(data, "0")
	await _emit_chunk_async(first, vertical_origin_x, off_set_y)

func make_specific_chunk_async(in_number: int) -> void:
	var first = get_specific_chunk(data, str(in_number))
	await _emit_chunk_async(first, vertical_origin_x, off_set_y)

func make_one_chunk_async() -> void:
	if data.is_empty(): return
	var candidates: Array[String] = []
	for k in data.keys():
		if k.is_valid_int():
			var n := int(k)
			if n >= 5 and n != 5:
				candidates.append(k)
	var chunk: Array = []
	if not candidates.is_empty():
		var pick_key := candidates[randi() % candidates.size()]
		var picked = data.get(pick_key)
		if picked is Array:
			chunk = picked
	else:
		var fallback = get_specific_chunk(data, "0")
		if fallback is Array:
			chunk = fallback
	await _emit_chunk_async(chunk, vertical_origin_x, off_set_y)

func make_specific_chunk_right_async(in_number: int, side: String="mid") -> void:
	var strip_left: bool = (side != "left")
	var strip_right: bool = (side != "right")
	var chunk = get_specific_chunk(data, str(in_number))

	var min_col: int = 0  if strip_left  else -1
	var max_col: int = 14 if strip_right else 15
	var visible_cols: int = max_col - min_col + 1
	var origin_x_for_emit: int = off_set_x - (min_col * TILE)

	_last_right_chunk_start_x = off_set_x
	await _emit_chunk_async(chunk, origin_x_for_emit, off_set_y, strip_left, strip_right)
	off_set_x += visible_cols * TILE
