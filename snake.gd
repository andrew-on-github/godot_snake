extends Node2D

const CELL := 30
const COLS := 20
const ROWS := 20
const TOP := 40
const STEP_TIME := 0.14

var snake: Array[Vector2i] = [
	Vector2i(10, 10),
	Vector2i(9, 10),
	Vector2i(8, 10)
]

var direction := Vector2i.RIGHT
var next_direction := Vector2i.RIGHT
var food := Vector2i.ZERO
var elapsed := 0.0
var game_over := false
var won := false


func _ready() -> void:
	spawn_food()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_R:
			get_tree().reload_current_scene()
			return

	if game_over:
		return

	var wanted := Vector2i.ZERO

	if event.is_action_pressed("ui_up"):
		wanted = Vector2i.UP
	elif event.is_action_pressed("ui_down"):
		wanted = Vector2i.DOWN
	elif event.is_action_pressed("ui_left"):
		wanted = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"):
		wanted = Vector2i.RIGHT

	# Prevent reversing into the snake's body.
	if wanted != Vector2i.ZERO and wanted != -direction:
		next_direction = wanted


func _process(delta: float) -> void:
	if game_over:
		return

	elapsed += delta

	if elapsed >= STEP_TIME:
		elapsed = 0.0
		move_snake()


func move_snake() -> void:
	direction = next_direction
	var head: Vector2i = snake[0] + direction

	# Check wall collisions.
	if head.x < 0 or head.x >= COLS or head.y < 0 or head.y >= ROWS:
		end_game()
		return

	var eating := head == food
	var body_to_check := snake.size()

	# Moving into the current tail cell is allowed if it moves away.
	if not eating:
		body_to_check -= 1

	for i in range(body_to_check):
		if snake[i] == head:
			end_game()
			return

	snake.push_front(head)

	if eating:
		spawn_food()
	else:
		snake.pop_back()

	queue_redraw()


func spawn_food() -> void:
	var empty_cells: Array[Vector2i] = []

	for y in range(ROWS):
		for x in range(COLS):
			var cell := Vector2i(x, y)

			if not snake.has(cell):
				empty_cells.append(cell)

	# Filling the entire board wins the game.
	if empty_cells.is_empty():
		won = true
		end_game()
		return

	var index := randi_range(0, empty_cells.size() - 1)
	food = empty_cells[index]


func end_game() -> void:
	game_over = true
	queue_redraw()


func _draw() -> void:
	# Background for the score bar.
	draw_rect(
		Rect2(0, 0, COLS * CELL, TOP),
		Color("#101820")
	)

	# Playing field.
	draw_rect(
		Rect2(0, TOP, COLS * CELL, ROWS * CELL),
		Color("#18222e")
	)

	# Food.
	if not won:
		draw_cell(food, Color("#ff6868"))

	# Snake.
	for i in range(snake.size()):
		var segment_color := Color("#45ad65")

		if i == 0:
			segment_color = Color("#8bea70")

		if game_over:
			segment_color = Color("#89939e")

		draw_cell(snake[i], segment_color)

	# Declare status outside the loop and before the condition.
	var score := snake.size() - 3
	var status := "Score: %d | Arrows: move | R: restart" % score

	if game_over:
		var result := "You win!" if won else "Game over!"
		status = "%s Score: %d | R: restart" % [result, score]

	draw_string(
		ThemeDB.fallback_font,
		Vector2(10, 27),
		status,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color.WHITE
	)


func draw_cell(cell: Vector2i, color: Color) -> void:
	var cell_position := Vector2(
		cell.x * CELL + 1,
		cell.y * CELL + TOP + 1
	)

	draw_rect(
		Rect2(cell_position, Vector2(CELL - 2, CELL - 2)),
		color
	)
