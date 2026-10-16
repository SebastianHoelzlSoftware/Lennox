# AI/README – Synchronisationsrichtlinien für KI-Unterstützung

## Hintergrund

Dieses Dokument definiert die Richtlinien für die Arbeit mit diesem Repository, um Konflikte zwischen lokalen Änderungen (VS Code) und Änderungen durch die KI (Vibe Handheld App) zu verhindern.

---

## Das Problem

**Ursache:**
- Commits werden von zwei verschiedenen Umgebungen aus erstellt:
  1. **Lokale Umgebung:** VS Code auf deinem PC (`C:\Users\sebas\Documents\Lennox`)
  2. **KI-Umgebung:** Vibe Handheld App (diese KI-Sitzung)
- Beide Umgebungen arbeiten auf demselben Branch (`main`), ohne korrekte Synchronisation.
- Dies führt zu:
  - Merge-Konflikten
  - Über Schreiben von Änderungen
  - Unerwarteten Commit-Histories
  - "Detached HEAD" Zuständen

**Beobachtetes Verhalten:**
- Die Git-History zeigt Commits, die nicht korrekt synchronisiert wurden (z.B. `Merge branch 'main' of https://github.com/...`)
- Änderungen in der KI-Umgebung erscheinen nicht in deiner lokalen Umgebung
- Umgekehrt gehen lokale Änderungen verloren, wenn die KI pushen

---

## Verpflichtende Arbeitsabläufe

### 1. Vor jedem KI-Arbeitsauftrag

**Immer ausführen (in dieser Reihenfolge):**

```bash
# 1. Aktuellen Status prüfen
git status

# 2. Alle entfernten Änderungen holen (origin = github.com/SebastianHoelzlSoftware/Lennox)
git fetch origin

# 3. Aktiven Branch prüfen (MUSS main sein)
git branch

# 4. Lokale Änderungen committen ODER stashen
#    Option A: Commiten
git add .
git commit -m "lokal: [Beschreibung]"
git push origin main

#    Option B: Stashen (wenn Änderungen noch nicht fertig)
git stash push -m "wip: [Beschreibung]"

# 5. Mit entferntem Branch synchronisieren
git pull origin main

# 6.Stash wieder anwenden (falls Option B)
git stash pop
```

### 2. Während der KI-Arbeit

**KI DARF NUR arbeiten, wenn:**
- [ ] Der lokale Branch aktuell ist (`git pull` wurde ausgeführt)
- [ ] Alle lokalen Änderungen entweder committed ODER gestashed sind
- [ ] Keine ungemergten Changes existieren (`git status` muss clean sein)

**KI MUSS:**
- Vor jedem Schreibvorgang die Datei lesen
- Nach jedem Schreibvorgang die Änderungen verifizieren
- NIE direkt pushen ohne Bestätigung

### 3. Nach KI-Änderungen

**Vor dem Push:**

```bash
# 1. Alle Änderungen prüfen
git diff

# 2. Geänderte Dateien zum Commit vorbereiten
git add [Dateien...]

# 3. Commit mit klarer Nachricht
git commit -m "ki: [Beschreibung der Änderungen]"

# 4. Push mit Force-Only-Lease (sicherer als --force)
git push --force-with-lease origin main
```

**Wichtig:**
- NIE `git push --force` verwenden (kann Remote-Änderungen überschreiben)
- IMMER `--force-with-lease` bevorzugen (prüft, ob Remote unverändert ist)

---

## Synchronisations-Checkliste für die KI

- [ ] **Status prüfen:** `git status` ausführen
- [ ] **Fetch:** `git fetch origin` ausführen
- [ ] **Branch prüfen:** Muss `main` sein, nicht detached
- [ ] **Lokale Änderungen:** Entweder committed oder gestashed
- [ ] **Pull:** `git pull origin main` ausführen
- [ ] **Konflikte lösen:** Falls Konflikte, manuell lösen
- [ ] **Arbeiten:** Erst jetzt mit Änderungen beginnen
- [ ] **Verifizieren:** `git diff` nach Änderungen prüfen
- [ ] **Commit:** Klare Commit-Nachricht mit Präfix (`ki:` oder `lokal:`)
- [ ] **Push:** Nur mit `--force-with-lease`

