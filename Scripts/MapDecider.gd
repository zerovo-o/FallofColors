extends Node
class_name Map_Decider

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
			
	# callback receives (row, col-1, value). Left border becomes col == -1.
	func for_each_cell(callback : Callable):
		for row in range(cells.size()):
			for col in range(cells[row].size()):
				callback.call(row, col - 1, cells[row][col])
				
	func for_each_inner_cell(callback:Callable):
		for row in range(cells.size()):
			for col in range(1, cells[row].size() - 1):
				callback.call(row, col - 1, cells[row][col])

func read_and_split_file(in_file_path: String) -> Dictionary:
	var file = FileAccess.open(in_file_path, FileAccess.READ)
	var result := {}
	var current_key := ""
	var current_array := []
	var key_index = 0
	if file:
		while not file.eof_reached(): #reads until the end of the file based off the cursor
			var line = file.get_line().strip_edges() #gets everything line by line
			
			if "=" in line: #this resets each array
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
	data = read_and_split_file(file_path)

# offsets
var off_set_y : int = 0

# horizontal helpers
const TILE : int = 16
const CHUNK_W : int = 17 * TILE
const CHUNK_H : int = 5 * TILE

var off_set_x : int = 16  # aligns with (col-1) so left border starts at x=0

# vertical anchor (added): x anchor for all vertical placements
var vertical_origin_x: int = 0

func set_vertical_origin_x(px: int) -> void:
	vertical_origin_x = px

# lock vertical anchor to the start x of the last right-placed chunk
func lock_vertical_to_last_right_chunk() -> void:
	vertical_origin_x = off_set_x - CHUNK_W


# ===== Vertical (unchanged API, but x now includes vertical_origin_x) =====
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
	# 竖向随机：只取编号 >= 5，且排除编号 5（第 6 个块）
	if data.is_empty():
		return

	var candidates: Array[String] = []
	for k in data.keys():
		var n: int = int(k)  # 键是字符串，转成数字判断
		if n >= 5 and n != 5:  # 这里排除 5；以后要排更多可用黑名单
			candidates.append(String(k))

	var chunk: Array = []  # 不能为 null，给个空数组占位
	if not candidates.is_empty():
		var pick_key: String = candidates[randi() % candidates.size()]
		if data.has(pick_key):
			var picked: Variant = data[pick_key]
			if picked is Array:
				chunk = picked as Array
	else:
		# 兜底：当候选为空时，用空白块（或你指定的其它安全块）
		var fallback: Variant = get_specific_chunk(data, "0")
		if fallback is Array:
			chunk = fallback as Array
		# 若 "0" 都不存在，chunk 保持为空数组，也不会崩

	var grid = Grid.new(chunk)
	grid.for_each_cell(func(row: int, col: int, value: String):
		var cell_pos: Vector2i = Vector2i(vertical_origin_x + col * TILE, row * TILE + off_set_y)
		spawning.emit(value, cell_pos))


# ===== Horizontal helpers (new) =====

# Emit a chunk at (origin_x, origin_y); optionally strip side walls only at border columns.
# for_each_cell passes col as (col-1):
# - left border col == -1
# - right border col == width_cells - 2 (when width_cells == 17)
func _emit_chunk(chunk: Array, origin_x: int, origin_y: int, strip_left: bool=false, strip_right: bool=false) -> void:
	if chunk == null:
		return
	var grid := Grid.new(chunk)
	var width_cells := 0
	if grid.cells.size() > 0:
		width_cells = grid.cells[0].size()
	grid.for_each_cell(func(row: int, col: int, value: String):
		if value == "|":
			var is_left_border := (col == -1)
			var is_right_border := (width_cells > 0 and col == width_cells - 2)
			if (strip_left and is_left_border) or (strip_right and is_right_border):
				return
		var cell_pos: Vector2i = Vector2i(origin_x + col * TILE, origin_y + row * TILE)
		spawning.emit(value, cell_pos))

# side: "left" (keep left, strip right), "mid" (strip both), "right" (strip left, keep right)
func make_specific_chunk_right(in_number: int, side: String="mid") -> void:
	var strip_left := false
	var strip_right := false
	match side:
		"left":
			strip_left = false; strip_right = true
		"mid":
			strip_left = true;  strip_right = true
		"right":
			strip_left = true;  strip_right = false
		_:
			strip_left = true;  strip_right = true
	var chunk = get_specific_chunk(data, str(in_number))
	_emit_chunk(chunk, off_set_x, off_set_y, strip_left, strip_right)
	off_set_x += CHUNK_W

func make_random_chunk_right(side: String="mid") -> void:
	var strip_left := (side != "left")
	var strip_right := (side != "right")
	var chunk = get_random_chunk(data)
	_emit_chunk(chunk, off_set_x, off_set_y, strip_left, strip_right)
	off_set_x += CHUNK_W

func make_blank_chunk_right(side: String="mid") -> void:
	var strip_left := (side != "left")
	var strip_right := (side != "right")
	var chunk = get_specific_chunk(data, "0")
	_emit_chunk(chunk, off_set_x, off_set_y, strip_left, strip_right)
	off_set_x += CHUNK_W

func new_row_right() -> void:
	off_set_x = 16
	off_set_y += CHUNK_H
