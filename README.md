
# Auto-generated recipes for the Editor Extensions mod

> may be unstable at the moment, I will be grateful if you report errors to me

## Goals (and limitations for me):
- dynamically, without using “hardcoding”:
> It didn’t work out completely, the mod has 3 of 27 recipes with a hardcode: a linked conveyor belt with a chest (partially) and night vision goggles (entirely)
  - generating recipes for items based on their "properties"
  - generating a module recipe using combinatorial optimization
  - satisfy situations when a creative item does not require energy but should

- Do not rewrite any Editor Extensions logic except in the data.raw.recipe["recipe"] fields:
	- ingredients - the ingredients of the recipe
	- energy_required - a very strange name for the variable responsible for the duration of crafting, changes only if it is impossible to place the required number of ingredients in the top field (limitations of the engine or user settings)

- dynamic integration into the technology tree
	- items must have a dependency on crafting ingredients
	- the number of each “science”, the total number of “sciences” and the research time are built from the dependencies (all this is the sum of the same parameters for the “parent”)

- integration into assemblers

## But...why? Why not just write the recipes by hand?
 1. this is a challenge I set for myself
 2. I don’t have to add compatibility with every mod, what I wrote should be able to independently find everything they need to create recipes
 3. learn about the "fun" features of modding and gaming
 4. it was fun to program

## Tested with mods, and at least the game starts:
- more-module-tiers
- RampantArsenal
- UltimateBelts
- Big_Brother
  - The recipe probably won't change.
- моды Hiladdar
- micro-machines
  - support for crafting in them
- моды Schall
- Space Exploration
  - It didn’t start right away, but the fix turned out to be funny, I just renamed data-update to data-final-fixes, also all modules except speed are disabled due to exceeding characteristics, you can fix it manually in the settings by specifying the necessary modules and enabling the forced use of the specified items. although if this mod is needed not only by me, then I will fix it.

## gallery
<details>
<summary>list</summary>

</details>

## Enabled items:
<details>
<summary>list</summary>

 - Linked belt
 - Linked chest
 - Super inserter
 - Super locomotive
 - Super pump
 - Super electric pole
 - Super fuel
 - Super substation
 - Infinity fusion reactor
 - Super energy shield
 - Super personal battery
 - Super exoskeleton
 - Super night vision
 - Super personal roboport
 - Super construction robot
 - Super logistic robot
 - Super roboport
 - Super beacon
 - Super speed module
 - Super efficiency module
 - Super productivity module
 - Super clean module
 - Super slow module
 - Super inefficiency module
 - Super dirty module
 - Super lab
 - Super radar
</details>