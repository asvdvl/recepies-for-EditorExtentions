local defines = {}

defines.recipes = {
    --logistic
    ["ee-linked-belt"]={
        ["type"]="defined",
        ["recipe"]={
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
        ["type"]="defined",
        --[[
            According to my calculations, using 1 super inserters you can achieve a speed of 360 items per second using these chests!
            therefore, 360/45 = 8, also multiply by 4 sides and get 32 conveyors!
            But i give off 75% price for motivating build that massive unloaders!
        ]]
        ["recipe"]={
            {type="item", name="ee-linked-belt", amount=8},
            {type="item", name="steel-chest", amount=1},
        }},
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

for _, value in pairs(defines.recipes) do
    if value.type ~= "defined" then
        value.type = "generated"
        value.recipe = {}
    end
end

local function empty_function(...) log('empty_function call detected! this shouldnt have happened! params: '..serpent.block({...})) end

defines.types = {
    --defined
    ["linked-belt"] = {
        ['keyword'] = "defined"
    },

    ["linked-container"] = {
        ['keyword'] = "defined"
    },

    --simply_property
    ["construction-robot"] = {
        ['keyword'] = "simply_property",
        ['search_rows'] = {"max_payload_size", "speed"}
    },

    ["logistic-robot"] = {
        ['keyword'] = "simply_property",
        ['search_rows'] = {"max_payload_size", "speed"}
    },

    ["inserter"] = {
        ['keyword'] = "simply_property",
        ['search_rows'] = {"rotation_speed", "stack"}
    },

    ["lab"] = {
        ['keyword'] = "simply_property",
        ['search_rows']={"researching_speed"}
    },

    ["pump"] = {
        ['keyword'] = "simply_property",
        ['search_rows'] = {"pumping_speed"}
    },

    ["energy-shield-equipment"] = {
        ['keyword'] = "simply_property",
        ['search_rows'] = {"max_shield_value"}
    },

    ["movement-bonus-equipment"] = {
        ['keyword'] = "simply_property",
        ['search_rows'] = {"movement_bonus"}
    },
    --other
    ['item'] = {

    },

    ["module"] = {
        ['search_rows'] = {'effect'}
    },

    ["electric-pole"] = {
        ['search_rows'] = {"maximum_wire_distance", "supply_area_distance"}
    },


    ["radar"] = {
        ['search_rows'] = {"max_distance_of_sector_revealed", "max_distance_of_nearby_sector_revealed"}
    },


    ["roboport"] = {
        ['search_rows'] = {"logistics_radius", "construction_radius"}
    },


    ["beacon"] = {
        ['search_rows'] = {"supply_area_distance"}
    },

    ["locomotive"] = {
        ['search_rows'] = {"max_speed", "max_power"}
    },

    ["night-vision-equipment"] = {},


    ["battery-equipment"] = {
        ['search_rows'] = {"energy_source", "buffer_capacity"}
    },

    ["generator-equipment"] = {
        ['search_rows'] = {"power"}
    },

    ["roboport-equipment"] = {
        ['search_rows'] = {"construction_radius"}
    },


}

for _, value in pairs(defines.types) do
    value.func = empty_function
    value.top_items = {}
    value.top_items.init = false
    value.top_items.data = {}

    if not value['search_rows'] then
        value['search_rows'] = {}
    end

    if not value['keyword'] then
        value['keyword'] = ""
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