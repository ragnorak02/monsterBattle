# Art Assets — Monster Catcher

Shopping list for visual assets. Specs and sources for upgrading placeholder art.

---

## Current Inventory

| Asset | Type | Spec | Status |
|-------|------|------|--------|
| Player spritesheet (boy/girl) | 4x4 directional walk | 16x16 per frame | Done |
| NPC default | 3-frame sprite | 16x16 per frame | Placeholder |
| 30 monster PNGs | Front-facing portraits | Various sizes, scaled 0.5x in overworld | Done |
| Town tileset | 8-tile atlas (grass, path, water, tree, wall, roof, fence, flowers) | 16x16 per tile | Done |
| Route tileset | 3-tile atlas (grass, path, tree) | 16x16 per tile | Placeholder |
| Chat bubble | UI element | 9-patch | Done |

---

## Needed Assets (by priority)

### High Priority

**NPC Variety Sprites**
- 3-4 distinct NPC character sprites (shopkeeper, elder, trainer, kid)
- 16x16 per frame, 3-frame idle (same format as current npc_default)
- Style: top-down pixel art matching player spritesheet

**Route Tileset Upgrade**
- Replace 3-tile placeholder with full tileset (8+ tiles)
- Tiles: grass, tall grass, dirt path, rock, bush, water, bridge, sign
- 16x16 per tile, same atlas layout as town tileset

**Overworld Monster Spritesheets**
- 4-frame walk cycle per monster (or at minimum 2-frame idle bounce)
- 16x16 or 32x32 per frame, scaled to match overworld
- Priority: starter monsters first (IDs 1-3)

### Medium Priority

**Animated Tileset Tiles**
- Water shimmer: 3-4 frame animation on water tile
- Grass sway: 2-frame animation on tall grass
- Flowers: 2-frame gentle sway
- Implementation: TileSet animation API (code ready, needs art frames)

**Battle VFX Sprites**
- Hit spark (3-4 frames)
- Critical hit flash (3-4 frames)
- Status effect icons (poison bubbles, burn flames, paralysis sparks)
- Catch ball throw arc + shake animation frames
- 16x16 or 32x32 per frame

### Low Priority

**UI Elements**
- Custom HP bar segments (replacing ColorRect)
- XP bar sprites
- Menu panel 9-patch backgrounds
- Type icons (Fire, Water, Grass, etc.) — 8x8 or 16x16

**Environment Decorations**
- Interior tileset (house/shop/gym floors, walls, furniture)
- Cave tileset (rock, stalagmite, dark floor, crystal)
- Weather overlays (rain drops, snow particles, fog gradient)

---

## Free Asset Sources

| Source | URL | Notes |
|--------|-----|-------|
| OpenGameArt | https://opengameart.org | CC0/CC-BY, large RPG tileset library |
| itch.io | https://itch.io/game-assets/free/tag-pixel-art | Many free packs, check license per asset |
| Kenney.nl | https://kenney.nl/assets | CC0, excellent quality, limited RPG sets |
| LPC (Liberated Pixel Cup) | https://lpc.opengameart.org | Standardized character generator sprites |

---

## Search Terms

- `16x16 rpg tileset pixel art`
- `top-down pixel monster sprites`
- `pixel art character walk cycle 16x16`
- `rpg battle effects pixel art`
- `pokemon style pixel monsters free`
- `2d rpg tileset town village`
- `pixel art vfx spritesheet hit spark`

---

## Specs

All assets must follow these rules:

- **Tile size:** 16x16 pixels
- **Filtering:** Nearest neighbor (no smoothing)
- **Scale:** Integer scale compatible (2x → 32x32 on screen at 640x360)
- **Format:** PNG with transparency
- **Atlas layout:** Horizontal strip preferred (matches TileSetAtlasSource)
- **Color depth:** 32-bit RGBA
- **Palette:** No strict palette enforced, but maintain consistent saturation/value range

---

## Future: Water Shimmer / Grass Sway

Requires additional animation frames in tileset PNGs. Code implementation is ~10 lines using TileSet animation API. Deferred until art frames are provided.

Example code pattern (for reference when art is ready):
```gdscript
# On TileSetAtlasSource, set animation columns and speed:
source.set_tile_animation_columns(atlas_coords, frame_count)
source.set_tile_animation_speed(atlas_coords, 4.0)  # FPS
```
