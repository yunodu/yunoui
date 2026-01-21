# yunoUI

<p align="center">
  <img src="Media/Banner/yui.png" alt="yunoUI Banner">
</p>

**yunoUI** is my own changes to existing World of Warcraft Addons. This package aggregates specific addons and profiles to create a cohesive UI experience. This is optimized for 1440p ultrawide (3440x1440). If your resolution differs you most likely will have to resize UI elements.

## 📦 Required Addons

To use yunoUI, you will need the following addons installed.

### via WowUp
You can install the core list using the following WowUp import string:
> [Click to view WowUp Import String](Profiles/wowup.txt)
>
> *(In WowUp: My Addons -> Import/Export Addon -> Import)*

### Manual List
* **QuaziiUI_Midnight** *(Note: You will need to get this elsewhere, NOT provided here. Please support Quazii by subscribing to him)*
* **Platynator**
* **BugGrabber**
* **BugSack**
* **Details! Damage Meter**
* **yunoUI** (This addon)
* **Danders Frames**

---

## 🛠️ Installation Guide

### Step 1: Preparation (First Time Only)
*If this is your very first time installing yunoUI on a fresh character:*

1.  Navigate to your WoW `_retail_` folder.
2.  **Delete (or backup)** your existing `Interface` and `WTF` folders to ensure a clean install.
3.  Launch World of Warcraft.

### Step 2: Blizzard Settings
Before configuring addons, set these in-game options:

* **Action Bars:** `Esc` -> Options -> Action Bars -> **Enable Bars 2 through 6**.
* **Resource Display:** `Esc` -> Options -> Combat -> **Uncheck** "Personal Resource Display".
* **Boss Warnings:** `Esc` -> Options -> Gameplay -> **Check** "Boss Warning" and "Boss Timeline".

---

## ⚙️ Configuration (First Time Setup)

Follow these steps in order to import the profiles.

### 1. Quazii UI
1.  Open the config: type `/qui`
2.  Go to **Import/Export**.
3.  Paste the **Quazii Profile String** (linked below).
4.  Click **Import**.
5.  Close the window and type `/reload`.

### 2. Details! Damage Meter
1.  Open config: `/details config`
2.  Go to **Options** -> **Profiles** -> **Import Profile**.
3.  Paste the **Details Profile String**.
4.  Name the profile (e.g., "yunoMain") and click **Okay**.
5.  **Crucial Step:** At the bottom of the window, check **"Use on all characters"**.
6.  Select your new profile from the list and close the window.

### 3. Platynator
1.  Open config: `/platy`
2.  Click **Import**.
3.  Paste the **Platynator String**.
4.  Name the profile and click **Okay**.
5.  Close the window.

### 4. Danders Frames
/// not implemented for now, theres a bug with profile imports in Danders Frames

### 5. yunoUI Addon
1.  Open config: `/yui` (or `/yunoui`)
2.  Go to **Profiles** (or Import).
3.  Paste the **yunoUI Core Profile String**.
4.  Click **Import/Accept**.
5.  Close the window.

### 6. Finalize & Edit Mode
1.  Type `/reload` to save current settings.
2.  Open Edit Mode: `Esc` -> **Edit Mode**.
3.  Click **Import**.
4.  Paste the **Edit Mode String**.
5.  Name the profile and click **Import**.
6.  **⚠️ IMPORTANT:** Do **NOT** click the red "Save" button at the bottom. Click the **"Save and Exit"** button at the top of the screen.
7.  Type `/reload` one last time.

---

## 🔁 Alt Character Setup
*For every new character you log into after the initial installation:*

1.  Log in to the character.
2.  **Enable Action Bars:** `Esc` -> Options -> Action Bars -> Ensure 2-6 are enabled.
3.  **Load Layout:** `Esc` -> Edit Mode -> Select your imported yunoUI profile from the dropdown.
4.  Type `/reload`.
5.  **GG EZ** — You're ready to play.

---

## 📂 Import Strings

Click the links below to view the raw import strings. Copy the content of the file to import.

| Addon | Profile Type | Link |
| :--- | :--- | :--- |
| **QuaziiUI** | Core Profile | [View String](Profiles/quazii.txt) |
| **yunoUI** | Core Profile | [View String](Profiles/yunoui.txt) |
| **Details!** | Damage Meter | [View String](Profiles/details.txt) |
| **Platynator** | Nameplates | [View String](Profiles/platynator.txt) |
| **Danders Frames** | DPS Profile | [View String](Profiles/danderframesdps.txt) |
| **Danders Frames** | Heal Profile | [View String](Profiles/danderframesheal.txt) |
| **Blizzard** | Edit Mode Layout | [View String](Profiles/editmode.txt) |
