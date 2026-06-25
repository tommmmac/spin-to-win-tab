extends CanvasLayer

func _ready():
	# Vertical dividers
	_draw_line(Vector2(640, 0), Vector2(640, 1080))
	_draw_line(Vector2(1280, 0), Vector2(1280, 1080))
	# Horizontal divider
	_draw_line(Vector2(0, 540), Vector2(1920, 540))

func _draw_line(from: Vector2, to: Vector2):
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 4.0
	line.default_color = Color.WHITE  # change to whatever fits your UI
	add_child(line)
