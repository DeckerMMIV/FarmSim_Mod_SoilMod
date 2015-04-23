# Farming Simulator modification - SoilMod

To read more about this mod, find it on http://fs-uk.com - http://fs-uk.com/mods/search/soil%20management


## Changes since SoilMod for FS2013

A quick rundown of the SoilMod-FS15 changes compared to SoilMod-FS2013:

- Two foliage-layers; one for 'visibles' and one for 'non-visible' (both same width/height as fruit_density.grle)
- Soil pH increased to use 4-bits, so lower level-change between steps
- Fertilizer concept changed to Nutritions N+PK
- Nutritions N+PK (4- & 3-bits) is affected by fertilizers and crop growth
- 3 fertilizer spray-types that increase; NPK, PK or N. Manure/slurry also adds N+PK.
- Soil moisture added (3 bits), which weather will affect (high temperature or rain)
- 3 extra herbicide spray-types that adds germination prevention (lasts 4 growth-cycles)
- Crop yield during harvest, will be affected by pH level, remaining nutrition N+PK levels, soil moisture and weeds
- Two distinct types of weed, and their patches not so square


## Effects

*As of version 2.0.27*

- Crops, from 2nd growth and up to withered (growth stages 3-8);
  - when plowed adds; +5 N, +1 PK
  - when cultivated adds; +2 N
- Swath/windrows; 
  - when plowed adds; +3 N
  - when cultivated adds; +1 N
  - at growth-cycle; decreased by 1 height
- ChoppedStraw (extra mod required) [since 2.0.27]
  - when cultivating adds; +1 N
  - when plowing chopped-maize haulm adds; +2 N, +2 PK
  - when plowing chopped-rape haulm adds; +2 N, +1 PK
  - when plowing chopped-straw adds; +1 N, +1 PK
  - when seeding; straw is removed, with no additional effects
- Manure; 
  - when plowed adds; +12 N, +4 PK
  - when cultivated adds; +6 N, +2 PK
  - unprocessed at growth-cycle; 
    - increase soil moisture by '1 internal level' [since 2.0.24]
    - decreased by 1 height
- Slurry; 
  - when plowed/cultivated; only visible graphics removed (Zunidisc bug pending #24)
  - at growth-cycle adds; +3 N
- Compost (extra mod required) [since 2.0.23];
  - when plowed adds; +3 N, +2 PK and increases soil pH by '1 internal level'
  - when cultivated adds; +1 N, +1 PK
  - unprocessed at growth-cycle; increase soil moisture by '1 internal level'
- Lime; 
  - when plowed/cultivated; increase soil pH by '4 internal levels'
  - at growth-cycle; increase soil pH by '3 internal levels'
- Fertilizer, both liquid and solid;
  - 'NPK' at growth-cycle adds; +3 N, +1 PK
  - 'PK' at growth-cycle adds; +3 PK
  - 'N' at growth-cycle adds; +5 N and decrease soil pH by '1 internal-level'
  - Please note that *before* the growth-cycle occurs then;
    - the last fertilizer type sprayed, will remove any other fertilizer type in the area, and
    - any of these fertilizers will remove Herbicide-X in the sprayed area.
- Herbicide;
  - at growth-cycle makes weeds withered and decrease soil pH by '1 internal level'
  - note that crops will be affected during growth-cycle if wrong herbicide is used;
    - when crop is at "blue" growth-stages; the crop will not growth
    - when crop is at "green" growth-stages; the crop becomes withered
  - usage of herbicide vs. crop types (hardcoded into script);
    - use type 'B' or 'C' on; wheat, barley, rye, oat, rice. (*Do not use type 'A'*)
    - use type 'A' or 'C' on; corn/maize, rape/canola, osr, luzerne, klee. (*Do not use type 'B'*)
    - use type 'A' or 'B' on; potato, sugarbeet, soybean, sunflower. (*Do not use type 'C'*)
- Herbicide-AA/BB/CC; does the same as herbicide-A/B/C, but also adds 3 extra days of weed-germination prevention (which does not affects crops)
- Herbicide-X [since 2.0.29]
  - This will cause all plants to be destroyed at the next growth-cycle.
  - Please note that *before* the growth-cycle occurs then;
    - spraying Herbicide-X will remove any of the fertilizers in the sprayed area.
- Spray moisture / "dark texture" (from liquid fertilizer/herbicide/slurry/water);
  - at growth-cycle; increases soil moisture by '1 internal-level'
- Water (explicit spraying of water or due to plowing);
  - at growth-cycle;
    - when area was plowed and NOT afterwards sprayed with water; decreases soil moisture by '1 internal level'
    - else; increases soil moisture by '1 internal level'
- Weather conditions;
  - at noon 12:00 o'clock and temperature above 22 degrees; decreases soil moisture by '1 internal level'
  - when raining and at every whole hour; increase soil moisture by '1 internal level'

### Growth of crops

During a growth-cycle, crops with cause the following effects:

- When at stages 1-7; consumes 1 N
- When at stages 3 & 5; consumes 1 PK
- When at stages 2, 3 & 5; decrease soil moisture by '1 internal level'
- When at stage 3; decrease soil pH by '1 internal level'
- Fully grown weeds become withered if there is zero N in soil
- Weeds (if not withered) consume 1 N and soil moisture
 
 
## Change-log

2.0.29
- Added a 'Herbicide-X' spray-type, which will remove all crops (including grass) at the next growth-cycle.
  - Except if fertilizer (NPK, PK, N) was sprayed in the same area afterwards.
- Hiding SoilMod's info-panel, when vehicle info also is.

2.0.27
- Added effects to chopped-straw.
- Removed the following rule due to possibly conflicting mods; "if 'kalk' is already one of accepted spray-types on spreader/sprayer, then do not add the ones from SoilMod"
- The 'Grow NOW!' action changed to a press-and-hold (2 sec.), before it activates. (Still only available on the server.)
- For multiplayer, attempted to inform clients of days before next growth-cycle.

2.0.26
- Registering spray-types before the map.i3d is loaded.

2.0.25
- Ability to use a map's own icons for spray-types, if found in `<mapMod>/fruitHuds` folder.
  - Filenames: `hud_spray_<fillname>.dds` and `hud_spray_<fillname>_small.dds`
- Added support for `ModsSettings` mod, for player-local configurable parameters.
  - SoilMod's info-panel is now a little bit easier to customize the position of.
- Removed SoilMod's spray-/fill-types from 'economy'.
- Tweaked fertilizer/herbicide prices, usage-per-sqm and mass.
- Spanish translation by Alfredo Prieto.
- Some file-extension renames, due to DedicatedServerSoftware issues warnings of too many .TXT/.PNG files.

2.0.24
- Manure left unprocessed will increase soil moisture.

2.0.23
- Added support for 'compost'.
- Polish translation updated by Ziuta.

2.0.22
- First public release.
