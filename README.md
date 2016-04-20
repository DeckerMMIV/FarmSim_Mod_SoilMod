# Farming Simulator modification - SoilMod

To read more about this mod, find it on http://fs-uk.com - http://fs-uk.com/mods/search/soil%20management


## Effects

*As of version 2.2.3*

- When using a mod that has the `SoilMod_Weeder` specialization;
  - will remove weed plants
  - will also start to remove crops, that have grown into their 3rd growth-state (growth-states 4-8)
  - will provide 2 days of weed-germination prevention
- Alfalfa & Clover (luzerne & klee) (if available in map) [since 2.0.51]
  - can be plowed/cultivated from 1st growth and up (growth states 2-8)
  - when plowed adds; +4 N, +2 PK
  - when cultivated adds; +1 N
- Sowing 'dryGrass' will not remove the field texture [since 2.0.49]
  - the sowing-machine's seed type must be set to 'grass with stripes'-icon, for this to work.
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
  - when plowed/cultivated; only visible graphics removed
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
- Herbicide-A/B/C;
  - at growth-cycle makes weeds withered and decrease soil pH by about 0.2 pH
  - note that crops will be affected during growth-cycle if wrong herbicide is used;
    - when crop is at "blue" growth-stages; the crop will not growth
    - when crop is at "green" growth-stages; the crop becomes withered
  - usage of herbicide vs. crop types (*SoilMod defaults, which may be changed by the map-mod [since v2.0.42]*);
    - use type 'B' or 'C' on; wheat, barley, rye, oat, rice. (*Do not use type 'A'*)
    - use type 'A' or 'C' on; corn/maize, rape/canola, osr, luzerne, klee. (*Do not use type 'B'*)
    - use type 'A' or 'B' on; potato, sugarbeet, soybean, sunflower. (*Do not use type 'C'*)
- Herbicide-AA/BB/CC; 
  - does the same as herbicide-A/B/C, but also adds 3 extra days of weed-germination prevention (which does not affects crops)
- Herbicide-X [since 2.0.29]
  - at growth-cycle; cause all plants to be destroyed and decreases soil pH by about 0.4 pH [since 2.0.31]
  - Please note that *before* the growth-cycle occurs then;
    - spraying Herbicide-X will remove any of the fertilizers in the sprayed area.
- Spray moisture / "dark texture" / "wet texture" (from liquid fertilizer/herbicide/slurry/water);
  - at growth-cycle; increases soil moisture by about 14%
- Water (explicit spraying of water or due to plowing);
  - at growth-cycle;
    - when area was plowed and NOT afterwards sprayed with water; decreases soil moisture by about 14%
    - else; increases soil moisture by about 14%
- Weather conditions;
  - at noon 12:00 o'clock and temperature above 22 degrees; decreases soil moisture by about 14%
  - when raining (not hail) and at every whole hour; increase soil moisture by about 14%

### Growth of crops

During a growth-cycle, crops with cause the following effects:

- When at stages 1-7; consumes 1 N
- When at stages 3 & 5; consumes 1 PK
- When at stages 2, 3 & 5; decrease soil moisture by about 14%
- When at stage 3; decrease soil pH by about 0.2 pH
- Fully grown weeds become withered if there is zero N in soil
- Weeds (if not withered) consume 1 N and about 14% soil moisture
 
 
## Change-log

2.2.15
- Attempt at fixing 'grid-pattern'-growth problem which apparently only occurred on clients in a multiplayer game.

2.2.14
- Added Danish translation of ReadMe and 'Map Instructions' by Holse.

2.2.13
- Added sanity-checking of registered 'fruits' growth-state values against their corresponding foliage-layer, to ensure that SoilMod only uses correctly registered fruits.

2.2.12
- Fix for a problem introduced in the code at version 2.2.7

2.2.11
- Automatic loading of fill-plane materials, for the SoilMod spray-types; fertilizer, fertilizer2, fertilizer3 and kalk.

2.2.10
- Fix for issue #88, where the map's custom fruitHud icons were not correctly used.

2.2.9
- "Okay, I give up. - DSS, you win."
  - Due to the restrictive checks that the Dedicated Server Software (DSS) makes, I have renamed all TXT files to XML (they are still text-files though) and added an ugly work-around to "mute" the DSS from issuing warnings about 'unknown file-type: GRLE'.

2.2.8
- Modified FillTrigger.LUA (e.g. 'fertilizer tanks'), so equipment's spray-type does not need to be switched before filling
- Modified FillTrigger.LUA, added user-attribute 'fillTypes' (plural) for "FillTrigger.onCreate", to support creation of 'only herbicide tanks' and similar
- Modified MultiSiloTrigger.LUA, to prevent liquid-sprayers being filled from it
- Modified MultiSiloTrigger.LUA, so the dialog-box display only the fill-types that the equipment can accept
- Minor fix when switching spray-type; now calling `setFillLevel()` to update it and any fill-planes correctly

2.2.7
- Polish map instructions updated by Ziuta
- Changed so SoilMod fill-types are registered before loading map, to allow amount for 'farm-silos' being stored in careerSavegame.xml
  - There may be some conflicts when other mods are registering the same fruit-/spray-/fill-types
  - This change might affect non-SoilMod maps too

