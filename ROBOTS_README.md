# Instructions for AI assistants

This file describes how an AI assistant should work in the Lennox repository. Follow the user's current request first, preserve existing work, and keep changes within the requested scope.

## Project at a glance

Lennox is a 2D educational game for helping children learn to read in English and Spanish. It is built with Godot 4 and GDScript.

- `src/core/` contains the game-domain code: levels, chunks, biomes, tiles, barriers, and openings.
- `test/unit/` contains GUT unit tests; `test/integration/` contains integration tests.
- `test/fixtures/` contains test fixtures.
- `doc/` contains focused design and implementation documentation.
- `addons/gut/` is the GUT test framework. Do not modify vendored addon code unless the task specifically concerns it.
- `project.godot` is the Godot project configuration.

Read the relevant implementation, tests, and documentation before changing behavior. Treat the code as authoritative when older documentation disagrees with it, and update directly related documentation when behavior or architecture changes.

## Project services and credentials

- Jira project: `LEN` on `https://devhoelzlsebastian.atlassian.net`; use issue keys such as `LEN-18`.
- GitHub repository: `https://github.com/SebastianHoelzlSoftware/Lennox`.
- Use the configured Jira/GitHub integrations when available. Do not look up, print, copy, or put credentials, tokens, or `.env` contents in source files, documentation, logs, or messages.
- Do not change Jira issues, comments, or statuses unless the user explicitly asks for that change. Work on an issue does not by itself authorize closing or rewriting it.

## Local environment

Use a Godot 4.6-compatible executable for this project; `project.godot` declares Godot 4.6 features. Prefer the executable already configured in the local editor or available in the environment. In the current Windows workspace, `bin\Godot_v4.6.3-stable_win64_console.exe` is available at the repository root; use it for headless validation if Godot is not on `PATH`.

Godot binaries and generated editor data are local tooling, not project source. The repository ignores `.godot/` and `/bin/`; never force-add those directories or commit engine executables. Do not copy an executable into the repository unless the user explicitly requests it.

### Map and TileSet notes

- The current demo scene is `scenes/main.tscn` with logic in `scenes/main.gd`. It generates 12x12 chunks, each 32x32 tiles, using seed `12345`.
- `Level.biome_map` is indexed `[x][y]`; chunk biome is `chunk.biome`. Biome enums are in `src/core/biome_type.gd`; tile enums are in `src/core/tile_type.gd`.
- The demo starts the player in the connected `GRASSLAND` region nearest the map center and selects a walkable `TileType.GRASS` cell in its center chunk.
- `scenes/main.tscn` uses `assets/tiles/rocks/rocks_16x16.tres`, a combined 16x16-pixel TileSet with named atlas sources including `Objects` and `Ground_rocks`. Keep this distinct from the per-sheet `.tres` files under `assets/tiles/rocks/tilesets/`; scene integration tests should use the combined resource.
- Named object resources are in `assets/tiles/rocks/tile_object_library.tres`; `TileObjectLibrary.get_pattern()` returns explicit patterns or lazily creates a pattern from `atlas_groups`. Group names like `objects_r04_c08` identify connected atlas coordinates, not guaranteed semantic objects; inspect the source texture before selecting one. `bone_fragment` is a hand-authored 2x3 object.
- The scene has a separate `ObjectTileMap` over the terrain layer. Current grass-biome decoration is intentionally temporary pending LEN-34: it tries 2-4 seed-derived patterns per grass chunk, restricts every footprint cell to `TileType.GRASS`, tracks occupied cells, and leaves a 5x5 spawn clearing. Placement attempts can skip objects when a chunk has no suitable space.
- `test/unit/test_main_object_layer.gd` covers the scene's terrain restrictions and distribution. The latest full suite has 68 GUT tests (60 unit, 8 integration); update the README count when changing tests.

## Design and implementation guidelines

- Keep the experience appropriate for children learning to read in English and Spanish: prioritize clarity, readable text, predictable interactions, and supportive feedback.
- Design for a 2D mobile game and touch input. Keep controls and important content legible at small screen sizes; avoid relying on color alone to communicate meaning.
- Follow established project patterns and keep changes focused. Prefer small, understandable GDScript changes over unnecessary abstractions.
- Use descriptive names and static types where practical, consistent with neighboring code. Follow `.editorconfig` and the GDScript settings in `.vscode/settings.json` for formatting.
- Keep game logic testable and separate from scene/UI concerns where the existing architecture does so.
- Do not invent new design or architecture conventions when the existing implementation or docs already establish one. Ask the user when a significant product or design decision is unresolved.

## Test-driven workflow

Use GUT, which is included in `addons/gut/`.

1. Inspect the relevant code and tests, then identify the expected behavior.
2. Add or update a focused test that captures the expected behavior.
3. Run that test and confirm it fails for the intended reason when practical.
4. Implement the smallest change that makes it pass.
5. Run the focused test, then the broader relevant suite; report any tests that could not be run.
6. Review the final diff and update related documentation.

The full suite can be run headlessly from the repository root (with `godot` available on `PATH`):

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gprefix=test_ -gexit -gjunit_xml_file=res://latest_test_output.xml
```

With the checked-in local Windows executable, PowerShell can run the suite without `godot` on `PATH`:

```powershell
& '.\bin\Godot_v4.6.3-stable_win64_console.exe' --headless --path '.' -s 'addons/gut/gut_cmdln.gd' '-gdir=res://test' -ginclude_subdirs -gprefix=test_ -gexit -gjunit_xml_file=res://latest_test_output.xml
```

Use `-gprefix=test_` so GUT discovers the repository's `test_*.gd` files; `-gdir=res://test` alone does not select these scripts under the default filename prefix. For a focused test, replace the directory flags with, for example, `'-gtest=res://test/unit/test_main_object_layer.gd'`.

When `-gjunit_xml_file=res://latest_test_output.xml` is supplied, GUT writes a JUnit report there. This is generated output and is ignored by Git; do not edit it by hand or treat an old report as evidence for a new run. When reporting test results, state which command/scope was run and whether it passed.

## Work, documentation, and approval rules

- Before editing, inspect `git status` and the target files. Preserve unrelated, uncommitted changes; do not overwrite or discard them.
- Do not commit, push, force-push, reset, clean, or stash user changes unless the user specifically asks. Never use destructive Git commands as a shortcut to resolve uncertainty.
- Update local documentation only when it is part of the user's request or is directly needed to keep it accurate after an implementation change. Keep additions relevant and consistent with the existing language and structure of the document.
- A request naming a specific document or Jira checklist authorizes edits to that requested scope. Before changing other documents, expanding the scope, or making additional Jira changes (including status transitions), explain the proposed change and ask the user for approval.
- Do not mark a Jira task complete just because code or documentation was changed. First verify its stated acceptance criteria and relevant tests. If authorized to update Jira, make the smallest accurate update and include a concise summary, verification performed, and any remaining work.
- At the end, summarize the files changed, tests run and results, and any known follow-up. Ask before performing any further task or documentation updates outside the authorized scope.
