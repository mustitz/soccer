from PIL import Image, ImageDraw

# Constants
SPRITE_WIDTH = 64
SPRITE_HEIGHT = SPRITE_WIDTH + SPRITE_WIDTH // 4
OUTLINE_THICKNESS = 1
RECT_SCALE_X = 0.5
RECT_SCALE_Y = 0.666
SLEEVE_WIDTH = int(0.15 * SPRITE_WIDTH)
SLEEVE_DELTA = int(0.1 * SPRITE_WIDTH)
NECK_DEPTH = int(0.05 * SPRITE_HEIGHT)
NECK_WIDTH = int(0.3 * SPRITE_WIDTH)
STRIPE_WIDTH = int (0.09 * SPRITE_WIDTH)
COLORS = [
    (255, 0, 0, 255),    # RED
    (0, 0, 255, 255),    # BLUE
    (0, 255, 0, 255),    # GREEN
    (255, 255, 0, 255),  # YELLOW
    (255, 0, 255, 255),  # MAGENTA
    (0, 255, 255, 255),  # CYAN
]
FILL_COLOR = (190, 0, 190, 255)
OUTLINE_COLOR = (0, 0, 0, 255)

def line(sprite, x1, y1, x2, y2):
    sprite.line([x1, y1, x2, y2], fill=OUTLINE_COLOR, width=OUTLINE_THICKNESS)

def create_tshirt_texture(color1, color2):
    img = Image.new('RGBA', (SPRITE_WIDTH, SPRITE_HEIGHT), (0, 0, 0, 0))
    sprite = ImageDraw.Draw(img)

    rect_width = int(SPRITE_WIDTH * RECT_SCALE_X)
    rect_height = int(SPRITE_HEIGHT * RECT_SCALE_Y)

    left = (SPRITE_WIDTH - rect_width) // 2
    top = (SPRITE_HEIGHT - rect_height) // 2
    right = left + rect_width
    bottom = top + rect_height

    # Top line with neck opening
    cx = (left + right) // 2
    neck_x1 = cx - NECK_WIDTH // 2
    neck_x2 = cx + NECK_WIDTH // 2

    line(sprite, left, top, neck_x1, top)
    line(sprite, neck_x2, top, right, top)

    # Triangular neckline
    neck_y = top + NECK_DEPTH
    line(sprite, neck_x1, top, cx, neck_y)
    line(sprite, cx, neck_y, neck_x2, top)
    line(sprite, right, bottom, right, top + 2 * SLEEVE_WIDTH)
    line(sprite, right, bottom, left, bottom)
    line(sprite, left, bottom, left, top + 2 * SLEEVE_WIDTH)

    # Left sleeve
    x, y, dx, dy = left, top, -SLEEVE_WIDTH - SLEEVE_DELTA, SLEEVE_WIDTH + SLEEVE_DELTA
    line(sprite, x, y, x+dx, y+dy)
    x, y, dx, dy = x+dx, y+dy, SLEEVE_WIDTH, SLEEVE_WIDTH
    line(sprite, x, y, x+dx, y+dy)
    x, y, dx, dy = x+dx, y+dy, SLEEVE_DELTA, -SLEEVE_DELTA
    line(sprite, x, y, x+dx, y+dy)

    # Right sleeve
    x, y, dx, dy = right, top, SLEEVE_WIDTH + SLEEVE_DELTA, SLEEVE_WIDTH + SLEEVE_DELTA
    line(sprite, x, y, x+dx, y+dy)
    x, y, dx, dy = x+dx, y+dy, -SLEEVE_WIDTH, SLEEVE_WIDTH
    line(sprite, x, y, x+dx, y+dy)
    x, y, dx, dy = x+dx, y+dy, -SLEEVE_DELTA, -SLEEVE_DELTA
    line(sprite, x, y, x+dx, y+dy)

    center_x = (left + right) // 2
    center_y = (top + bottom) // 2
    ImageDraw.floodfill(img, (center_x, center_y), FILL_COLOR)

    colors = [color1, color2]
    for x in range(SPRITE_WIDTH):
        for y in range(SPRITE_HEIGHT):
            pixel = img.getpixel((x, y))
            if pixel == FILL_COLOR:
                index = (x // STRIPE_WIDTH) & 1
                img.putpixel((x, y), colors[index])

    return img

if __name__ == "__main__":
    # Create big grid image
    grid_width = len(COLORS) * SPRITE_WIDTH
    grid_height = len(COLORS) * SPRITE_HEIGHT
    big_img = Image.new('RGBA', (grid_width, grid_height), (0, 0, 0, 0))

    # Generate all color combinations
    for i in range(len(COLORS)):
        for j in range(len(COLORS)):
            tshirt_img = create_tshirt_texture(COLORS[i], COLORS[j])

            # Calculate position in grid
            x_pos = j * SPRITE_WIDTH
            y_pos = i * SPRITE_HEIGHT

            # Paste the T-shirt into the big image
            big_img.paste(tshirt_img, (x_pos, y_pos))

    big_img.save('tshirt_grid.png')
    print(f"Generated tshirt_grid.png ({grid_width}x{grid_height})")
