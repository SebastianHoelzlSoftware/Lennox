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

Use a Godot 4.6-compatible executable for this project; `project.godot` declares Godot 4.6 features. Prefer the executable already configured in the local editor or available in the environment.

Godot binaries and generated editor data are local tooling, not project source. The repository ignores `.godot/` and `/bin/`; never force-add those directories or commit engine executables. Do not copy an executable into the repository unless the user explicitly requests it.

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
godot --headless --path . --script addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit -gjunit_xml_file=res://latest_test_output.xml
```

The command writes a JUnit report to `latest_test_output.xml`. This is generated output and is ignored by Git; do not edit it by hand or treat an old report as evidence for a new run. When reporting test results, state which command/scope was run and whether it passed.

## Work, documentation, and approval rules

- Before editing, inspect `git status` and the target files. Preserve unrelated, uncommitted changes; do not overwrite or discard them.
- Do not commit, push, force-push, reset, clean, or stash user changes unless the user specifically asks. Never use destructive Git commands as a shortcut to resolve uncertainty.
- Update local documentation only when it is part of the user's request or is directly needed to keep it accurate after an implementation change. Keep additions relevant and consistent with the existing language and structure of the document.
- A request naming a specific document or Jira checklist authorizes edits to that requested scope. Before changing other documents, expanding the scope, or making additional Jira changes (including status transitions), explain the proposed change and ask the user for approval.
- Do not mark a Jira task complete just because code or documentation was changed. First verify its stated acceptance criteria and relevant tests. If authorized to update Jira, make the smallest accurate update and include a concise summary, verification performed, and any remaining work.
- At the end, summarize the files changed, tests run and results, and any known follow-up. Ask before performing any further task or documentation updates outside the authorized scope.
