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
