extends Control

var gradient_ref_img = Image.create(16, 16, false, Image.FORMAT_RGB8)
var template = FileAccess.get_file_as_string("res://svg_template.txt").trim_suffix("\n")


func _ready() -> void:
	%GradientPosPreview.texture = ImageTexture.create_from_image(gradient_ref_img)


func _process(_delta: float) -> void:
	# Update preview
	var tex = $Viewport/Gradient.texture
	tex.fill_from = Vector2(%FromPos/SpinBoxX.value / 15.0, %FromPos/SpinBoxY.value / 16.0)
	tex.fill_to = Vector2(%ToPos/SpinBoxX.value / 15.0, %ToPos/SpinBoxY.value / 16.0)
	tex.gradient.set_color(0, $SideBar/VBox/ColorA/ColorPickerButton.color)
	tex.gradient.set_color(1, $SideBar/VBox/ColorB/ColorPickerButton.color)
	
	# Update the gradient direction reference image
	gradient_ref_img.fill(Color.BLACK)
	gradient_ref_img.set_pixel(%FromPos/SpinBoxX.value, %FromPos/SpinBoxY.value, Color.RED)
	gradient_ref_img.set_pixel(%ToPos/SpinBoxX.value, %ToPos/SpinBoxY.value, Color.BLUE)
	%GradientPosPreview.texture.update(gradient_ref_img)


func load_image_from_clipboard() -> bool:
	if not DisplayServer.clipboard_has_image():
		$SideBar/PrintLabel.text = "Error: Image not found on clipboard."
		return false
	var img = DisplayServer.clipboard_get_image()
	if not img.get_size() == Vector2i(16, 16):
		$SideBar/PrintLabel.text = "Error: The clipboard image is not 16x16."
		return false
	$Viewport/Icon.texture = ImageTexture.create_from_image(img)
	$SideBar/PrintLabel.text = "Loaded mask from clipboard."
	return true


func _on_load_mask_pressed() -> void:
	load_image_from_clipboard()


func _on_save_svg_pressed() -> void:
	# Load SVG template
	var svg = template
	
	# Create gradient
	var gpos_start = Vector2i(%FromPos/SpinBoxX.value, %FromPos/SpinBoxY.value)
	var gpos_end = Vector2i(%ToPos/SpinBoxX.value, %ToPos/SpinBoxY.value)
	var gpos_formatting = [gpos_start.x, gpos_start.y, gpos_end.x, gpos_end.y]
	var gpos_text = 'x1="%s" y1="%s" x2="%s" y2="%s"' % gpos_formatting
	var gradient_text = '<linearGradient id="bgGradient" ' + gpos_text
	gradient_text += ' gradientUnits="userSpaceOnUse"><stop offset="0%" stop-color="#'
	gradient_text += %ColorA/ColorPickerButton.color.to_html().substr(0, 6)
	gradient_text += '"/><stop offset="100%" stop-color="#'
	gradient_text += %ColorB/ColorPickerButton.color.to_html().substr(0, 6)
	gradient_text += '"/></linearGradient>'
	svg = svg.replace("TEMPLATE:GRADIENT", gradient_text)
	
	# Create mask
	var rects_text = ""
	var img: Image = $Viewport/Icon.texture.get_image()
	for x in img.get_width():
		for y in img.get_height():
			var col = img.get_pixel(x, y)
			if not col == Color.BLACK and not col.a == 0.0:
				var rect = '<rect x="%s"  y="%s"  width="1" height="1" fill="white"/>' % [x, y]
				rects_text += "\n      " + rect
	svg = svg.replace("TEMPLATE:CUTOUT", rects_text)
	
	# Copy the SVG text
	DisplayServer.clipboard_set(svg)
	$SideBar/PrintLabel.text = "Copied SVG text."
