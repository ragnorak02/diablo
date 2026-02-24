# Free CC0 / Open-Source Asset Sources

## 3D Models

### Characters & Enemies
- **Kenney Assets** (CC0) — https://kenney.nl/assets
  - Modular dungeon kit, character models, props
- **Quaternius** (CC0) — https://quaternius.com/packs
  - Fantasy characters, monsters, weapons, armor
- **Kay Lousberg** (CC0) — https://kaylousberg.itch.io/
  - Low-poly RPG characters, dungeon assets
- **Mixamo** (Free for Godot) — https://www.mixamo.com/
  - Character animations (walk, run, attack, dodge, death)

### Dungeon Environment
- **Kenney Dungeon Pack** (CC0) — https://kenney.nl/assets/dungeon-pack
  - Walls, floors, doors, stairs, torches
- **Dungeon Tileset** (CC0) — https://kenney.nl/assets/roguelike-dungeon
  - 2D alternative for minimaps

### Weapons & Items
- **Kenney Weapons** (CC0) — https://kenney.nl/assets/weapon-pack
- **Quaternius Weapons** (CC0) — https://quaternius.com/packs/ultimateweapons.html
- **Kenney Loot** (CC0) — https://kenney.nl/assets/loot-items

## Textures & Materials
- **Polyhaven** (CC0) — https://polyhaven.com/textures
  - PBR stone, metal, wood textures for dungeons
- **AmbientCG** (CC0) — https://ambientcg.com/
  - Ground, wall, material textures
- **Kenney Textures** (CC0) — https://kenney.nl/assets/prototype-textures

## Audio
- **Kenney Audio** (CC0) — https://kenney.nl/assets?q=audio
  - UI sounds, impacts, footsteps
- **Freesound** (CC0 tagged) — https://freesound.org/
  - Ambient dungeon sounds, combat SFX
- **OpenGameArt** (CC0/CC-BY) — https://opengameart.org/
  - RPG music, monster sounds, spell effects

## Fonts
- **Google Fonts** (OFL) — https://fonts.google.com/
  - MedievalSharp, Cinzel, UnifrakturMaguntia
- **Kenney Fonts** (CC0) — https://kenney.nl/assets/kenney-fonts

## Particles / VFX
- **Godot VFX Library** — https://github.com/GDQuest/godot-visual-effects
  - Spell effects, hit particles, ambient fog

## Integration Notes
- All placeholder meshes in this project use Godot primitives (capsules, boxes, spheres)
- Replace with actual models by updating the mesh references in each script's `_setup_mesh()` function
- Textures can be applied by creating materials and assigning to mesh surfaces
- Animations from Mixamo can be imported via .glb/.gltf and used with AnimationPlayer
