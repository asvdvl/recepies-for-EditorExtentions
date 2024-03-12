local all_recipes = data.raw.recipe
local get_energy_value = require("__flib__/data-util").get_energy_value
--recipes for which I can find legal crafting
local defines = require("defines")
local recipes = defines.recipes
defines.init_balancing_items_table(data.raw, settings.startup)

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
            log('property `'..row_name..'` is `'..tostring(item[row_name])..'`. prototype `'..item.name..'` (just warning, you can ignore this)')
        end
    end
    return totalSum
end

local function is_item_has_craft(item_name)
    --by some reason, here all_recipes is nil, and idk why
    all_recipes = data.raw.recipe
    if all_recipes[item_name] and #all_recipes[item_name].ingredients > 0 then
        return true
    else
        --hello wube, i love you...
        for _, recipe in pairs(all_recipes) do
            if recipe.result == item_name then
                return true
            elseif recipe.results then
                for _, results in pairs(recipe.results) do
                    if results.name == item_name then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function get_right_table_by_value(value, pos_data, neg_data)
    if value > 0 then
        return pos_data
    elseif value < 0 then
        return neg_data
    end
end

--functions for generating recepies
----I decided to make this function as a separate one to make it easier to read
local function module_top_items_prepairing(data_raw_category, top_items)
    local effect_value = 0
    local current_data
    top_items.data = defines.balancing_items_table.effect   --this will rewrite the defines table but I don’t care, having 2 tables is useless and leads to code bloat
    local top_items_data = top_items.data

    if settings.startup["rfEE_always_overwrite_from_balancing"].value then
        return
    end

    for module, module_props in pairs(data_raw_category) do
        if not defines.recipes[module] then
            for effect_name, v in pairs(module_props.effect) do
                effect_value = v.bonus
                current_data = get_right_table_by_value(effect_value, top_items_data.positive, top_items_data.negative)

                if not current_data then    --current_data has missing effects, but fallback items shouldn't have them
                    break
                end

                if not current_data[effect_name] or (math.abs(effect_value) > math.abs(current_data[effect_name][2])) then
                    current_data[effect_name] = {module, effect_value}
                end
            end
        end
    end
end

--checking that the solution satisfies the condition
local function is_solution_are_found(current_effects, top_items_data)
    local top_effect_val
    for effect_name, effect_value in pairs(current_effects) do
        top_effect_val = get_right_table_by_value(effect_value, top_items_data.positive[effect_name], top_items_data.negative[effect_name])
        if math.abs(effect_value)-math.abs(top_effect_val[2]) > 0 then
            return false
        end
    end
    return true
end

local function module_processing(m_data)
    --the part where the table of top items is created
    local effect_value, effect_value_2 = 0, 0
    local data_raw_category = m_data.data_raw_category
    local recipe_object = m_data.recipe_object
    local types_table = m_data.types_table

    if not types_table.top_items.data then
        module_top_items_prepairing(data_raw_category, types_table.top_items)
    end
    local top_items_data = types_table.top_items.data

    --the part where the actual recipe generation happens
    local ingredients = recipe_object.ingredients
    local recipe_item_template = {type="item", name="fish", amount=65000}

    --[[
        some combinatorial optimization starts from here,
        if you want to keep your psyche healthy,
        scroll through with your eyes closed(JK)

        I also work only with top_items_data because I don’t want to complicate the already cumbersome code
    ]]
    --First we set the target effect
    local current_effects = {}
    local ingridients_raw = {}
    for effect_name, v in pairs(data_raw_category[recipe_object.name].effect) do
        effect_value = v.bonus --pull out the desired value from the table
        current_effects[effect_name] = effect_value
    end

    local amount = 0
    while not is_solution_are_found(current_effects, top_items_data) do
        for effect_name, effect_value in pairs(current_effects) do
            top_effect_val = get_right_table_by_value(effect_value, top_items_data.positive[effect_name], top_items_data.negative[effect_name])
            if math.abs(effect_value)-math.abs(top_effect_val[2]) > 0 then
                amount = math.ceil(math.abs(top_effect_val[2]/effect_value))
                if ingridients_raw[top_effect_val[1]] then
                    ingridients_raw[top_effect_val[1]] = ingridients_raw[top_effect_val[1]] + amount
                else
                    ingridients_raw[top_effect_val[1]] = amount
                end

                if data_raw_category[top_effect_val[1]] then
                    for effect_name_2, v in pairs(data_raw_category[top_effect_val[1]].effect) do
                        effect_value_2 = v.bonus
                        current_effects[effect_name_2] = (current_effects[effect_name_2] or 0) - (effect_value_2*amount)
                    end
                else
                    current_effects[effect_name] = current_effects[effect_name] - (top_effect_val[2]*amount)
                end
            end
        end
    end
    amount = nil

    for ingredients_name, amount in pairs(ingridients_raw) do
        local new_item = table.deepcopy(recipe_item_template)
        new_item.name = ingredients_name
        new_item.amount = amount
        table.insert(ingredients, new_item)
    end
end
defines.set_function_by_keyword('modules', module_processing)

local function base_property_stuff(up_data)
    local max_value_for_target_item = math.abs(find_diff_value(up_data.types_table.search_rows, up_data.data_raw_category[up_data.recipe_object.name]))
    local maxValue = 0

    for _, item in pairs(up_data.data_raw_category) do
        local pairValue = math.abs(find_diff_value(up_data.types_table.search_rows, item))
        if string.sub(item.name, 1, 3) ~= "ee-"         --checking that we are not working with an item from the EE mod
            and (
                pairValue < max_value_for_target_item   --checking that the item does not have stats higher than those from the EE mod
                and maxValue < pairValue)               --checking that the item has stats greater than those already stored
            and is_item_has_craft(item.name)
        then
            maxValue = pairValue
            up_data.types_table.top_items = {item, pairValue}
        end
    end

    local amount = math.ceil(max_value_for_target_item/up_data.types_table.top_items[2])

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
            func_apply_recipe(  --the only reason why I put everything in a table is that in functions I can simply pull out the data that I need without fiddling with input variables
                {
                    data_raw_category = data.raw[raw_type],
                    recipe_object = all_recipes[recipe],
                    recipes_table = table,
                    types_table = types_table,
                })
            if #all_recipes[recipe].ingredients > 0 or settings.startup["rfEE_allow_all_items"].value then
                all_recipes[recipe].enabled = true
            else
                log('recipe `'..recipe..'` was defined but ingredients were not assigned')
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

--fixing amount of ingridients(there are plans to “fix” too expensive items here)
for recipe, table in pairs(recipes) do
    local max_ingrigient_amount = settings.startup["rfEE_max_items_count"].value
    for _, recipe_row in pairs(all_recipes[recipe].ingredients) do
        local amount = recipe_row.amount
        if amount > max_ingrigient_amount then
            --basicly in plans 
            log('item '..all_recipes[recipe].name..' is too powerfull, calc amount of top ingredient '..recipe_row.name..' is '..amount..' but allowed only `'..max_ingrigient_amount)
            amount = max_ingrigient_amount
        end
        recipe_row.amount = amount
    end
end