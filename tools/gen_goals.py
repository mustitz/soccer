from PIL import Image, ImageDraw
from collections import namedtuple

Point = namedtuple('Point', ['x', 'y'])

# Constants
CELL_SIZE = 128
PIPE = 20
PIPE2 = 4
KX1, KX2, KY1, KY2 = 0.30, 0.75, 0.27, 0.70
K = 0.60
NET_DIV = 17
COLOR = (255, 255, 255, 255)

def draw_net_lines(draw, edge1, edge2, spacing):
    """
    Draw net lines connecting two edges divided into N parts.
    edge1: (x1, y1, x2, y2) - first edge coordinates
    edge2: (x3, y3, x4, y4) - second edge coordinates
    spacing: desired spacing in pixels
    """
    x1, y1, x2, y2 = edge1
    x3, y3, x4, y4 = edge2

    # Calculate edge lengths
    len1 = ((x2 - x1)**2 + (y2 - y1)**2)**0.5
    len2 = ((x4 - x3)**2 + (y4 - y3)**2)**0.5

    # Find best N to get close to spacing
    mlen = (len1 + len2) / 2
    N = max(1, round(mlen / spacing))

    # Draw connecting lines
    for i in range(N + 1):
        t = i / N if N > 0 else 0

        # Points on edge1
        p1_x = x1 + t * (x2 - x1)
        p1_y = y1 + t * (y2 - y1)

        # Points on edge2
        p2_x = x3 + t * (x4 - x3)
        p2_y = y3 + t * (y4 - y3)

        draw.line([p1_x, p1_y, p2_x, p2_y], fill=COLOR, width=1)

def create_goal_texture(gate_length):
    width = gate_length * CELL_SIZE
    height = CELL_SIZE

    # Create image with transparency
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Outer rectangle
    p111 = Point(0, 0)
    p112 = Point(width-1, 0)
    p121 = Point(0, height-1)
    p122 = Point(width-1, height-1)

    # Inner rectangle with constants
    delta = 1.5
    p211 = Point(int(KX1 * CELL_SIZE - delta), int(KY1 * CELL_SIZE - delta))
    p212 = Point(int(width - (CELL_SIZE - KX2 * CELL_SIZE) + delta), int(KY1 * CELL_SIZE - delta))
    p221 = Point(int(KX1 * CELL_SIZE - delta), int(height - (CELL_SIZE - KY2 * CELL_SIZE) + delta))
    p222 = Point(int(width - (CELL_SIZE - KX2 * CELL_SIZE) + delta), int(height - (CELL_SIZE - KY2 * CELL_SIZE) + delta))

    # Adjust points for pipe thickness
    q111 = Point(p111.x + K * PIPE, p111.y + K * PIPE)
    q112 = Point(p112.x - K * PIPE, p112.y + K * PIPE)
    q121 = Point(p121.x + K * PIPE, p121.y - K * PIPE)
    q122 = Point(p122.x - K * PIPE, p122.y - K * PIPE)

    # Outer border
    draw.line([*p121, *p111], fill=COLOR, width=PIPE)
    draw.line([*p111, *p112], fill=COLOR, width=PIPE)
    draw.line([*p112, *p122], fill=COLOR, width=PIPE)

    # Draw rectangles and connections
    draw.line([*p221, *p211], fill=COLOR, width=PIPE2)
    draw.line([*p211, *p212], fill=COLOR, width=PIPE2)
    draw.line([*p212, *p222], fill=COLOR, width=PIPE2)
    #draw.line([*p222, *p221], fill=COLOR, width=PIPE2)

    draw.line([*p111, *p211], fill=COLOR, width=PIPE2)
    draw.line([*p112, *p212], fill=COLOR, width=PIPE2)
    #draw.line([*p121, *p221], fill=COLOR, width=PIPE2)
    #draw.line([*p122, *p222], fill=COLOR, width=PIPE2)

    # Add net lines
    net_div = CELL_SIZE / NET_DIV

    # Net lines, left
    draw_net_lines(draw, (*q111, *p211), (*q121, *p221), net_div)
    draw_net_lines(draw, (*q111, *q121), (*p211, *p221), net_div)

    # Net lines, top
    draw_net_lines(draw, (*q111, *p211), (*q112, *p212), net_div)
    draw_net_lines(draw, (*q111, *q112), (*p211, *p212), net_div)

    # Net lines, right
    draw_net_lines(draw, (*q112, *p212), (*q122, *p222), net_div)
    draw_net_lines(draw, (*q112, *q122), (*p212, *p222), net_div)

    # Net lines, middle
    draw_net_lines(draw, (*p211, *p221), (*p212, *p222), net_div)
    draw_net_lines(draw, (*p211, *p212), (*p221, *p222), net_div)

    return img

# Generate for specific gate lengths
for length in range(2, 21, 2):
    img = create_goal_texture(length)
    img.save(f'goal_{length:02d}.png')
    print(f"Generated goal_{length:02d}.png")

print("All goal textures generated!")
