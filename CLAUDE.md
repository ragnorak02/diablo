# DIABLO — Extraction Protocol  
Studio: AMARIS  
Game ID: diablo  
Engine: Godot 4.6  
Language: GDScript  
Rendering: Forward+  
Physics: Godot Physics  
Controller Required: YES  
Godot Path (MANDATORY): Z:/godot/godot.exe  

---

# 1. STUDIO CONTRACT (CRITICAL)

Diablo is part of the AMARIS multi-repo ecosystem.

Mandatory Files:
- CLAUDE.md → execution brain
- project_status.json → dashboard truth
- game.config.json → launcher contract
- test_results.json → test output (if used)
- achievements.json (if implemented)

Never duplicate completion % here.  
project_status.json is the single source of truth.

If checklist item does not apply → mark N/A. Never delete.

---

# 2. GODOT EXECUTION CONTRACT

Claude MUST use:

Z:/godot/godot.exe

Never:
- Use PATH
- Use console exe in Downloads
- Override launcher path in game.config.json
- Assume alternate engine install

Headless Boot:
Z:/godot/godot.exe --path . --headless --quit-after 1

Run Tests:
Z:/godot/godot.exe --headless --script res://tests/test_runner.gd

Exit Code:
0 = pass  
Non-zero = failure  

Tests must pass before commit.

---

# 3. GAME IDENTITY

Genre: Dark Fantasy Extraction ARPG  
Mode: PvE + PvP  
Core Loop:

Town → Cathedral → Procedural Dungeon  
Descend → Loot → Fight → Trophy → Physically Extract → Risk PvP → Return to Town  

Extraction is physical, not teleport-based.

---

# 4. WHAT MUST NOT BREAK

- Dungeon generation stability
- Extraction mechanic integrity
- PvP combat synchronization
- EventBus decoupling
- GameManager as state authority
- Test runner functionality
- Controller support
- Scene flow integrity
- project_status.json schema

---

# 5. CORE SYSTEM MAP

Autoloads:
- GameManager
- ItemDatabase
- EventBus
- AudioManager

Systems:
- DungeonGenerator
- PlayerController (3D)
- PlayerIso (2D)
- PvPManager
- ExtractionManager
- LootDrop
- HUD
- InventoryScreen
- InteractionZone

---

# 6. UNRESOLVED ARCHITECTURE DECISION

⚠ 2D/3D Split must be resolved.

- [ ] Decide: Full 3D conversion
- [ ] OR Commit to 2D isometric
- [ ] Remove unused branch
- [ ] Update camera logic accordingly
- [ ] Remove orphan scripts
- [ ] Run full regression test

This decision blocks polish phase.

---

# 7. MACRO PHASE STRUCTURE (AUTOMATION-READY)

---

## PHASE 1 — Foundation Integrity ✓

- [x] Boot headless successfully
- [x] Run all tests
- [x] Confirm 78/78 passing
- [x] Validate autoload initialization order
- [x] Validate no warnings in console
- [ ] Confirm controller works in Town + Dungeon (input actions mapped — needs manual verify)
- [x] Commit stable baseline

---

## PHASE 2 — Dungeon Generation Hardening

- [x] Validate procedural seed determinism
- [x] Add test for dungeon floor generation
- [x] Validate stair linking across floors
- [x] Validate enemy spawn boundaries
- [x] Validate loot spawn positions
- [x] Validate no softlocks
- [x] Stress test 20 floor transitions
- [ ] Commit + test

---

## PHASE 3 — Combat & PvP Stability

- [x] Verify damage events flow through EventBus
- [ ] Add test for player death state
- [ ] Add test for enemy death state
- [ ] Add PvP duel scenario test
- [ ] Confirm no friendly-fire edge errors
- [x] Validate dodge i-frame timing
- [x] Validate skill cooldown logic
- [x] Confirm no double-hit bug
- [ ] Manual PvP playtest session

---

## PHASE 4 — Extraction Risk Loop Integrity

- [x] Verify extraction zone activation
- [x] Verify extraction interrupted by damage
- [x] Verify loot persists until extraction
- [x] Verify death drops loot
- [ ] Validate trophy item generation
- [ ] Confirm extraction resets dungeon state
- [ ] Add test: extract success
- [ ] Add test: extract interrupted
- [ ] Commit

---

## PHASE 5 — Inventory & Loot Economy

- [x] Validate defensive item copies
- [x] Validate rarity roll system
- [x] Validate inventory UI sync
- [ ] Add gold accumulation tracking
- [ ] Add sell mechanic
- [x] Add potion consumption logic
- [x] Confirm no mutation of registry items
- [ ] Add test for loot generation

---

## PHASE 6 — Vertical Slice Lock

- [ ] Full loop playable start → extract
- [ ] PvE + PvP scenario playable
- [ ] Boss encounter functional
- [ ] Extraction trophy reward visible
- [ ] No crash in 30-minute session
- [ ] All core systems stable
- [ ] Update project_status.json

---

## PHASE 7 — Performance & Determinism

- [ ] Profile CPU usage in dungeon
- [ ] Confirm no physics explosion
- [ ] Validate 60 FPS baseline
- [ ] Test 10 simultaneous enemies
- [ ] Confirm no memory growth across 3 runs
- [ ] Confirm deterministic floor transitions

---

## PHASE 8 — Audio Layer

- [ ] Add combat SFX
- [ ] Add extraction audio cue
- [ ] Add dungeon ambient loop
- [ ] Add PvP hit confirm sound
- [ ] Add volume controls
- [ ] Validate AudioManager lazy loading

---

## PHASE 9 — Visual Polish

- [ ] Replace primitive meshes
- [ ] Add hit impact VFX
- [ ] Add death dissolve effect
- [ ] Add damage numbers (camera-safe)
- [ ] Add screen flash on critical hit
- [ ] Add boss intro moment

---

## PHASE 10 — Pre-Release Stabilization

- [ ] Run headless test suite
- [ ] Manual 3 full-run test
- [ ] Validate extraction economy
- [ ] Validate PvP exploit absence
- [ ] Confirm no warnings
- [ ] Update project_status.json:
      - macro_phase
      - subphase
      - completion_percent
      - test status
      - timestamps
- [ ] Commit
- [ ] Push

---

# 8. CURRENT FOCUS

Current Goal: Phase 2 — Dungeon Generation Hardening
Current Task: Add seed determinism + dungeon generation tests
Work Mode: Development
Next Milestone: Phase 2 complete

---

# 9. AUTOMATION SEQUENCE (MANDATORY)

After major work:

1. Update project_status.json
2. Run:
   Z:/godot/godot.exe --path . --headless --quit-after 1
3. Run full test suite
4. Confirm no schema drift
5. Commit
6. Push

---

# END