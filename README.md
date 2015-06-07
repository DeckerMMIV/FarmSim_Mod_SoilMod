# Farming Simulator modification - SoilMod

To read more about this mod, find it on http://fs-uk.com - http://fs-uk.com/mods/search/soil%20management


## Effects

*As of version 2.0.31*

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
    - increase soil moisture by about 14% [since 2.0.24]
    - decreased by 1 height
- Slurry; 
  - when plowed/cultivated; only visible graphics removed (Zunidisc bug pending #24)
  - at growth-cycle adds; +3 N
- Compost (extra mod required) [since 2.0.23];
  - when plowed adds; +3 N, +2 PK and increases soil pH by about 0.2 pH
  - when cultivated adds; +1 N, +1 PK
  - unprocessed at growth-cycle; increase soil moisture by about 14%
- Lime; 
  - when plowed/cultivated; increase soil pH by about 0.8 pH
  - at growth-cycle; increase soil pH by about 0.6 pH
- Fertilizer, both liquid and solid;
  - 'NPK' at growth-cycle adds; +3 N, +1 PK
  - 'PK' at growth-cycle adds; +3 PK
  - 'N' at growth-cycle adds; +5 N and decrease soil pH by about 0.2 pH
  - Please note that *before* the growth-cycle occurs then;
    - the last fertilizer type sprayed, will remove any other fertilizer type in the area, and
    - any of these fertilizers will remove Herbicide-X in the sprayed area [since 2.0.30]
- Herbicide;
  - at growth-cycle makes weeds withered and decrease soil pH by about 0.2 pH
  - note that crops will be affected during growth-cycle if wrong herbicide is used;
    - when crop is at "blue" growth-stages; the crop will not growth
    - when crop is at "green" growth-stages; the crop becomes withered
  - usage of herbicide vs. crop types (hardcoded into script);
    - use type 'B' or 'C' on; wheat, barley, rye, oat, rice. (*Do not use type 'A'*)
    - use type 'A' or 'C' on; corn/maize, rape/canola, osr, luzerne, klee. (*Do not use type 'B'*)
    - use type 'A' or 'B' on; potato, sugarbeet, soybean, sunflower. (*Do not use type 'C'*)
- Herbicide-AA/BB/CC; 
  - does the same as herbicide-A/B/C, but also adds 3 extra days of weed-germination prevention (which does not affects crops)
- Herbicide-X [since 2.0.29]
  - at growth-cycle; cause all plants to be destroyed and decreases soil pH by about 0.4 pH [since 2.0.31]
  - Please note that *before* the growth-cycle occurs then;
    - spraying Herbicide-X will remove any of the fertilizers in the sprayed area.
- Spray moisture / "dark texture" (from liquid fertilizer/herbicide/slurry/water);
  - at growth-cycle; increases soil moisture by about 14%
- Water (explicit spraying of water or due to plowing);
  - at growth-cycle;
    - when area was plowed and NOT afterwards sprayed with water; decreases soil moisture by about 14%
    - else; increases soil moisture by about 14%
- Weather conditions;
  - at noon 12:00 o'clock and temperature above 22 degrees; decreases soil moisture by about 14%
  - when raining and at every whole hour; increase soil moisture by about 14%

### Growth of crops

During a growth-cycle, crops with cause the following effects:

- When at stages 1-7; consumes 1 N
- When at stages 3 & 5; consumes 1 PK
- When at stages 2, 3 & 5; decrease soil moisture by about 14%
- When at stage 3; decrease soil pH by about 0.2 pH
- Fully grown weeds become withered if there is zero N in soil
- Weeds (if not withered) consume 1 N and about 14% soil moisture
 
 
## Change-log

2.0.42
- Callback 'setFruitTypeHerbicideAvoidance' can now be called with <herbicideType> "-", i.e. 'fruit not affected by any herbicide-type'.

2.0.41
- Renamed file-extensions once again.
  - I'm giving up on keeping the Dedicated Server Software to not complain about; too many .txt files and unknown file type .grle

2.0.40
- Removed wrong verification.

2.0.39
- Added more verifications/checks that the map has been correctly prepared for SoilMod.

2.0.38
- Callback method added: modSoilMod2.setFruitTypeHerbicideAvoidance(<fruitName>,<herbicideType>)
  - For map-makers to put in SampleModMap.LUA, if they need to change or add a new fruit and what herbicide it dislikes.
- Added code to verify that SoilMod's custom spray-/fill-types have been registered and are available.
  - This is due to the 'max 64 fill-types' problem that some players encounter, when having too many mods.
- Refactored loading-mechanism of the LUA scripts.

2.0.37
- Dutch translation by DreadX.

2.0.36
- Rearranged 2+1 foliage-sub-layers in the Map_Instructions.TXT, due to FS15 patch 1.3 beta-1.
  - Note: It is NOT required to update existing already SoilMod-prepared maps. (If you do, existing savegames will become corrupt!)
  - Note: Even though patch 1.3 beta-2 "solved the problem", the restructured foliage-sub-layers should be used for new/unprepared maps.

2.0.35
- Workaround for when players use the 'mrLight' mod.
  - The problem was that 'mrLight' does not know of SoilMod's additional spray-types.
  
2.0.34
- Multiplayer fix, where 'augmented spray-type' was not correctly transmitted to clients.

2.0.33
- Refactored hiding of SoilMod's info-panel.
  - Now possible to specify 'autoHide' via ModsSettings.XML (which is an optional extra mod.)

2.0.32
- Included German translation by Beowulf of the ReadMe text (for v2.0.22)

2.0.31
- 'Herbicide-X' (*or what custom name its given by map-mods*) now decrease soil pH levels.

2.0.30
- Support for a map-mod to override the spray-type names, by having them in the map's modDesc.XML <l10n> section.
  - So if 'Fertilizer NPK' or 'Herbicide B' is not descriptive enough, then the map-maker can overrule these, along with the hud icons [see v2.0.25]

2.0.29
- Added a 'Herbicide-X' spray-type, which will remove all crops (including grass) at the next growth-cycle.
  - Except if fertilizer (NPK, PK, N) was sprayed in the same area afterwards.
- Re-added the following rule; "if 'kalk' is already one of accepted spray-types on spreader/sprayer, then do not add the ones from SoilMod"
  - The previous problem looked like it was due to forgetting removing other mods that conflict with SoilMod.
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
