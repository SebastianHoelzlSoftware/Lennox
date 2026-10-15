# Procedural 2D Map Generierung

## Übersicht

Dieses Dokument beschreibt den Algorithmus und die Implementierung der **prozeduralen 2D-Map-Generierung** für Lennox. Das Ziel ist eine dynamische, abwechslungsreiche Spielwelt mit natürlichen Biomen, geschlossenen Barrieren und strategisch platzierten Öffnungen.

---

## Technische Rahmenbedingungen

| Parameter          | Wert                     | Begründung                          |
|--------------------|--------------------------|-------------------------------------|
| **Level-Größe**    | 64x64 Chunks             | Ausreichend groß für Prototypen      |
| **Chunk-Größe**    | 32x32 Kacheln            | Balance zwischen Detail und Performance |
| **Kachelgröße**    | 32x32 Pixel              | Optimal für Mobile-Performance       |
| **Gesamtgröße**    | 2048x2048 Pixel          | 64 Chunks × 32 Kacheln × 32 Pixel    |
| **Implementierung**| GDScript                 | Einfache Integration in Godot       |
| **Determinismus**   | Pro Chunk                | Gleiche Seed = gleicher Chunk        |

---

## Algorithmus-Übersicht

Die Map-Generierung folgt einem **4-stufigen Prozess**:

1. **Biom-Generierung** (Voronoi + Perlin Noise)
2. **Barrieren-Generierung** (Convex Hull + Perturbation)
3. **Öffnungen platzieren** (0–n pro Barriere)
4. **Kacheln erstellen** (TileMap in Godot)

---

## 1. Biom-Generierung

### Basis-Biome

| Biom      | Barrierendichte | Typische Barrierentypen | Öffnungs-Häufigkeit | Beschreibung                     |
|-----------|------------------|-------------------------|---------------------|---------------------------------|
| Grasland  | Niedrig (1–2)    | Fels, Baumgruppen      | Hoch (1–3)          | Offene Flächen mit vereinzelten Hindernissen |
| Wald      | Hoch (3–5)       | Baumgruppen, Fels     | Mittel (1–2)        | Dichte Vegetation mit natürlichen Barrieren |
| Fels      | Sehr hoch (5–8)  | Felsketten, Klippen    | Niedrig (0–1)       | Bergige, schwer passierbare Regionen |
| Wasser    | Keine            | Inseln                 | –                   | Seen, Flüsse, Meere             |
| Sand      | Niedrig (1–2)    | Dünen, Fels            | Hoch (1–3)          | Wüsten oder Strandregionen      |

### Generierungsprozess

1. **Voronoi-Diagramm:**
   - Teile das Level in **3–5 Voronoi-Zellen** pro Chunk-Gruppe ein.
   - Jede Zelle wird einem **Biom-Typ** zugewiesen.
   - **Ziel:** Natürliche, organische Regionen.

2. **Perlin Noise für Übergänge:**
   - Wende **Perlin Noise** auf die Voronoi-Grenzen an, um **glatte Übergänge** zwischen Biomen zu erzeugen.
   - **Parameter:**
     - Skalierung: 0.05–0.1
     - Octaves: 2–4
     - Persistence: 0.5

3. **Biom-spezifische Anpassungen:**
   - **Wasser:** Nur in Senken (Noise-Werte < 0.2).
   - **Fels:** Auf Hügeln (Noise-Werte > 0.7).
   - **Wald:** In mittleren Höhen (Noise-Werte 0.4–0.7).

---

## 2. Barrieren-Generierung

### Algorithmus: Convex Hull + Perturbation

1. **Zufallspunkte generieren:**
   - Pro Chunk: **5–15 Zufallspunkte** im inneren Bereich (nicht am Rand).
   - **Abstand:** Mindestens 2 Kacheln zwischen Punkten.

2. **Convex Hull berechnen:**
   - Finde das **kleinste konvexe Polygon**, das alle Punkte umschließt.
   - **Methode:** Graham-Scan oder QuickHull-Algorithmus.

3. **Perturbation für organische Formen:**
   - Verschiebe jeden Punkt der Convex Hull **zufällig um ±1–2 Kacheln** nach innen oder außen.
   - **Ziel:** Natürlichere, weniger geometrische Formen.

4. **Barriere als Kacheln umsetzen:**
   - Alle Kacheln **innerhalb des Polygons** werden zu **Barrieren-Kacheln** (z.B. Fels- oder Baum-Texturen).
   - **Kollisionsabfrage:** Diese Kacheln blockieren den Spieler.

