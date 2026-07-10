# rlchase

A terminal maze-chase game written entirely in [rl-lang](https://github.com/rl-lang) - built as a dogfooding exercise to stress-test the language's parser, stdlib, and terminal I/O.

Dodge wandering hunters, sidestep death tiles, grab pellets, and hunt down the elusive bonus target before your enemies catch you. Survive long enough and the maze gets meaner.

## Demo

[![asciicast](https://asciinema.org/a/Pmy1Uy3XwZmfG0SW.svg)](https://asciinema.org/a/Pmy1Uy3XwZmfG0SW)

## Features

- **Procedurally generated levels** - walls, danger tiles, enemies, pellets, and power-ups are randomized every run, with density scaling as you climb levels.
- **Chasing enemies** - hunters path toward you most of the time, with just enough randomness to keep them from feeling robotic.
- **Wandering bonus target** - a high-value target (`*`) that moves on its own, worth more than a standard pellet but harder to pin down.
- **Power-ups** - grab a `!` to freeze all enemies in place for a few of your moves.
- **Persistent stats** - best level reached, games played, wins, and losses are saved locally and shown on the main menu.
- **Full color terminal UI** - distinct colors per entity type, plus a screen-transition sweep between menu and gameplay.
- **Difficulty scaling** - more walls, more danger tiles, more enemies, and a higher score requirement each time you level up.

## Controls

| Key | Action |
|---|---|
| Arrow keys | Move |
| Enter / Space | Confirm menu selection |
| Ctrl+M / M | Back to menu |
| Ctrl+C | quit |

## How to play

1. From the main menu, select **start**.
2. Move around the maze with the arrow keys.
3. Collect pellets (`o`) and the bonus target (`*`) to raise your score.
4. Avoid enemies (`E`) and danger tiles (`x`) — touching either ends the run.
5. Grab a power-up (`!`) to freeze enemies temporarily if you're cornered.
6. Reach the level's score goal to advance to the next, harder level.
7. Winning increases your level and updates your best-level record; dying resets you back to level 1.

## Legend

| Symbol | Meaning |
|---|---|
| `@` | You |
| `E` | Enemy - Normal type |
| `e` | Enemy - Wanderer type |
| `C` | Enemy - Chaser type |
| `x` | Danger tile (instant death) |
| `#` | Wall |
| `o` | Pellet (+1 score) |
| `!` | Power-up (freezes enemies) |
| `*` | Bonus target (+3 score, moves on its own) |

## Running the game

```sh
rl run rlchase.rl
```

Requires a terminal that supports raw mode, the alternate screen buffer, and ANSI color/attribute codes.

## Stats file

Progress is saved locally next to the game binary:

- `rlchase.save` - highest level reached, total games played, total wins, total losses

Delete these files to reset your stats.

## Built with

- [rl-lang](https://github.com/rl-lang) - a statically-typed, interpreted language written in Rust
- `std::term` for raw-mode terminal control, cursor movement, and color
- `std::random` for procedural level generation
- `std::io` / `std::path` for stat persistence

## Roadmap

- [ ] Reachability check so the goal/pellets can never spawn behind a sealed wall cluster
- [ ] Second enemy tier with different movement behavior
- [ ] Fade-in transition to complement the current fade-out sweep
- [ ] Retry-without-menu on death
- [ ] Death-cause messaging (caught vs. stepped on danger tile)


## License

[MIT](LICENSE).
