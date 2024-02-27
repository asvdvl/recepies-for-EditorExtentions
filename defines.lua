local defines = {}

defines.recipes = {
    --logistic
    ["ee-linked-belt"]={
        ["type"]="defined",
        ["recipe"]={
            {type="item", name="logistic-chest-passive-provider", amount=1},
            {type="item", name="logistic-chest-requester", amount=1},
            {type="item", name="ee-super-logistic-robot", amount=1},
            {type="item", name="express-transport-belt", amount=2},

        }},
    ["ee-linked-chest"]={
        ["type"]="defined",
        --According to my calculations, using 1 super inserters you can achieve a speed of 360 items per second using these chests! therefore, 360/45 = 8, also multiply by 4 sides and get 32 conveyors!
        ["recipe"]={
            {type="item", name="ee-linked-belt", amount=32},
            {type="item", name="steel-chest", amount=2},
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
    ["linked-belt"] =
        {['keyword'] = "defined"},

    ["linked-container"] =
        {['keyword'] = "defined"},

    ["module"] =
        {['search_rows'] = {'effect'}},

    ["electric-pole"] =
        {['search_rows'] = {"maximum_wire_distance", "supply_area_distance"}},

    ["inserter"] =
        {['search_rows'] = {"extension_speed", "rotation_speed"}},

    ["radar"] =
        {['search_rows'] = {"max_distance_of_sector_revealed", "max_distance_of_nearby_sector_revealed"}},

    ["lab"] =
        {['search_rows']={"researching_speed"}},

    ["roboport"] =
        {['search_rows'] = {"logistics_radius", "construction_radius"}},

    ["pump"] =
        {['search_rows'] = {"pumping_speed"}},

    ["beacon"] =
        {['search_rows'] = {"supply_area_distance"}},

    ["locomotive"] =
        {['search_rows'] = {"max_speed", "max_power"}},

    ["construction-robot"] =
        {['search_rows'] = {"max_payload_size", "speed"}},

    ["logistic-robot"] =
        {['search_rows'] = {"max_payload_size", "speed"}},

    ["night-vision-equipment"] =
        {},

    ["energy-shield-equipment"] =
        {['search_rows'] = {"max_shield_value"}},

    ["battery-equipment"] =
        {['search_rows'] = {"energy_source", "buffer_capacity"}},

    ["generator-equipment"] =
        {['search_rows'] = {"power"}},

    ["roboport-equipment"] =
        {['search_rows'] = {"construction_radius"}},

    ["movement-bonus-equipment"] =
        {['search_rows'] = {"movement_bonus"}},
}

for _, value in pairs(defines.types) do
    value["func"] = empty_function
    value["top_items"] = {}
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