"""
生成 world.tscn 和 town.tscn 的 TileMapLayer tile_map_data
格式: struct.pack('<hhhhhh', x, y, source_id, atlas_x, atlas_y, alt) × N cells
base64 编码写入 PackedByteArray("...")
"""
import struct, base64

# ── Tile 类型 (atlas 坐标, 对应 world_tiles16.png) ──────────────
T_GRASS      = (0, 0)
T_TALL_GRASS = (2, 0)
T_DIRT       = (4, 0)
T_WATER      = (0, 1)
T_STONE      = (6, 0)

def encode_tiles(tile_dict: dict) -> str:
    cells = []
    for (x, y), (ax, ay) in sorted(tile_dict.items(), key=lambda kv: (kv[0][1], kv[0][0])):
        cells.append(struct.pack('<hhhhhh', x, y, 0, ax, ay, 0))
    return base64.b64encode(b''.join(cells)).decode()

def paint_patch(tiles, col, row, w, h, tile_type):
    for r in range(h):
        for c in range(w):
            tiles[(col+c, row+r)] = tile_type

COLS, ROWS = 60, 40

# ── 华灵草原 (world.tscn) 本地 0-59 × 0-39 ─────────────────────
world_tiles = {}
for r in range(ROWS):
    for c in range(COLS):
        world_tiles[(c, r)] = T_GRASS

for patch in [[64,8,6,4],[72,14,5,5],[80,6,7,4],[66,24,5,4],[76,28,6,3],[90,15,5,4],[100,22,6,4]]:
    paint_patch(world_tiles, patch[0]-60, patch[1], patch[2], patch[3], T_TALL_GRASS)

for c in range(COLS):
    world_tiles[(c, 36)] = T_DIRT
    world_tiles[(c, 37)] = T_DIRT

for pt in [[90,20],[91,20],[92,20],[89,21],[90,21],[91,21],[92,21],[93,21],[90,22],[91,22],[92,22]]:
    world_tiles[(pt[0]-60, pt[1])] = T_WATER

world_b64 = encode_tiles(world_tiles)
print(f"world: {len(world_tiles)} cells")

# ── 碧溪镇 (town.tscn) 本地 0-59 × 0-39 ───────────────────────
town_tiles = {}
for r in range(ROWS):
    for c in range(COLS):
        town_tiles[(c, r)] = T_GRASS

for r in range(ROWS):
    for c in range(13, 17):
        town_tiles[(c, r)] = T_STONE

for c in range(COLS):
    town_tiles[(c, 16)] = T_STONE
    town_tiles[(c, 17)] = T_STONE
    town_tiles[(c, 36)] = T_STONE
    town_tiles[(c, 37)] = T_STONE

paint_patch(town_tiles, 2, 27, 4, 3, T_TALL_GRASS)
paint_patch(town_tiles, 38, 25, 4, 3, T_TALL_GRASS)

town_b64 = encode_tiles(town_tiles)
print(f"town: {len(town_tiles)} cells")

# ══ 更新 world.tscn ════════════════════════════════════════════
WORLD_TSCN = r"D:\AI\Game\RPG_Demo\scenes\world.tscn"
with open(WORLD_TSCN, 'r', encoding='utf-8') as f:
    content = f.read()

# 给 TileSetAtlasSource 加上 texture_region_size（若没有）
if 'texture_region_size' not in content:
    content = content.replace(
        'texture = ExtResource("2")\n0:0/0 = 0',
        'texture = ExtResource("2")\ntexture_region_size = Vector2i(16, 16)\n0:0/0 = 0'
    )

# 给 TileSet 加 tile_size（若没有）
if 'tile_size' not in content:
    content = content.replace(
        '[sub_resource type="TileSet" id="TileSet_k7we6"]\nsources/0',
        '[sub_resource type="TileSet" id="TileSet_k7we6"]\ntile_size = Vector2i(16, 16)\nsources/0'
    )

# 给 Ground 节点插入 tile_map_data（在 tile_set 行之后）
old_ground = 'tile_set = SubResource("TileSet_k7we6")\n\n[node name="Decorations"'
new_ground = f'tile_set = SubResource("TileSet_k7we6")\ntile_map_data = PackedByteArray("{world_b64}")\n\n[node name="Decorations"'
content = content.replace(old_ground, new_ground)

with open(WORLD_TSCN, 'w', encoding='utf-8') as f:
    f.write(content)
print("world.tscn updated.")

# ══ 更新 town.tscn ═════════════════════════════════════════════
TOWN_TSCN = r"D:\AI\Game\RPG_Demo\scenes\town.tscn"
with open(TOWN_TSCN, 'r', encoding='utf-8') as f:
    town_content = f.read()

# 在文件头（format行之后）插入 TileSet 相关资源
TILESET_BLOCK = f'''[ext_resource type="Texture2D" path="res://assets/tilemaps/world_tiles16.png" id="10"]

[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_town"]
texture = ExtResource("10")
texture_region_size = Vector2i(16, 16)
0:0/0 = 0
2:0/0 = 0
4:0/0 = 0
6:0/0 = 0
0:1/0 = 0

[sub_resource type="TileSet" id="TileSet_town"]
tile_size = Vector2i(16, 16)
sources/0 = SubResource("TileSetAtlasSource_town")

'''

# 插到第一个 ext_resource 之前
first_ext = '[ext_resource type="Script"'
if 'TileSet_town' not in town_content:
    town_content = town_content.replace(first_ext, TILESET_BLOCK + first_ext)

# 在根节点（[node name="town"...] 行后）插入 Ground
GROUND_NODE = f'''[node name="Ground" type="TileMapLayer" parent="."]
z_index = -5
tile_set = SubResource("TileSet_town")
tile_map_data = PackedByteArray("{town_b64}")

'''

# 插在 Buildings 节点之前
if '[node name="Ground"' not in town_content:
    town_content = town_content.replace(
        '\n[node name="Buildings" type="Node2D" parent="."]',
        '\n' + GROUND_NODE + '[node name="Buildings" type="Node2D" parent="."]'
    )

with open(TOWN_TSCN, 'w', encoding='utf-8') as f:
    f.write(town_content)
print("town.tscn updated.")
print("Done!")
