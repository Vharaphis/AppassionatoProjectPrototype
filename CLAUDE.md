# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot **4.7** (Forward+, Jolt Physics, D3D12 on Windows) prototype written in GDScript. No build system or linter: the project is run from the Godot editor (F5). Main scene is `scenes/cardManagementScene.tscn`.

Tests are plain assert scripts in `tests/`, run headless: `godot --headless --script res://tests/test_spawn_table.gd` (prints `OK`). Open the project in the editor once after adding a `class_name`, so the global class cache knows it.

The game is a rhythm/deckbuilder hybrid: the player arranges cards on a track, then a 3D arena fight runs where the cards are played automatically in a loop, on tempo, while enemies spawn.

Code comments and UI strings are mixed French/English; match the language of the file you edit.

## Gameplay loop (scene flow)

`cardManagementScene` (preparation) → `fightingEnemiesScene` (combat) → `rewardScene` → back to preparation. Scenes switch with `get_tree().change_scene_to_file()` using path constants at the top of each scene script. On defeat, `RunState.reset_run()` and back to preparation.

Everything that must survive a scene change lives in the **`RunState` autoload** (`scripts/run/run_state.gd`, declared as a scene `scenes/run/runState.tscn` so its `Deck` child and reward pool are editable in the inspector; it intentionally has no `class_name`). It holds the deck, player HP, round index, per-round difficulty formulas, the reward pool, and `card_sequence` (the cards locked on the track, handed from preparation to combat).

Card conservation matters: cards leaving the hand/track must go back to `deck.discard()` (see `_discard_remaining_hand` and `RunState.discard_sequence`), otherwise the deck drains over rounds and soft-locks.

## Card system

- **`CardData`** (`Resource`, `.tres` in `scenes/cards/`): authored, shared, saved on disk — never mutate at runtime. `temporality` is a string of `o` (play) / `x` (cooldown) slots.
- **`CardInstance`** (`RefCounted`): runtime wrapper created by `Deck.draw_card()`; per-run changes go in its `*_override` fields or `state`. Note the `Deck` piles store `CardData`, so instance state is lost on discard.
- **`CardEffect`** / **`TargetSelector`**: `@abstract` Resources composed in the inspector (e.g. `DamageEffect` + `ClosestTargets`, `ArmorEffect`). New card behavior = new effect/selector subclass, not hand-coded cards.

## Combat architecture (`fightingEnemiesScene`)

Nodes are decoupled via signals and `@export` references; the scene script (`scenes/fighting_enemies_scene.gd`) wires them and drives the UI:

- **`CardReader`**: pure timing logic. Advances one slot every `60/bpm * beats_per_slot` seconds using an accumulator (not a Timer), emits `slot_entered` / `card_played` / `loop_completed`. Re-reads temporality each slot so it can change mid-combat.
- **`CombatRuntime`**: listens to `card_played`, refreshes a shared **`EffectContext`** (player, enemies, level, reader, source card, previous card, `effect_multiplier`) and calls `effect.execute(ctx)`. Effects should use `ctx.scale_amount()` for numbers.
- **Enemies**: an enemy type = `EnemyData` (stats + scene, `.tres` in `scenes/enemies/`) + a scene whose `Enemy` root has an `EnemyBehavior` child (movement, e.g. `ChaseBehavior`). `EnemySpawner` picks from a `SpawnTable` of `SpawnEntry` weighted by round (`RunState.round_index`, or `round_override`) and injects `enemy.data` before `add_child`. Adding an enemy = new data/scene/behavior + a table entry, no spawner change.
- **`CombatObjective`**: counts deaths of enemies spawned by `EnemySpawner`, emits `completed`.
- **`HealthComponent`** (`scripts/components/`): shared by player and enemies (HP, armor, invulnerability). Armor deliberately does not persist between rounds.
- **`Level`** (`@tool`): builds floor/walls from `arena_size`; `get_playable_rect()` is used for spawn clamping.

Physics layers: 1 = world, 2 = player, 3 = enemies. Input actions: `move_left/right/up/down` (WASD, arrows, left stick).

## Repo notes

- `.github/workflows/claude.yml` runs Claude Code on GitHub (installed via `/install-github-app`).
- `.graphify/` holds a generated knowledge graph of the codebase; `Claude outputs/` holds generated issue templates/drafts — neither is game code.
