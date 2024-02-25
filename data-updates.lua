local all_recipes = data.raw.recipe

--recipes for which I can find legal crafting
local recipes = {
    --logistic
    ["ee-linked-belt"]={},
    ["ee-linked-chest"]={},
    ["ee-super-inserter"]={},
    ["ee-super-locomotive"]={},
    ["ee-super-pump"]={},

    --energy
    ["ee-super-electric-pole"]={},
    ["ee-super-fuel"]={},
    ["ee-super-substation"]={},

    --equipment
    ["ee-infinity-fusion-reactor-equipment"]={},
    ["ee-super-energy-shield-equipment"]={},
    ["ee-super-battery-equipment"]={},
    ["ee-super-exoskeleton-equipment"]={},
    ["ee-super-night-vision-equipment"]={},
    ["ee-super-personal-roboport-equipment"]={},

    --robots
    ["ee-super-construction-robot"]={},
    ["ee-super-logistic-robot"]={},
    ["ee-super-roboport"]={},

    --modules/effects
    ["ee-super-beacon"]={},
    ["ee-super-speed-module"]={},
    ["ee-super-effectivity-module"]={},
    ["ee-super-productivity-module"]={},
    ["ee-super-clean-module"]={},
    ["ee-super-slow-module"]={},
    ["ee-super-ineffectivity-module"]={},
    ["ee-super-dirty-module"]={},

    --other
    ["ee-super-lab"]={},
    ["ee-super-radar"]={},
}
for _, value in pairs(recipes) do
    value["can_make_legaly"] = true
end

--find all other recepies
for key, value in pairs(all_recipes) do
    if value.category == "ee-testing-tool" then
        if settings.startup["rfEE_allow_all_items"].value or recipes[key] then
            value.enabled = true
        end
        if not recipes[key] then
            --value["can_make_legaly"] = false
            recipes[key] = {["can_make_legaly"] = false}
        end

    end
end