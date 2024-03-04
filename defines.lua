local defines = {}

defines.item_processing_prefix = "item"
defines.recipes = {
    --logistic
    ["ee-linked-belt"]={
        type = "defined",
        recipe = {
            {type="item", name="cargo-wagon", amount=1},
            --[[
                Let's imagine that the electric motor has a power of 5 kW
                (based on a 200 kW exoskeleton with 30 motors in the recipe)
                and this means that we need 120 to achieve the 600kW(vanila locomotive) figure.
            ]]
            {type="item", name="electric-engine-unit", amount=120},
            {type="item", name="processing-unit", amount=60},
            {type="item", name="express-underground-belt", amount=1},
            {type="item", name="fusion-reactor-equipment", amount=1},
        }},
    ["ee-linked-chest"]={
        type = "defined",
        --[[
            According to my calculations, using 1 super inserters you can achieve a speed of 360 items per second using these chests!
            therefore, 360/45 = 8, also multiply by 4 sides and get 32 conveyors!
            But i give off 75% price for motivating build that massive unloaders!
        ]]
        recipe = {
            {type="item", name="ee-linked-belt", amount=8},
            {type="item", name="steel-chest", amount=1},
        }},
    ["ee-super-inserter"]={},
    ["ee-super-locomotive"]={},
    ["ee-super-pump"]={},

    --energy
    --["ee-super-electric-pole"]={}, --this item is disabled due to its uselessness and the complexity of 2 different processings for 1 class
    ["ee-super-fuel"]={
        type = defines.item_processing_prefix.."_generated",
        name_filter = "fuel",
        search_rows = {fuel_value = 1, fuel_acceleration_multiplier = 1, fuel_top_speed_multiplier = 1},
    },
    ["ee-super-substation"]={},

    --equipment
    ["ee-infinity-fusion-reactor-equipment"]={},
    ["ee-super-energy-shield-equipment"]={},
    ["ee-super-battery-equipment"]={},
    ["ee-super-exoskeleton-equipment"]={},
    ["ee-super-night-vision-equipment"]={
        type = "defined",
        recipe = {
            {type="item", name="night-vision-equipment", amount=1},
            {type="item", name="processing-unit", amount=50},
            {type="item", name="effectivity-module", amount=1},
        }
    },
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

for _, value in pairs(defines.recipes) do
    if not value.type then
        value.type = "generated"
        value.recipe = {}
    end
end

local function empty_function(...)
    local table = {...}
    if table[1] and table[1]["recipe_object"] then
        log('empty_function call detected! this shouldnt have happened! prototype: '..table[1].recipe_object.name)
    else
        log('empty_function call detected! this shouldnt have happened! params: '..serpent.block(table))
    end
end

defines.types = {
    --defined
    ["linked-belt"] = {
        keyword = "defined"
    },

    ["linked-container"] = {
        keyword = "defined"
    },

    ["night-vision-equipment"] = {
        keyword = "defined"
    },

    --base_property
    ["construction-robot"] = {
        keyword = "base_property",
        search_rows = {"max_payload_size", "speed"}
    },

    ["logistic-robot"] = {
        keyword = "base_property",
        search_rows = {"max_payload_size", "speed"}
    },

    ["inserter"] = {
        keyword = "base_property",
        search_rows = {["rotation_speed"] = 21600, "stack"}
    },

    ["lab"] = {
        keyword = "base_property",
        search_rows = {"researching_speed"}
    },

    ["pump"] = {
        keyword = "base_property",
        search_rows = {"pumping_speed"}
    },

    ["energy-shield-equipment"] = {
        keyword = "base_property",
        search_rows = {"max_shield_value"}
    },

    ["movement-bonus-equipment"] = {
        keyword = "base_property",
        search_rows = {"movement_bonus"}
    },

    --energy related stuff but compatible with base_property
    ["locomotive"] = {
        keyword = "base_property",
        search_rows = {"max_speed", "max_power"}
    },

    ["generator-equipment"] = {
        keyword = "base_property",
        search_rows = {"power"}
    },

    --with area
    ["radar"] = {
        keyword = "base_property",
        search_rows = {["max_distance_of_sector_revealed"] = "^2", ["max_distance_of_nearby_sector_revealed"] = "^2"}
    },

    ["roboport"] = {
        keyword = "base_property",
        search_rows = {["logistics_radius"] = "^2", ["construction_radius"] = "^2"}
    },

    ["roboport-equipment"] = {
        keyword = "base_property",
        search_rows = {["construction_radius"] = "^2"}
    },

    ["beacon"] = {
        keyword = "base_property",
        search_rows = {["supply_area_distance"] = "^2"}
    },

    ["electric-pole"] = {
        keyword = "base_property",
        search_rows = {"maximum_wire_distance", ["supply_area_distance"] = "^2"}
    },

    --items are too complex for processing, i just moved search_rows to 
    ['item'] = {
        keyword = "items",
    },

    --other
    ["module"] = {
        keyword = "modules",
        search_rows = {'effect'}
    },

    ["battery-equipment"] = {
        search_rows = {"energy_source/buffer_capacity"}
    },

}

--filling in all missing fields by default
for _, type in pairs(defines.types) do
    type.func = empty_function
    type.top_items = {}

    if not type['search_rows'] then
        type.search_rows = {}
    end

    if not type['keyword'] then
        type.keyword = ""
    end
end

--convert subtables in search_rows like {"power"} to {["power"]=1}
for _, types in pairs(defines.types) do
    for row_name, row in pairs(types.search_rows) do
        if type(row_name) == "number" then
            types.search_rows[row] = 1
            types.search_rows[row_name] = nil
        end
    end
end

function defines.set_function_by_keyword(keyword, func)
    for _, value in pairs(defines.types) do
        if value.keyword == keyword then
            value["func"] = func
        end
    end
end

return defines