# Biome-System für Lennox

## Übersicht

Biome definieren die **Grundstruktur und das Aussehen** der Spielwelt. Jedes Biom hat spezifische Eigenschaften wie **Barrierendichte, typische Hindernisse und Öffnungen**, die den Spielverlauf beeinflussen.

---

## Basis-Biome

| Biom      | Beschreibung                                                                 | Farbe (Hex)  | Barrierendichte | Typische Barrieren       | Öffnungs-Häufigkeit |
|-----------|-----------------------------------------------------------------------------|--------------|------------------|---------------------------|---------------------|
| Grasland  | Offene, grüne Flächen mit vereinzelten Bäumen oder Felsen.               | `#7CF06B`    | Niedrig (1–2)    | Fels, Baumgruppen         | Hoch (1–3)          |
| Wald      | Dichte Vegetation mit vielen natürlichen Hindernissen.                   | `#3A7D44`    | Hoch (3–5)       | Baumgruppen, Fels        | Mittel (1–2)        |
| Fels      | Bergige, felsige Regionen mit steilen Klippen.                           | `#8B8B8B`    | Sehr hoch (5–8)  | Felsketten, Klippen       | Niedrig (0–1)       |
| Wasser    | Seen, Flüsse oder Meere. Keine Barrieren, außer Inseln.                  | `#4169E1`    | Keine            | Inseln (umgekehrte Logik)| –                   |
| Sand      | Wüsten oder Strandregionen mit Dünen und vereinzelten Felsen.            | `#F4A460`    | Niedrig (1–2)    | Dünen, Fels               | Hoch (1–3)          |

---

## Biom-Parameter

### Grasland
- **Höhenprofil:** Flach bis leicht hügelig (Perlin Noise: 0.3–0.6).
- **Vegetation:** Gras, vereinzelte Bäume, Blumen.
- **Barrieren:**
  - **Fels:** Kleine Felsgruppen (5–8 Kacheln Durchmesser).
  - **Baumgruppen:** 3–5 Bäume in einer Gruppe.
- **Öffnungen:**
  - **Furt:** Häufig (wenn Wasser in der Nähe).
  - **Pass:** Mittel.
  - **Treppe:** Selten.

### Wald
- **Höhenprofil:** Leicht hügelig (Perlin Noise: 0.4–0.7).
- **Vegetation:** Dichte Bäume, Sträucher, Moos.
- **Barrieren:**
  - **Baumgruppen:** 5–10 Bäume in einer Gruppe (10–15 Kacheln Durchmesser).
  - **Fels:** Kleine Felsvorsprünge.
- **Öffnungen:**
  - **Pass:** Häufig (zwischen Baumgruppen).
  - **Furt:** Mittel (wenn Wasser in der Nähe).
  - **Tür:** Selten (z.B. für Höhlen oder besondere Bereiche).

### Fels
- **Höhenprofil:** Sehr hügelig bis bergig (Perlin Noise: 0.7–1.0).
- **Vegetation:** Kaum Vegetation, vereinzelte Flechten.
- **Barrieren:**
  - **Felsketten:** 10–20 Kacheln Durchmesser, oft geschlossene Polygone.
  - **Klippen:** Senkrechte Wände (nicht passierbar).
- **Öffnungen:**
  - **Pass:** Selten (enge Schluchten).
  - **Treppe:** Mittel (für Höhenunterschiede).
  - **Tür:** Sehr selten (z.B. für Höhleneingänge).

### Wasser
- **Höhenprofil:** Flach (Perlin Noise: 0.0–0.2).
- **Vegetation:** Keine (außer auf Inseln).
- **Barrieren:**
  - **Inseln:** 15–30 Kacheln Durchmesser (Fels oder Sand).
- **Öffnungen:**
  - **Furt:** Immer (wenn Insel an Land grenzt).

