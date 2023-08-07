extends Node2D

func _process(_delta):
	var scroll_direction = $Camera2D/Control.get_scroll_direction()
	
	if scroll_direction != Vector2.ZERO:
		$Camera2D.position += scroll_direction

func update_mouse_cursor():
	var zoom = 1
	
	var a = OS.get_window_safe_area()
	var b = get_viewport_rect()
	zoom = min(a.size.x / b.size.x, a.size.y / b.size.y)
	
	var image: Image = Image.new()
	image.load("res://assets/graphics/cursor.png")
	image.resize(image.get_width() * zoom, image.get_height() * zoom, Image.INTERPOLATE_NEAREST)
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	Input.set_custom_mouse_cursor(texture)

func on_window_resize():
	update_mouse_cursor()

func _ready():
	get_tree().get_root().connect("size_changed", self, "on_window_resize")
	on_window_resize()
