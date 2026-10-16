# chunk.gd
class_name Chunk

# Koordinaten
var x: int
var y: int

# Biom (Standard: Grasland)
var biome: String = "Grasland"

# Kacheln (32x32)
var tiles: Array = []

# Barrieren
var barriers: Array = []

# --- Initialisierung ---
func _init(p_x: int, p_y: int):
    x = p_x
    y = p_y
    # 32x32 Kacheln initialisieren
    for i in range(32):
        tiles.append([])
        for j in range(32):
            tiles[i].append("Gras")  # Standard-Kachel