2.2.6
- Russan translation updated by Gonimy-Vetrom
- Italian translation updated by DD Modpassion
- Polish translation updated by Dzi4d3k
- Fix for 'grid-pattern'-growth problem on x4 maps (and possibly also x16 maps)
- Fix for only adding SoilMod spray-types to equipment with 'Sprayer' specialization

2.2.3
- Hired workers tries to "remember" what they are spraying, even when empty.
  - NOTE: This only works with-in the current play-session, and NOT between save/load sessions.
- Map-specific setting for `sprayTypeChangeMethod`, so map-authors DO NOT need to modify SoilMod's scripts.
  - Map-author, or owner of savegame, can now decide if spray-type can only be selected near a fertilizer-tank or not.
  - Ask/look in the FS-UK support-topic for instructions, or read the comment in fmcSoilMod.LUA, loadMapFinished().
  - Yes, I'm annoyed at a particular map-author, who've distributed a modified SoilManagement.ZIP with his map.
- Icons for the spray-/fill-types moved, and should now be copied to the map-mod if the map-author wants to modify them.
  - Ask/look in the FS-UK support-topic for instructions, or read the `Map_Instructions.txt` part 0.
  - Yes, I'm annoyed at a particular map-author, who've distributed a modified SoilManagement.ZIP with his map.
- Added custom tool-specialization for 'mechanical weed prevention'; `SoilMod_weeder`.
  - Can be used in custom made "cultivator like" mods.
  - SoilMod itself will NOT contain any buyable equipment with this, so other mod-authors have to create some.
  - Ask/look in the FS-UK support-topic for instructions.
- Plowing/cultivating "cover crops" (alfalfa, clover) won't increase N & PK as much.
- Grid-display settings will be read from optional ModsSettings-mod configuration file.
  - Ask/look in the FS-UK support-topic for instructions.

2.1.x
- Other parallel occurring experiments

2.0.53
- Experiment with 'weeder' tool.
  
2.0.52
- Added support for map-specific 'change spray type' setting.
  - This was done, due to discovering that a certain map-author distributed a modified SoilManagement.ZIP with his map-mod.
  - That map-author should now instead add the following to the map-mod's SampleModMap.LUA, inside the `loadCareerMap01Finished()` function:
  ```
  -- Check that SoilMod v2.x is available...
  if modSoilMod2 ~= nil and modSoilMod2.setCustomSetting ~= nil then
      -- Map-specific setting of how 'change spray type' should work.
      -- This can be overruled in the careerSavegame.XML, in case the player wants it otherwise.
      modSoilMod2.setCustomSetting("sprayTypeChangeMethod", "Everywhere")
                                                      -- or "NearFertilizerTank"
  end
  ```
  - Players who want to override this setting, have to do so in their careerSavegame.XML file:
  ```
  <modsSettings>
      <fmcSoilMod>
          <customSettings sprayerTypeChangeMethod="NearFertilizerTank" />
  ```  
  - NOTE! There might be some multiplayer bugs regarding this, as the player-clients (*those that connect to the hosting-server*) probably won't get the correct server-side setting.

- Added support for 'explicit spreader/sprayer type' setting (`solid` or `liquid`), via the vehicle-XML file.
  - The modded vehicle's vehicle-XML file, may now contain the following XML-tags and attributes, to tell SoilMod if it is a `solid` spreader or `liquid` sprayer:
  ```
  <vehicle type="...">
      ...
      <SoilMod>
          <sprayer type="solid" />  <!-- or type="liquid" -->
      </SoilMod>
      ...
  </vehicle>
  ```  
  
2.0.51
- Experimentation with "cover crops"; 'alfalfa' and 'clover' (a.k.a. 'luzerne' and 'klee')
  - When cultivating/plowing these, the nutrition N & PK will be raised differently than compared with other crops.

2.0.50
- Ability for customizing the "grid-display" via 'ModsSettings'-mod.
  - The 'ModsSettings'-mod is an optional mod (still in BETA), but required if you want to customize the "grid-display".

2.0.49
- Added ability to sow grass without removing the field.
  - If a sowing-machine can seed grass, an extra seed type is possible to select, looking like 'grass with stripes'.
  - This 'grass with stripes'-icon (graphics is not my skill) attempts to illustrate that when sowing grass, the field will not be removed.

2.0.48
- Minor fix to Spanish translation by Vanquish081.

2.0.47
- Map_Instructions_PL.TXT by Ziuta, added in folder; Requirements_for_your_MapI3D\.Instructions_in_other_languages.

2.0.46
- Misc. changes in the plugin for the ChoppedStraw support.

2.0.45
- Maybe fix/work-around against the ZZZ_64erFix mod's later change of the `Fillable.sendNumBits` constant.
- Spanish translation updated by Vanquish081.

2.0.44
- Added console-command 'modSoilModField', which uses a fields field-borders to get a simple SoilMod-status of the field.
  - Note: The status output will be 'average values', so smaller areas within the field-borders could have much different values.
  - Note: If map-maker have not defined any field-borders, this console-command will not work.
  - Note: If a field have multiple overlapping field-borders, this console-command will not compensate for it.
- Renamed console-command to 'modSoilModPaint' from 'modSoilMod'.

2.0.43
- Fixed Zunhammer Zunidisk so it now cultivates slurry into ground.
- Fixed 'worked area' calculations for cultivator/plough, after seeing FS15 script documentation.
- Added verification that `Fillable.sendNumBits` is not modified before SoilMod initializes.
- Did some code cleanup.

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
