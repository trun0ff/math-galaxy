extends RefCounted
## Small antialiased thumbnails avoid sparse-sampling stripes when blurring art.
static var cache: Dictionary = {}

static func blurred_thumbnail(texture: Texture2D) -> Texture2D:
	var key := texture.resource_path
	if cache.has(key): return cache[key]
	var image := texture.get_image()
	# Average down in cheap 2x steps; a huge Lanczos reduction stalls old GPUs/CPUs.
	while image.get_width() > 128 and image.get_height() > 2:
		image.shrink_x2()
	image.resize(64, maxi(1, int(round(64.0 * image.get_height() / image.get_width()))), Image.INTERPOLATE_BILINEAR)
	var thumbnail := ImageTexture.create_from_image(image)
	cache[key] = thumbnail
	return thumbnail