### Biom-abhängige Parameter

| Biom      | Barrieren pro Chunk | Typische Barrierengröße | Innenfläche       |
|-----------|---------------------|--------------------------|-------------------|
| Grasland  | 1–2                 | 5–10 Kacheln Durchmesser | Gras              |
| Wald      | 3–5                 | 8–15 Kacheln Durchmesser | Wald              |
| Fels      | 5–8                 | 10–20 Kacheln Durchmesser| Fels              |
| Wasser    | 0–1 (Inseln)        | 15–30 Kacheln Durchmesser| Wasser (Insel)    |
| Sand      | 1–2                 | 6–12 Kacheln Durchmesser | Sand              |

---

## 3. Öffnungen in Barrieren

### Öffnungs-Typen

| Typ       | Breite (Kacheln) | Beschreibung                          | Passierbar | Interaktiv |
|-----------|------------------|---------------------------------------|------------|------------|
| Treppe    | 2–3              | Schräge Kacheln für Höhenunterschiede | Ja         | Nein       |
| Tür       | 1                | Einfache Lücke mit Tür-Objekt         | Ja         | **Ja**     |
| Furt      | 2–4              | Wasser-Kacheln in der Barriere        | Ja         | Nein       |
| Pass      | 3–5              | Schmale Passage mit Fels-Kacheln      | Ja         | Nein       |

### Platzierungsregeln

1. **Anzahl pro Barriere:**
   - **Grasland:** 80% Chance auf 1–3 Öffnungen.
   - **Wald:** 60% Chance auf 1–2 Öffnungen.
   - **Fels:** 20% Chance auf 0–1 Öffnung.

2. **Positionierung:**
   - Wähle **zufällig eine Kante** des Barrieren-Polygons.
   - Ersetze die Kante durch eine **Lücke** (Breite = Öffnungsbreite).
   - **Einschränkung:** Öffnung darf **nicht an einer Chunk-Grenze** liegen.

3. **Interaktive Öffnungen:**
   - **Türen** sind standardmäßig **gesperrt** und müssen durch Rätsel geöffnet werden.
   - **Markierung:** Spezielle Kachel (z.B. Tür-Texture) für interaktive Öffnungen.

---

## 4. Godot-Integration

### Datenstrukturen

#### Level
```gdscript
class_name Level
var width: int      # Anzahl Chunks (x)
var height: int     # Anzahl Chunks (y)
var chunk_size: int # Kacheln pro Chunk (32)
var tile_size: int  # Pixel pro Kachel (32)
var seed: int       # Basis-Seed für Determinismus
var chunks: Array[Chunk] # 2D-Array von Chunks
```

#### Chunk
```gdscript
class_name Chunk
var x: int          # Chunk-Koordinate (x)
var y: int          # Chunk-Koordinate (y)
var biome: String   # Biom-Typ (z.B. "Grasland")
var tiles: Array    # 2D-Array von Kachel-Typen
var barriers: Array[Barrier] # Liste von Barrieren im Chunk
```

#### Barriere
```gdscript
class_name Barrier
var polygon: Array[Vector2] # Liste von Punkten (Kachel-Koordinaten)
var biome: String           # Biom-Typ der Innenfläche
var openings: Array[Opening] # Liste von Öffnungen
```

#### Öffnung
```gdscript
class_name Opening
var type: String     # "Treppe", "Tür", "Furt", "Pass"
var position: Vector2 # Start-Kachel der Öffnung
var width: int       # Breite in Kacheln
var is_interactive: bool # Für Türen: true
```

### Generierungs-Ablauf in GDScript

```gdscript
func generate_level(seed: int, width: int, height: int) -> Level:
    var level = Level.new()
    level.seed = seed
    level.width = width
    level.height = height
    
    # 1. Biom-Karte generieren
    level.biomes = generate_biome_map(seed, width, height)
    
    # 2. Barrieren pro Chunk generieren
    for x in range(width):
        for y in range(height):
            var chunk = generate_chunk(seed, x, y, level.biomes[x][y])
            level.chunks[x][y] = chunk
    
    # 3. Chunk-Übergänge glätten (optional)
    smooth_chunk_transitions(level)
    
    return level

func generate_chunk(seed: int, x: int, y: int, biome: String) -> Chunk:
    var chunk = Chunk.new()
    chunk.x = x
    chunk.y = y
    chunk.biome = biome
    
    # Biom-spezifische Barrieren generieren
    var num_barriers = get_barrier_count_for_biome(biome)
    for i in range(num_barriers):
        var barrier = generate_barrier(seed, x, y, biome)
        chunk.barriers.append(barrier)
    
    # Kacheln aus Barrieren und Biom erstellen
    chunk.tiles = generate_tiles_from_barriers(chunk)
    
    return chunk
```

