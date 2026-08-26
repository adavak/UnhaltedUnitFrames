## V12.1.3
- Noise debuffs (Sated, Exhaustion, Temporal Displacement, etc.) are now automatically excluded from every debuff container that is not backed by explicit SpellIDs.
- New candidate filters that filter strings cannot express:
  - Buffs: Boss Auras, Stealable.
  - Debuffs: Others (Not You), Dispel Types (Magic / Curse / Disease / Poison / Bleed).
- Hidden filters: tokens can now be hidden per container (Player / Others). Hidden tokens are excluded from every matching group, including the automatic defaults.

## V12.1.2
- Aura containers with no filters configured now filter automatically:
  - Buffs: auras cast by the player on friendly units; important auras (Big Defensive, External Defensive, Raid in Combat, Important) on hostile units.
  - Debuffs: shown on hostile units; always visible on player / party / raid frames.
  - Friendly / hostile is determined per frame by can-assist.

## V12.1.1
- Complete zhCN localization.
- Update embedded libraries.

## V12.1.0
- Add Party / Raid Frames.
- Add Dedicated Augmentation Raid Frames.
  - Define rendered frames by Unit Name.
  - All Settings from Raid Frames are supported yet separated.
- Indicators:
  - Added: Ready Check.
  - Added: Resurrect.
  - Added: Threat.
  - Added: Phase.
  - Added: Role.
  - Added: Summon.
  - Fixed: Highlight / Target Overlays breaking when making changes.
- Tags
  - Healer Mana & Healer Mana with Sign.
  - `perhp` tag has been redefined to support statuses.
  - Move to localised `DEAD`.
- Power Bar has `Only Show Healer Mana` option.
- Test Environment Rework.
- Dead & Offline Backdrop Colour.
- Heal Absorbs will reverse grow when selecting `Attach to Missing Health`.
- Added `Unhalted Unit Frames` to Main Menu.
- Added `Interrupt on Cooldown` Colour for Cast Bars.