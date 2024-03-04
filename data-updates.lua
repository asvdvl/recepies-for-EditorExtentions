local all_recipes = data.raw.recipe
local get_energy_value = require("__flib__/data-util").get_energy_value
--recipes for which I can find legal crafting
local defines = require("defines")
local recipes = defines.recipes

--allows to specify some "code" in a string that is executed here. for example (25, '^2') -> 625
local function perfom_math_from_string(x, multiplier)
    local func, errorMsg = load("return "..x..multiplier)
    if func then
        local status, result = pcall(func)
        if status then
            return result
        else
            error('error when executing expression ('..x..', '..multiplier..') by reason '..result)
            return x
        end
    else
        error('error when executing expression ('..x..', '..multiplier..') by reason '..errorMsg)
        return x
    end
end

--[[
    a function that returns the "sum" of properties for a specified entity,
    to determine how the entity's properties differ from the properties of another entity
]]
local function find_diff_value(search_rows, item)
    local totalSum = 0
    local value = 0
    for row_name, multiplier in pairs(search_rows) do
        if item[row_name] then
            value = 0
            if type(item[row_name]) == "number" then
                value = item[row_name]
            elseif type(item[row_name]) == "string" then
                value = get_energy_value(item[row_name])
            elseif type(item[row_name]) == "boolean" then
                value = 1
            end
            if type(multiplier) == "number" then
                totalSum = totalSum + (value * multiplier)
            elseif type(multiplier) == "string" then
                totalSum = totalSum + perfom_math_from_string(value, multiplier)
            end
        else
            log('property `'..row_name..'` is `'..tostring(item[row_name])..'`. prototype '..item.name)
        end
    end
    return totalSum
end

--functions for generating recepies
local function module_processing(data)
    if not data.types_table.top_items.init then
        data.types_table.top_items.init = true
        data.types_table.top_items.data = {positie = {}, negative = {}}
        for module, module_props in pairs(data.data_raw_category) do
            if not defines.recipes[module] then
                
            end
        end
    end

    data.recipe_object.ingredients = {}
end
defines.set_function_by_keyword('modules', module_processing)

local function base_property_stuff(up_data)
    local max_value_for_target_item = 0
    local maxValue = 0

    for _, item in pairs(up_data.data_raw_category) do
        local pairValue = math.abs(find_diff_value(up_data.types_table.search_rows, item))
        if item.name == up_data.recipe_object.name then
            max_value_for_target_item = pairValue
        elseif pairValue > maxValue and (data.raw.recipe[item.name] and #data.raw.recipe[item.name].ingredients > 0) then    --by some reason, here all_recipes is nil, and idk why
            maxValue = pairValue
            up_data.types_table.top_items = {item, pairValue}
        end
    end

    local amount = math.ceil(max_value_for_target_item/up_data.types_table.top_items[2])
    local max_ingrigient_amount = settings.startup["rfEE_max_items_count"].value
    if amount > max_ingrigient_amount then
        --basicly in plans 
        log('item '..up_data.recipe_object.name..' is too powerfull, calc amount of top ingredients is '..amount..' but allowed only '..max_ingrigient_amount)
        amount = max_ingrigient_amount
    end
    --data.types_table.top_items
    up_data.recipe_object.ingredients = {
        {type="item",
        name=up_data.types_table.top_items[1].name,
        amount=amount}
    }
end
defines.set_function_by_keyword('base_property', base_property_stuff)

--this function falls out of the principle of "code universality" that I adhere to, but I’m tired of putting all these filters in defined.lua
local function item_processing(data)
    if string.find(data.recipes_table.type, defines.item_processing_prefix) then
        local fake_data_raw_category = {}
        for item_name, item_table in pairs(data.data_raw_category) do
            if string.find(item_name, data.recipes_table.name_filter) then
                fake_data_raw_category[item_name] = item_table
            end
        end

        base_property_stuff({
            data_raw_category = fake_data_raw_category,
            recipe_object = data.recipe_object,
            --recipes_table = data.recipes_table,    --not needed
            types_table = data.recipes_table,
        })
    end
end
defines.set_function_by_keyword('items', item_processing)

local function defined_stuff(data)
    if data.recipes_table.type == "defined" then
        data.recipe_object.ingredients = data.recipes_table.recipe
    else
        log('-----------------------------------------------------------')
        log('recipe category mark as defined but recipe mark as '..data.recipes_table.type..'! '..data.recipe_object.name)
        log('-----------------------------------------------------------')
    end
end
defines.set_function_by_keyword('defined', defined_stuff)

--main cycle for apply/calc all recepies
for raw_type, types_table in pairs(defines.types) do
    func_apply_recipe = types_table.func
    for recipe, table in pairs(recipes) do
        if data.raw[raw_type][recipe] then
            func_apply_recipe(
                {
                    data_raw_category = data.raw[raw_type],
                    recipe_object = all_recipes[recipe],
                    recipes_table = table,
                    types_table = types_table,
                })
            if #all_recipes[recipe].ingredients > 0 or settings.startup["rfEE_allow_all_items"].value then
                all_recipes[recipe].enabled = true
            end
        end
    end
end

--allow assemblers to make new recepies
for _, prototype in pairs(data.raw["assembling-machine"]) do
    local _, _, proto_name = string.find(prototype.name, "(.+)-%d+$")
    if proto_name == "assembling-machine" then
        table.insert(prototype.crafting_categories, "ee-testing-tool")
    end
end