# level.gd
class_name Level

# Level-Parameter
var width: int
var height: int
var chunk_size: int
var tile_size: int
var world_seed: int

# Chunks (2D-Array)
var chunks: Array = []

# --- Initialisierung ---
func _init(p_width: int, p_height: int, p_chunk_size: int, p_tile_size: int, p_world_seed: int):
    width = p_width
    height = p_height
    chunk_size = p_chunk_size
    tile_size = p_tile_size
    world_seed = p_world_seed

# --- Level generieren ---
func generate() -> void:
    """Generiert alle Chunks für das Level."""
    # Seed für Determinismus setzen
    seed_random(world_seed)

    for x in range(width):
        chunks.append([])
        for y in range(height):
            chunks[x].append(generate_chunk(x, y))

func generate_chunk(p_x: int, p_y: int) -> Chunk:
    """Generiert einen einzelnen Chunk."""
    var chunk := Chunk.new(p_x, p_y)

    # Biom für den Chunk generieren (vereinfacht für Prototyp)
    chunk.biome = _get_biome_for_chunk(p_x, p_y)

    # Hier später: Barrieren generieren (für [LEN-5])
    # var barriers := generate_barriers_for_chunk(p_x, p_y, chunk.biome)
    # for barrier in barriers:
    #     chunk.barriers.append(barrier)

    return chunk

func _get_biome_for_chunk(p_x: int, p_y: int) -> String:
    """Gibt ein Biom für den Chunk zurück (vereinfacht für Prototyp)."""
    # Deterministisch basierend auf Seed + Koordinaten
    var hash_val := hash([p_x, p_y, seed])
    var biome_index : int = abs(hash_val) % 5  # 5 Biome
    var biomes := ["Grasland", "Wald", "Fels", "Wasser", "Sand"]
    return biomes[biome_index]

# --- Chunk-Zugriff ---
func get_chunk(p_x: int, p_y: int) -> Chunk:
    """Gibt den Chunk an der Position (x, y) zurück."""
    if p_x >= 0 and p_x < width and p_y >= 0 and p_y < height:
        return chunks[p_x][p_y]
    return null

# --- Hilfsfunktionen ---
func hash(arr: Array) -> int:
    """Einfache Hash-Funktion für Determinismus."""
    var result := 0
    for item in arr:
        result = (result * 31 + item) % 2147483647
    return result

func seed_random(p_world_seed: int) -> void:
    randomize()
    seed(p_world_seed)
