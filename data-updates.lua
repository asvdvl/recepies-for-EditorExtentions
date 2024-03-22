local all_recipes = data.raw.recipe
local get_energy_value = require("__flib__/data-util").get_energy_value
--recipes for which I can find legal crafting
local defines = require("defines")
local recipes = defines.recipes
defines.init_balancing_items_table(data.raw, settings.startup)
local local_defines = {}
local utils = require("utils")
local is_item_NOT_from_EE = utils.is_item_NOT_from_EE

local_defines.energy_fields = {
    ["energy_usage"]=true,
    ["energy_per_movement"]=true,
    ["energy_per_rotation"]=true,
    ["power"]=true,
    ["energy_consumption"]=true,
    ["energy_per_move"]=true,
    ["max_power"]=true
}

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
                totalSum = totalSum + utils.perfom_math_from_string(value, multiplier)
            end
        else
            log('property `'..row_name..'` is `'..tostring(item[row_name])..'`. prototype `'..item.name..'` (just warning, you can ignore this)')
        end
    end
    return totalSum
end

--functions for generating recepies
----I decided to make this function as a separate one to make it easier to read
local top_module_crafting_time = 1
local function module_top_items_prepairing(data_raw_category, top_items)
    local recepie_name
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
                current_data = utils.get_right_table_by_value(effect_value, top_items_data.positive, top_items_data.negative)

                if not current_data then    --current_data has missing effects, but fallback items shouldn't have them
                    break
                end

                if not current_data[effect_name] or (math.abs(effect_value) > math.abs(current_data[effect_name][2])) then
                    current_data[effect_name] = {module, effect_value}
                    if utils.is_item_has_technology(module) then
                        recepie_name = utils.is_item_has_technology(module)[2]
                        top_module_crafting_time = all_recipes[recepie_name].energy_required
                    end
                end
            end
        end
    end
end

--checking that the solution satisfies the condition(for modules)
local function is_solution_are_found(current_effects, top_items_data)
    local top_effect_val
    for effect_name, effect_value in pairs(current_effects) do
        top_effect_val = utils.get_right_table_by_value(effect_value, top_items_data.positive[effect_name], top_items_data.negative[effect_name])
        if math.abs(effect_value)-math.abs(top_effect_val[2]) > 0 then
            return false
        end
    end
    return true
end

local function module_processing(data_raw_category, recipe_object, recipes_table, types_table)
    --the part where the table of top items is created
    local effect_value, effect_value_2 = 0, 0

    if not types_table.top_items.data then
        module_top_items_prepairing(data_raw_category, types_table.top_items)
    end
    local top_items_data = types_table.top_items.data

    --the part where the actual recipe generation happens
    local ingredients = recipe_object.ingredients
    recipe_object.energy_required = top_module_crafting_time * 2
    local recipe_item_template = {type="item", name="fish", amount=65000}

    --[[
        some combinatorial optimization starts from here,
        if you want to keep your psyche healthy,
        scroll through with your eyes closed(JK)

        I also work only with top_items_data because I don’t want to complicate the already cumbersome code
        and as I know there are solutions through matrices but I don’t want to suffer with it
    ]]
    --First we set the target effect
    local current_effects = {}
    local ingridients_raw = {}
    for effect_name, v in pairs(data_raw_category[recipe_object.name].effect) do
        effect_value = v.bonus --pull out the desired value from the table
        current_effects[effect_name] = effect_value + effect_value*((settings.startup["rfEE_recipes_ingredient_increase_percent"].value/100)-1)
    end

    --now we can start looking for the number of items in the recipe
    local amount = 0
    while not is_solution_are_found(current_effects, top_items_data) do
        for effect_name, effect_value in pairs(current_effects) do
            top_effect_val = utils.get_right_table_by_value(effect_value, top_items_data.positive[effect_name], top_items_data.negative[effect_name])
            if math.abs(effect_value)-math.abs(top_effect_val[2]) > 0 then
                amount = math.ceil(math.abs(effect_value/top_effect_val[2]))
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

    for ingredients_name, amount in pairs(ingridients_raw) do
        local new_item = table.deepcopy(recipe_item_template)
        new_item.name = ingredients_name
        new_item.amount = amount
        table.insert(ingredients, new_item)
    end
end
defines.set_function_by_keyword('modules', module_processing)

local function base_property_stuff(data_raw_category, recipe_object, recipes_table, types_table)
    local max_value_for_target_item = math.abs(find_diff_value(types_table.search_rows, data_raw_category[recipe_object.name]))
    local maxValue = 0

    for _, item in pairs(data_raw_category) do
        local pairValue = math.abs(find_diff_value(types_table.search_rows, item))
        if is_item_NOT_from_EE(item.name)
            and (
                pairValue < max_value_for_target_item   --checking that the item does not have stats higher than those from the EE mod
                and maxValue < pairValue)               --checking that the item has stats greater than those already stored
            and utils.is_item_has_technology(item.name)
        then
            maxValue = pairValue
            types_table.top_items = {item, pairValue}
        end
    end

    local amount = math.ceil(max_value_for_target_item/types_table.top_items[2])

    --data.types_table.top_items
    recipe_object.ingredients = {
        {type="item",
        name=types_table.top_items[1].name,
        amount=amount + amount*((settings.startup["rfEE_recipes_ingredient_increase_percent"].value/100)-1)}
    }
