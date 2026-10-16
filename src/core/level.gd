# level.gd
class_name Level

# Level-Parameter
var width: int
var height: int
var chunk_size: int
var tile_size: int
var seed: int

# Chunks (2D-Array)
var chunks: Array = []

# --- Initialisierung ---
func _init(p_width: int, p_height: int, p_chunk_size: int, p_tile_size: int, p_seed: int):
    width = p_width
    height = p_height
    chunk_size = p_chunk_size
    tile_size = p_tile_size
    seed = p_seed

# --- Level generieren (minimale Implementierung) ---
func generate() -> void:
    for x in range(width):
        chunks.append([])
        for y in range(height):
            # Erstelle einen Dummy-Chunk (für Tests)
            chunks[x].append(Chunk.new(x, y))

# --- Chunk abrufen ---
func get_chunk(x: int, y: int) -> Chunk:
    if x >= 0 and x < width and y >= 0 and y < height:
        return chunks[x][y]
    return null