### Sand
- **Höhenprofil:** Flach bis leicht hügelig (Perlin Noise: 0.2–0.5).
- **Vegetation:** Kaum Vegetation, vereinzelte Kakteen (für Wüste).
- **Barrieren:**
  - **Dünen:** 6–12 Kacheln Durchmesser (Sandhügel).
  - **Fels:** Kleine Felsformationen.
- **Öffnungen:**
  - **Pass:** Häufig (zwischen Dünen).
  - **Furt:** Selten (nur bei Oasen).

---

## Biom-Übergänge

### Regeln für glatte Übergänge
1. **Voronoi + Perlin Noise:**
   - **Voronoi** definiert die groben Regionen.
   - **Perlin Noise** glättet die Übergänge zwischen den Regionen.

2. **Pufferzonen:**
   - An den Grenzen zwischen Biomen gibt es eine **Pufferzone von 2–4 Kacheln**, in der die Eigenschaften der beiden Biome gemischt werden.
   - **Beispiel:** Grasland → Wald: Die Pufferzone enthält sowohl Gras als auch vereinzelte Bäume.

3. **Biom-Dominanz:**
   - Das **dominante Biom** in einer Zelle wird durch den **nächsten Voronoi-Punkt** bestimmt.
   - Der **Noise-Wert** bestimmt die **Höhe und Dichte** innerhalb des Bioms.

### Beispiel: Grasland → Wald
| Entfernung zum Waldrand | Biom-Mix          | Vegetation               |
|--------------------------|-------------------|---------------------------|
| 0–2 Kacheln              | 70% Gras, 30% Wald | Gras + vereinzelte Bäume |
| 2–4 Kacheln              | 30% Gras, 70% Wald | Dichtes Gras + viele Bäume|
| >4 Kacheln               | 100% Wald         | Nur Bäume und Sträucher   |

---

## Biom-spezifische Barrieren-Parameter

### Grasland
| Parameter               | Wert                     |
|-------------------------|--------------------------|
| Barrieren pro Chunk     | 1–2                      |
| Barrierengröße          | 5–10 Kacheln Durchmesser |
| Öffnungen pro Barriere  | 1–3                      |
| Typische Öffnungs-Typen | Furt (50%), Pass (30%), Treppe (20%) |

### Wald
| Parameter               | Wert                     |
|-------------------------|--------------------------|
| Barrieren pro Chunk     | 3–5                      |
| Barrierengröße          | 8–15 Kacheln Durchmesser |
| Öffnungen pro Barriere  | 1–2                      |
| Typische Öffnungs-Typen | Pass (60%), Furt (20%), Tür (20%) |

### Fels
| Parameter               | Wert                     |
|-------------------------|--------------------------|
| Barrieren pro Chunk     | 5–8                      |
| Barrierengröße          | 10–20 Kacheln Durchmesser|
| Öffnungen pro Barriere  | 0–1                      |
| Typische Öffnungs-Typen | Pass (70%), Treppe (30%) |

### Wasser
| Parameter               | Wert                     |
|-------------------------|--------------------------|
| Barrieren pro Chunk     | 0–1 (Inseln)             |
| Barrierengröße          | 15–30 Kacheln Durchmesser|
| Öffnungen pro Barriere  | 1–2 (Furten)             |
| Typische Öffnungs-Typen | Furt (100%)              |

### Sand
| Parameter               | Wert                     |
|-------------------------|--------------------------|
| Barrieren pro Chunk     | 1–2                      |
| Barrierengröße          | 6–12 Kacheln Durchmesser |
| Öffnungen pro Barriere  | 1–3                      |
| Typische Öffnungs-Typen | Pass (80%), Furt (20%)   |

---

## Implementierung in GDScript