end
defines.set_function_by_keyword('base_property', base_property_stuff)

--this function falls out of the principle of "code universality" that I adhere to, but I’m tired of putting all these filters in defined.lua
local function item_processing(data_raw_category, recipe_object, recipes_table, types_table)
    if string.find(recipes_table.type, defines.item_processing_prefix) then
        local fake_data_raw_category = {}
        for item_name, item_table in pairs(data_raw_category) do
            if string.find(item_name, recipes_table.name_filter) then
                fake_data_raw_category[item_name] = item_table
            end
        end

        base_property_stuff(fake_data_raw_category, recipe_object, recipes_table, recipes_table)
    end
end
defines.set_function_by_keyword('items', item_processing)

local function defined_stuff(data_raw_category, recipe_object, recipes_table, types_table)
    if recipes_table.type == "defined" then
        recipe_object.ingredients = recipes_table.recipe
    else
        log('-----------------------------------------------------------')
        log('recipe category mark as defined but recipe mark as '..recipes_table.type..'! '..recipe_object.name)
        log('-----------------------------------------------------------')
    end
end
defines.set_function_by_keyword('defined', defined_stuff)

--main cycle for apply/calc all recepies
local processed_items = {}  --necessary, because some items can be found more than once (or rather, everything except the actual items)
for raw_type, types_table in pairs(defines.types) do
    func_apply_recipe = types_table.func
    for recipe, table in pairs(recipes) do
        if data.raw[raw_type][recipe] and not processed_items[recipe] then
            func_apply_recipe(data.raw[raw_type], all_recipes[recipe], table, types_table)
            if #all_recipes[recipe].ingredients > 0 or settings.startup["rfEE_allow_all_items"].value then
                all_recipes[recipe].enabled = true  --here will need to assign a technology dependency and the technology itself
            else
                log('recipe `'..recipe..'` was defined but ingredients were not assigned')
            end
            processed_items[recipe] = true
        end
    end
end
defines.init_balancing_items_table_post_recepies_process(data.raw, settings.startup)

--allow assemblers to make new recepies
for _, prototype in pairs(data.raw["assembling-machine"]) do
    local _, _, proto_name = string.find(prototype.name, "(.+)-%d+$")
    if proto_name == "assembling-machine" then
        table.insert(prototype.crafting_categories, "ee-testing-tool")
    end
end

local entity, amount, power_req, total_power_req, new_item = {}, 0, 0, 0, {}
local energy_source_fields = {["input_flow_limit"]=true}
local recipe_item_template = {type="item", name=defines.balancing_items_table.energy.electric[1], amount=0}
local balancing_item_power_output = defines.balancing_items_table.energy.electric[2]
for recipe, recipe_def_table in pairs(recipes) do
    --fixing amount of ingridients
    --there are plans to “fix” too expensive items here
    local max_ingrigient_amount = settings.startup["rfEE_max_items_count"].value
    total_power_req = 0
    for _, recipe_row in pairs(all_recipes[recipe].ingredients) do
        --fix "free energy items", part1, finding how much energy an object needs
        entity = data.raw[utils.find_prototype_category(recipe_row.name)][recipe_row.name]
        power_req = 0
        if recipe_def_table.type ~= "defined" then
            if entity.energy_source then
                for key in pairs(energy_source_fields) do
                    power_req = power_req + (get_energy_value(entity.energy_source[key] or 0) or 0)
                end
            end
            for key in pairs(local_defines.energy_fields) do
                power_req = power_req + (get_energy_value(entity[key] or 0) or 0)
            end
        end

        amount = recipe_row.amount
        if amount > max_ingrigient_amount then
            --basicly in plans 
            log('item '..all_recipes[recipe].name..' is too powerfull, calc amount of top ingredient '..recipe_row.name..' is '..amount..' but allowed only `'..max_ingrigient_amount)
            all_recipes[recipe].energy_required = amount / settings.startup["rfEE_divider_time_to_craft_overpower_items"].value
            amount = max_ingrigient_amount
        end
        recipe_row.amount = amount
        total_power_req = total_power_req + (power_req * amount)
    end
    --fix "free energy items", part2, actual fixes
    if total_power_req > 0 and not defines.types[utils.find_prototype_category(recipe)].restrict_power_fix then
        log('item '..all_recipes[recipe].name..' power require:'..tostring(total_power_req))

        new_item = table.deepcopy(recipe_item_template)
        new_item.amount = math.ceil(total_power_req/balancing_item_power_output)

        if new_item.amount > max_ingrigient_amount then
            new_item.amount = max_ingrigient_amount
        end

        table.insert(all_recipes[recipe].ingredients, new_item)
    end
end