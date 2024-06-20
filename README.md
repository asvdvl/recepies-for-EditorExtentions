[ru desctiption](https://github.com/asvdvl/recepies-for-EditorExtentions/blob/master/README.ru.md)

# Auto-generated recipes for the Editor Extensions mod

> may be unstable at the moment, I will be grateful if you report errors to me

## Goals (and limitations for me):
> not all recipes are dynamic, the mod has 3 out of 27 recipes with hardcode: a linked conveyor belt with a chest (partially) and night vision goggles (entirely)

- dynamically, without using "hardcoding":
	- generating recipes for items based on their "properties"
	- generating a module recipe using combinatorial optimization
	- satisfy situations when a creative item does not require energy but should

- Do not rewrite any Editor Extensions logic except in the data.raw.recipe["recipe"] fields:
	- ingredients - the ingredients of the recipe
	- energy_required - a very strange name for the variable responsible for the duration of crafting, changes only if it is impossible to place the required number of ingredients in the top field (limitations of the engine or user settings)

- dynamic integration into the technology tree
	- items must have a dependency on crafting ingredients
	- the number of each "science", the total number of "sciences" and the research time are built from the dependencies (all this is the sum of the same parameters for the "parent")

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
- Hiladdar mods
- micro-machines
	- support for crafting in them
- Schall mods
- Space Exploration
	- It didn’t start right away, but the fix turned out to be funny, I just renamed data-update to data-final-fixes, also all modules except speed are disabled due to exceeding characteristics, you can fix it manually in the settings by specifying the necessary modules and enabling the forced use of the specified items. although if this mod is needed not only by me, then I will fix it.

## Gallery
<details>
<summary>list</summary>

![recipes](/gallery/recipes.png)
![linked chest](/gallery/linked-chest.png)
![settings 1/3](/gallery/settings1.png)
![settings 2/3](/gallery/settings2.png)
![settings 3/3](/gallery/settings3.png)

</details>

## Included items and balance comments:
* I must say right away that this mod turns out to be endgame content, and I think this is fair

* Each item can be individually turned on or off in the settings

- Linked belt
	- The logic is very simple, imagine that an electric motor was inserted into a cargo wagon and it now runs underground, if it weren’t for the condition that I would not change the EE code, then I would force player to put inside conveyors equal to the distance between 2 points, but I’ve already been developing the mod for a month.

- Linked chest
	- these 2 items, as you can see, are interconnected, for me it is logical. as I mentioned in defines.lua, I had to put 32 underground ones(look at screenshots), but in this case it is easier to save up for cargo drones (at that time of development, without changing the crafting time and reactors)

- these items are "ordinary", based on the given parameters, we selected the best item with the most suitable stats but not exceeding them, we also satisfied the lack of electricity by adding a reactor, the required number of reactors was calculated using the maximum consumption of items in ingredients
	- Super inserter
	- Super locomotive
	- Super pump
	- Super electric pole
	- Super substation
	- Super energy shield
	- Super personal battery
	- Super exoskeleton
	- Super personal roboport
	- Super roboport
	- Super lab
	- Super radar
	- Super beacon

- this recipe is just hadcoded, I have no idea how to "dynamically" generate it
	- Super night vision

- and we come to the part that I consider the most interesting for me and because of which I started writing this mod, modules. the essence is simple, from EE we have cool modules with characteristics of 250%; the algorithm takes top modules and tries to "suppress" this requirement, for example, for a speed of 250% we need 5 speed modules, but speed modules bring not only speed, but also decrease in efficiency, and in order to reduce the decrease in efficiency to 0, we take 7 efficiency modules. This is the simplest example, because there is a productivity module, not to mention useless modules that harm and do not help, also the crafting time is double the time of the top module
	- Super speed module
	- Super efficiency module
	- Super productivity module
	- Super slow module
	- Super inefficiency module
	- Super dirty module
	- Super clean module
	- a separate note, because in the game there are no modules that reduce pollution, it is taken from the "fallback" table, in this case it’s a wood, which to me is logical, this behavior changes in the settings, like other fallback effects

- a separate category of "super-highlighted" game has a limit on recipes of 65k, so to compensate for this, I transferred the leftovers that did not fit during crafting, 1 missing item == 1 second, as a result, items cannot be crafted, except for drones, but I left them, there will probably be individuals who have even more cheating items _or you will find a setting that divides this time_
	- Super fuel
	- Infinity fusion reactor
	- Super construction robot
	- Super logistic robot