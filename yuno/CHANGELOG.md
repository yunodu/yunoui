## yuno 5.0

- Rebuilt the installer.
- Moved chat buttons, health opacity, and class-background tint into Appearance.
- Added 16:9 and 21:9 EllesmereUI layouts. The installer imports both and uses the one that matches your monitor.
- You can switch layouts later from `/yuno`.
- Updated the bundled EllesmereUI profiles.
- Damage Meter windows now follow the imported layout.
- Player and target portraits are now built into yuno. Blinkii's Portraits is no longer required.
- Appearance can draw drop shadows on unit frames, resource bars, and the cooldown manager.
- Updated the default extras and portrait settings.
- Removed Movement Tracker. It now lives in EllesmereUI.
- Please *fully* reinstall yunoUI to make sure everything is applied correctly.
- That includes deleting the contents of your current AddOn folder and reimporting the WoWUp string.

## yuno 4.5

- Updated the bundled EllesmereUI profile.
- EllesmereUI import now strips stranded spec overrides left behind by override-group membership changes (e.g. stuck Hide Power Bar values).
- Added a healing profile that activates automatically on healer specs.
- Updated the bundled BigWigs core profile.
- Added BigWigs boss-options import so boss settings ship with the core profile.
- Registered a Yuno BigWigs countdown voice and bar style.
- Updated the bundled EXBoss profile.
- Updated the EXBoss voice files with new self-recorded callouts. Thanks to Angelina for helping and speaking them in <3.
- Added PvP / arena support via sArena Reloaded.
- Added Baganator bag profile import.
- Updated the bundled Cooldown Manager profiles.
- Added new textures for bars and highlights, and new mouseover arrows.
- Fixed body copy overlapping the action buttons on long addon lists.

## yuno 4.0

- Removed the sound channel override and its related settings and commands.
- Updated the bundled EllesmereUI profile.
- Updated the bundled Cooldown Manager profiles.

## yuno 3.10

- Fixed party and raid health background flicker while units take damage.
- Added an Appearance mode choice for Dark Mode or Class Colored in `/yuno` and the installer.
- Added a login popup when bundled profiles have been updated, prompting to reimport only the changed ones.
- Updated the bundled EllesmereUI import profile.
- Moved Cooldown Manager import ahead of EllesmereUI in the installer so EUI is the final import step.
- Moved the Appearance color choice to after EllesmereUI import so it applies to the imported profile.

## yuno 3.02

- Changed the optional forced sound channel override from 32 to 70.

## yuno 3.01

- Rebuilt the Movement Tracker with combat-safe charge caching.
- Added the pet healthbar to idle fade.
- Added a sound channel override that keeps `Sound_NumChannels` at 32.

## yuno 3.0

- Reworked the /yuno menu and installer with a custom framework.
- Added a Quality of Life page with a Movement Tracker.
- Fully reworked the profile installer into its own dedicated window.
- Fixed the dedicated installer reopening to the final scale step after the intermediate reload.
- Restyled the installed-profile character prompt.
- Moved the friendly nameplate override from CVars into Appearance behaviors.
- Updated the EXBoss profile import.
- Updated the EllesmereUI profile import.
- Updated the BigWigs profile import.

## yuno 2.9

- Added EXBoss profile import.
- Updated the bundled BigWigs import profile to accompany for EXBoss.

## yuno 2.8

- Added a yuno settings option to disable EllesmereUI color syncing.
- Updated Blizzard Cooldown Manager class import strings.

## yuno 2.7

- Updated the bundled EllesmereUI import profile for Ellesmere's unit frame changes.
- Removed DandersFrames profile import and profile switching support; EllesmereUI unit frames now cover this setup.

## yuno 2.6

- Added a framework layer for the theme.
- Restyled the `/yuno` settings and installer window around the new theme.
- Added the logo.
- Switched EllesmereUI theme enforcement from `Dark` to `Custom Color`.
- Updated the enforced EllesmereUI accent color to the new logo blue.
- Added an optional idle fade setting for the player frame, resource bars, and cooldown manager outside combat, target, dungeon, and raid states.
- Extended the EllesmereUI unit frame runtime patch to party and raid frames.
- Removed the automatic installer step that applied legacy Ellesmere chat and Damage Meter presets now that EllesmereUI profile import handles them.
- Stopped `/yuno profiles` from automatically applying the old Ellesmere extras after loading profiles.
- Updated the bundled EllesmereUI import profile again.

## yuno 2.5

- Updated the bundled EllesmereUI import profile.
- Fixed the BigWigs startup warning caused by `yuno` referencing `BigWigs_Options`.
- Removed direct loading of `BigWigs_Options`; BigWigs now handles its own options loading during profile import.
