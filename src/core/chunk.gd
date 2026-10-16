# chunk.gd
class_name Chunk

var x: int
var y: int
var biome: String = "Grasland"
var tiles: Array = []
var barriers: Array = []

func _init(p_x: int, p_y: int):
    x = p_x
    y = p_y
    _init_tiles() 

func _init_tiles():
    """Initializes the 32x32 tile array with standard tiles"""
    tiles = []
    for i in range(32):
        tiles.append([])
        for j in range(32):
            tiles[i].append("Gras") # Standard Kachel

func add_barrier(polygon: Array[Vector2]) -> void:
    """Fügt eine neue Barriere hinzu."""
    print("BARRIERS ADDED!")
    var barrier = Barrier.new()
    barrier.polygon = polygon
    barriers.append(barrier)

func is_barrier(p_x: int, p_y: int) -> bool:
    """Prüft, ob eine Kachel eine Barriere ist."""
    for barrier in barriers:
        if barrier.contains_point(Vector2(p_x, p_y)):
            return true
    return false

func set_tile(p_x: int, p_y: int, tile_type: String) -> void:
    """Setzt eine Kachel an der Position (x, y)."""
    if p_x >= 0 and p_x < 32 and p_y >= 0 and p_y < 32:
        tiles[p_x][p_y] = tile_type

func get_tile(p_x: int, p_y: int) -> String:
    """Gibt den Kachel-Typ an der Position (x, y) zurück."""
    if p_x >= 0 and p_x < 32 and p_y >= 0 and p_y < 32:
        return tiles[p_x][p_y]
    return ""