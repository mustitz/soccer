from PIL import Image, ImageDraw

SPRITE_WIDTH = 256
SPRITE_HEIGHT = 256
OUTLINE_THICKNESS = 10
HEAD_RADIUS = 35
BODY_WIDTH = 80
FILL_COLOR = (0, 0, 0, 0)
OUTLINE_COLOR = (0, 0, 0, 255)

def draw_user():
    img = Image.new('RGBA', (SPRITE_WIDTH, SPRITE_HEIGHT), (0, 0, 0, 0))
    sprite = ImageDraw.Draw(img)

    # Circle
    margin_x = int(0.05 * SPRITE_WIDTH)
    margin_y = int(0.05 * SPRITE_HEIGHT)

    x1 = margin_x
    y1 = margin_y
    x2 = SPRITE_WIDTH - margin_x
    y2 = SPRITE_HEIGHT - margin_y

    sprite.ellipse([x1, y1, x2, y2], fill=FILL_COLOR, outline=OUTLINE_COLOR, width=OUTLINE_THICKNESS)

    # Head inside
    head_x = SPRITE_WIDTH // 2
    head_y = int(SPRITE_HEIGHT * 0.33)

    x1 = head_x - HEAD_RADIUS
    y1 = head_y - HEAD_RADIUS
    x2 = head_x + HEAD_RADIUS
    y2 = head_y + HEAD_RADIUS

    sprite.ellipse([x1, y1, x2, y2], fill=OUTLINE_COLOR)

    # Body (trapezoid)
    y1 = head_y + HEAD_RADIUS + 10
    y2 = SPRITE_HEIGHT - margin_y - 27

    w1 = BODY_WIDTH // 2
    w2 = BODY_WIDTH

    points = [
        (SPRITE_WIDTH // 2 - w1 // 2, y1),
        (SPRITE_WIDTH // 2 + w1 // 2, y1),
        (SPRITE_WIDTH // 2 + w2 // 2, y2),
        (SPRITE_WIDTH // 2 - w2 // 2, y2)
    ]

    sprite.polygon(points, fill=OUTLINE_COLOR)

    # Resize to 128x128
    img = img.resize((128, 128), Image.LANCZOS)

    return img

if __name__ == "__main__":
    img = draw_user()
    img.save('user.png')
    print("Generated user.png")