---

## Commit-Nachrichten Konvention

| Präfix | Bedeutung | Beispiel |
|--------|-----------|----------|
| `ki:` | Änderung durch KI | `ki: fix indentation in chunk.gd` |
| `lokal:` | Lokale Änderung (VS Code) | `lokal: add new barrier type` |
| `docs:` | Dokumentation | `docs: update procedural map gen` |
| `test:` | Tests | `test: add unit tests for barrier` |
| `fix:` | Bugfix | `fix: ray-casting algorithm` |
| `feat:` | Neues Feature | `feat: add opening system` |

---

## Notfallprozeduren

### Fall 1: Merge-Konflikt

```bash
# 1. Konflikt erkennen
git status  # Zeigt "Unmerged paths"

# 2. Konflikte manuell lösen (Dateien öffnen und <<<<<<< >>>>>> markierungen entfernen)

# 3. Konflikte als gelöst markieren
git add [konflikt-datei]

# 4. Commit
git commit -m "merge: resolve conflict in [Datei]"

# 5. Push
git push origin main
```

### Fall 2: Detached HEAD

```bash
# 1. Aktuellen Branch prüfen
git branch

# 2. Zu main zurückkehren
git checkout main

# 3. Synchronisieren
git pull origin main
```

### Fall 3: Falscher Commit gepusht

```bash
# 1. Letzten Commit rückgängig machen (lokal)
git reset --soft HEAD~1

# 2. Änderungen korrigieren

# 3. Neuer Commit
git commit -m "ki: corrected [Beschreibung]"

# 4. Force-Push mit Lease
git push --force-with-lease origin main
```

---

## Verbotene Aktionen

- ❌ `git push --force` (ohne `--with-lease`)
- ❌ Direkter Push ohne vorherigen `git pull`
- ❌ Arbeiten auf nicht-synchronisiertem Branch
- ❌ Ändern von Dateien ohne vorheriges Lesen
- ❌ Commits ohne klare Nachricht
- ❌ Arbeiten mit ungemergten Changes

---

## Automatisierte Prüffragen für die KI

**Vor jedem Schreibvorgang:**
1. "Habe ich die Datei in dieser Sitzung bereits gelesen?"
2. "Gibt es ungemergte Änderungen?" (→ `git status`)
3. "Bin ich auf dem korrekten Branch?" (→ `git branch`)

**Vor jedem Commit:**
1. "Habe ich alle Änderungen mit `git add` gestaged?"
2. "Ist die Commit-Nachricht klar und folgt der Konvention?"

**Vor jedem Push:**
1. "Habe ich `git pull` ausgeführt?"
2. "Verwende ich `--force-with-lease` statt `--force`?"

---

## Verantwortlichkeiten

| Aufgabe | Verantwortlich | Tool |
|---------|---------------|------|
| Lokale Änderungen verwalten | User (Sebastian) | VS Code |
| KI-Änderungen erstellen | KI (Vibe) | Vibe App |
| Synchronisation sicherstellen | **BEIDE** | Git CLI |
| Konfliktlösung | User (Sebastian) | VS Code |
| Commit-Nachrichten | Derjenige, der commited | - |

---

## Quick Reference Commands

```bash
# Status prüfen
git status

# Alles synchronisieren
git fetch origin && git pull origin main

# Lokale Änderungen committen
git add . && git commit -m "lokal: [Nachricht]"
git push origin main

# KI-Änderungen committen (nach Verifizierung)
git add . && git commit -m "ki: [Nachricht]"
git push --force-with-lease origin main

# Notfall: Alles zurücksetzen (VORSICHT!)
git reset --hard origin/main
git clean -fd
```

---

*Dieses Dokument wurde erstellt, um zukünftige Synchronisationsprobleme zu vermeiden. Bei Fragen oder Unklarheiten, frage nach Klärung, bevor du Änderungen commited oder pushst.*