### Biom-Karte generieren
```gdscript
func generate_biome_map(seed: int, width: int, height: int) -> Array:
    var biome_map = []
    var noise = OpenSimplexNoise.new()
    noise.seed = seed
    noise.octaves = 4
    noise.period = 20.0
    noise.persistence = 0.5
    
    # Voronoi-Punkte generieren (1 Punkt pro 5x5 Chunks)
    var voronoi_points = []
    var step = 5
    for x in range(0, width, step):
        for y in range(0, height, step):
            voronoi_points.append(Vector2(x, y))
    
    # Biom-Typen für Voronoi-Punkte zuweisen
    var biome_types = ["Grasland", "Wald", "Fels", "Wasser", "Sand"]
    var biome_assignments = []
    for point in voronoi_points:
        var biome_idx = randi() % biome_types.size()
        biome_assignments.append(biome_types[biome_idx])
    
    # Biom-Karte erstellen
    for x in range(width):
        biome_map.append([])
        for y in range(height):
            # Nächsten Voronoi-Punkt finden
            var min_dist = INF
            var closest_idx = -1
            for i in range(voronoi_points.size()):
                var dist = voronoi_points[i].distance_to(Vector2(x, y))
                if dist < min_dist:
                    min_dist = dist
                    closest_idx = i
            
            # Noise-Wert für Glättung
            var noise_val = noise.get_noise_2d(x * 0.1, y * 0.1)
            
            # Biom zuweisen (mit Noise-Glättung)
            var biome = biome_assignments[closest_idx]
            biome_map[x].append(biome)
    
    return biome_map
```

### Biom-spezifische Parameter abrufen
```gdscript
func get_biome_params(biome: String) -> Dictionary:
    match biome:
        "Grasland":
            return {
                "barrier_count": randi_range(1, 2),
                "barrier_size": randi_range(5, 10),
                "opening_count": randi_range(1, 3),
                "opening_types": ["Furt", "Pass", "Treppe"]
            }
        "Wald":
            return {
                "barrier_count": randi_range(3, 5),
                "barrier_size": randi_range(8, 15),
                "opening_count": randi_range(1, 2),
                "opening_types": ["Pass", "Furt", "Tür"]
            }
        "Fels":
            return {
                "barrier_count": randi_range(5, 8),
                "barrier_size": randi_range(10, 20),
                "opening_count": randi_range(0, 1),
                "opening_types": ["Pass", "Treppe"]
            }
        "Wasser":
            return {
                "barrier_count": randi_range(0, 1),
                "barrier_size": randi_range(15, 30),
                "opening_count": randi_range(1, 2),
                "opening_types": ["Furt"]
            }
        "Sand":
            return {
                "barrier_count": randi_range(1, 2),
                "barrier_size": randi_range(6, 12),
                "opening_count": randi_range(1, 3),
                "opening_types": ["Pass", "Furt"]
            }
        _:
            return {
                "barrier_count": 1,
                "barrier_size": 8,
                "opening_count": 1,
                "opening_types": ["Pass"]
            }
```

---

## Erweiterungen

### Neue Biome hinzufügen
1. **Neues Biom definieren:**
   - Name, Beschreibung, Farbe.
   - Barrierendichte, typische Barrieren, Öffnungs-Häufigkeit.
2. **Biom-Parameter anpassen:**
   - `get_biome_params()` erweitern.
3. **Texturen hinzufügen:**
   - Neue Kacheln für das Biom in Godot importieren.

### Biom-spezifische Objekte
- **Grasland:** Blumen, Pilze.
- **Wald:** Bäume, Sträucher, Totholz.
- **Fels:** Steine, Kristalle.
- **Wasser:** Algen, Seerosen.
- **Sand:** Kakteen, Dünen.

---

## Links

- [Godot OpenSimplexNoise](https://docs.godotengine.org/en/stable/classes/class_opensimplexnoise.html)
- [Voronoi-Diagramm Algorithmen](https://en.wikipedia.org/wiki/Voronoi_diagram)
- [Perlin Noise Erklärung](https://adrianb.io/2014/08/09/perlinnoise.html)
