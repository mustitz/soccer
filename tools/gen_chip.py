from PIL import Image, ImageDraw, ImageFont
import random

# Constants
SPRITE_WIDTH = 256
SPRITE_HEIGHT = 256
OUTLINE_THICKNESS = 5
MIN_PIN_LENGTH = 20
MAX_PIN_LENGTH = 50
PIN_RADIUS = 7
FILL_COLOR = (0, 0, 0, 0)
OUTLINE_COLOR = (0, 0, 0, 255)

PINS = ((20, -1), (40, -1), (60, -1), (20, 0), (40, 0), (60, +1), (40, +1))

def plot_pin(sprite, x, y, dx, dy, pin_length=None, pin_step=0):
    if pin_length is None:
        pin_length = random.randint(MIN_PIN_LENGTH, MAX_PIN_LENGTH)

    mid_x = x
    mid_y = y + dy * pin_length

    sprite.line([x, y, mid_x, mid_y], fill=OUTLINE_COLOR, width=OUTLINE_THICKNESS)

    if pin_step != 0:
        end_x = mid_x + pin_step * MIN_PIN_LENGTH
        end_y = mid_y

        sprite.line([mid_x, mid_y, end_x, end_y], fill=OUTLINE_COLOR, width=OUTLINE_THICKNESS)
    else:
        end_x = mid_x
        end_y = mid_y

    x1 = end_x - PIN_RADIUS
    y1 = end_y - PIN_RADIUS
    x2 = end_x + PIN_RADIUS
    y2 = end_y + PIN_RADIUS

    sprite.ellipse([x1, y1, x2, y2], fill=OUTLINE_COLOR, outline=OUTLINE_COLOR)

def draw_chip():
    img = Image.new('RGBA', (SPRITE_WIDTH, SPRITE_HEIGHT), (0, 0, 0, 0))
    sprite = ImageDraw.Draw(img)

    # Chip
    rect_width = int(SPRITE_WIDTH * 0.6)
    rect_height = int(SPRITE_HEIGHT * 0.4)

    x1 = (SPRITE_WIDTH - rect_width) // 2
    y1 = (SPRITE_HEIGHT - rect_height) // 2
    x2 = x1 + rect_width
    y2 = y1 + rect_height

    sprite.rectangle([x1, y1, x2, y2],
                    fill=FILL_COLOR,
                    outline=OUTLINE_COLOR,
                    width=OUTLINE_THICKNESS)

    # AI
    font_size = 48
    font = ImageFont.truetype("Arial", font_size)

    text = "AI"
    text_bbox = sprite.textbbox((0, 0), text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]

    text_x = (SPRITE_WIDTH - text_width) // 2
    text_y = y1 + (rect_height - text_height) // 2 - text_height // 4

    sprite.text((text_x, text_y), text, fill=OUTLINE_COLOR, font=font)

    # Pins
    pin_count = len(PINS)
    pin_spacing = rect_width // (pin_count + 1)

    for i, (pin_len, pin_step) in enumerate(PINS):
        pin_x = x1 + pin_spacing * (i + 1)
        plot_pin(sprite, pin_x, y1, 0, -1, pin_len, pin_step)

    for i, (pin_len, pin_step) in enumerate(PINS):
        pin_x = x1 + pin_spacing * (i + 1)
        plot_pin(sprite, pin_x, y2, 0, 1, pin_len, pin_step)

    # Resize to 128x128
    img = img.resize((128, 128), Image.LANCZOS)

    return img

if __name__ == "__main__":
    img = draw_chip()
    img.save('chip.png')
    print("Generated chip.png")