---

## 5. Kollisionsabfrage

- **Barrieren-Kacheln:** Blockieren den Spieler (Kollisionslayer: `Barrier`).
- **Öffnungen:** Keine Kollisionsabfrage (Kollisionslayer: `Passable`).
- **Interaktive Öffnungen (Türen):**
  - Standardmäßig blockieren.
  - Bei Interaktion (z.B. Rätsel gelöst): Kollisionslayer auf `Passable` ändern.

---

## 6. Performance-Optimierungen

1. **Chunk-Caching:**
   - Generierte Chunks zwischenspeichern (z.B. in einem Dictionary: `{x, y: Chunk}`).

2. **Lazy Loading:**
   - Nur Chunks generieren, die **im Sichtbereich der Kamera** sind.
   - **Puffer:** 2–3 Chunks um den Sichtbereich herum vorladen.

3. **Kachel-Optimierung:**
   - **TileMap** in Godot verwenden (effizienter als einzelne Kachel-Objekte).
   - **Collider:** `CollisionPolygon2D` für komplexe Barrieren oder `CollisionShape2D` für einfache Formen.

---

## 7. Beispiele

### Beispiel 1: Grasland-Chunk
- **Biom:** Grasland
- **Barrieren:** 1 Felsgruppe (8x8 Kacheln) mit 2 Öffnungen (1 Furt, 1 Pass).
- **Innenfläche:** Gras.

### Beispiel 2: Fels-Chunk
- **Biom:** Fels
- **Barrieren:** 3 Felsketten (10–15 Kacheln Durchmesser) mit 0–1 Öffnung pro Barriere.
- **Innenfläche:** Fels.

### Beispiel 3: Wald-Chunk
- **Biom:** Wald
- **Barrieren:** 4 Baumgruppen (6–12 Kacheln Durchmesser) mit 1–2 Öffnungen pro Barriere.
- **Innenfläche:** Wald.

---

## 8. Erweiterungen (Zukunft)

1. **Weitere Biome:** Höhle, Vulkan, Schnee, etc.
2. **Dynamische Barrieren:** Barrieren, die sich bewegen oder verschwinden (z.B. durch Rätsel).
3. **Höhenkarte:** 2.5D-Effekte mit Höhenunterschieden.
4. **Prozedurale Objekte:** Bäume, Steine, etc. auf Kacheln platzieren.
5. **Level-Themen:** Spezielle Level mit einzigartigen Barrieren (z.B. "Tempel-Level" mit vielen Türen).

---

## Anhang: Algorithmus-Pseudocode

### Convex Hull (Graham-Scan)
```
1. Finde den Punkt mit der niedrigsten y-Koordinate (P0).
2. Sortiere alle Punkte nach dem Polarwinkel zu P0.
3. Initialisiere einen Stack mit P0, P1, P2.
4. Für jeden weiteren Punkt P:
   a. Während der Winkel zwischen den letzten 2 Punkten im Stack und P > 180°:
      - Entferne den letzten Punkt aus dem Stack.
   b. Füge P zum Stack hinzu.
5. Der Stack enthält die Convex Hull.
```

### Perturbation
```
Für jeden Punkt in der Convex Hull:
   - Verschiebe den Punkt um ±1–2 Kacheln in x- und y-Richtung.
   - Stelle sicher, dass das Polygon geschlossen bleibt.
```

### Perlin Noise
```
func perlin_noise(x: float, y: float, seed: int) -> float:
    # Implementierung eines einfachen Perlin-Noise-Algorithmus
    # oder Nutzung von Godots `OpenSimplexNoise`.
    pass
```

---

## Links

- [Godot TileMap Dokumentation](https://docs.godotengine.org/en/stable/tutorials/2d/procedural_geometry/tilemap.html)
- [OpenSimplexNoise in Godot](https://docs.godotengine.org/en/stable/classes/class_opensimplexnoise.html)
- [Convex Hull Algorithmen](https://en.wikipedia.org/wiki/Convex_hull_algorithms)
