<div align="center">

# MountRoulette

![Logo](https://i.imgur.com/FMnEM4P.png)
</div>

MountRoulette is a WoW Classic (currently Season of Mastery) addon that randomly chooses a mount for you every time you mount up.  It was created because no other random-mount addons could be found that were compatible with WoW Classic.  The next best thing that appeared to be availble was a WoW Classic TBC addon, which seemed unreliable at best.  MountRoulette is very simple to configure and use across all of your characters.

## Features
- Automatically detects new mounts when you acquire them.
- Handles both item-based mounts (e.g. ***Pinto Bridle***) and summoned mounts (e.g. Warlock's ***summon felsteed*** spells).
- Automatically re-selects a new random mount any time you gain a new mount, move mount items in/out of your bags, move into a new zone, etc.
- Prioritizes fast mounts over slow ones if you've gained fast riding-skill, and any fast mounts are currently in your bags / spellbook.
- Mounting / dismounting is done by creating an account-wide macro, which you can then drag to an actionbar, bind to a keypress / mouseclick, etc.

## Quick Start
1. Create a new macro called **MountRouletteMac**, and put something like the following into it:
```lua
/click [outdoors, nomounted] MR_button
/dismount [mounted]
```
1. Set up how you want to access the macro (e.g. dragged to an actionbar, bound to keypress, etc.)
1. Type `/mroulette choose` to rescan your available mounts, pick one randomly, and set up the "MR_button" that your macro calls.
1. Test it out!

## Controlling MountRoulette
- MountRoulette has several commands you can use.  All start with "/mroulette" or "/mr" (for short):
1. `/mroulette show`:  Shows all currently available mounts
1. `/mroulette scan`: Re-scan your bags and spellbook for all mounts currently available
2. `/mroulette choose`: Pick one of the available mounts randomly and assign it to MountRoulette's button.

## How It Works
Everytime certain in-game events occur, MountRoulette automatically re-scans your bags and spellbook to find all mounts currently available.  It then randomly picks one of your available mounts to be used.  At present these events include:
- Whenever you log in
- Whenever your spellbook changes
- Whenever your bag contents change
- Whenever you move to a new zone
- Whenever you move to a new area within a zone

MountRoulette creates a non-visible UI button (called ***MR_button***) and assigns it to invoke the selected mount, through either an item-use or spell-cast action depending on the kind of mount it is.

Once you have set up your new macro (once per account for all your characters) as shown in *Quick Start* above, the macro will use MountRoulette's button to summon your selected mount.  It will summon the same mount each time until one of the above events occur or you manually randomize your mounts again with `/mroulette choose`.
