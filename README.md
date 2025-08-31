# mirror-lasers

Project scaffolded to the recommended Godot layout.

Structure created:

- scenes/
  - Main.tscn (entry scene)
  - Player.tscn
  - UI.tscn
  - levels/Level1.tscn
- scripts/
  - Main.gd
  - Player.gd
  - UI.gd
- assets/
  - audio/ (.gitkeep)
  - fonts/ (.gitkeep)

Notes:

- `project.godot` was left untouched.
- Replace the placeholder `.gitkeep` files in assets with real assets.
- Next: implement game-specific scenes (laser sources, mirrors, target) and the laser tracer logic in `scripts/`.
