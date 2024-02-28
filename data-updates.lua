local all_recipes = data.raw.recipe

--recipes for which I can find legal crafting
local defines = require("defines")
local recipes = defines.recipes

--find all other recepies
if settings.startup["rfEE_allow_all_items"].value then
    for key, value in pairs(all_recipes) do
        if value.category == "ee-testing-tool" then
            if not recipes[key] then
                value.enabled = true    --now I just turn it on, no more actions
                log('found recipe '..key..' that was not found in definitions')
            end
        end
    end
end

--functions for generating recepies
function module_processing(data)
    data.recipe_object.ingredients = {}
end

function base_simply_property_stuff(data)
    --should be rewriten for dynamic properties support
    local function find_diff_value(search_rows, item)
        if #search_rows == 1 then
            pairValue = item[search_rows[1]]
        else
            pairValue = item[search_rows[1]] + item[search_rows[2]]
        end
        return pairValue
    end
    local max_value_for_target_item = 0
    if not data.types_table.top_items.init then
        local maxValue = 0
        for _, item in pairs(data.data_raw_category) do
            local pairValue = math.abs(find_diff_value(data.types_table.search_rows, item))
            if item.name == data.recipe_object.name then
                max_value_for_target_item = pairValue
            elseif pairValue > maxValue then
                maxValue = pairValue
                data.types_table.top_items.data = {item, pairValue}
            end
        end
    end
    local amount = math.ceil(max_value_for_target_item/data.types_table.top_items.data[2])
    if amount > 65535 then
        amount = 65535
    end
    --data.types_table.top_items.data
    data.recipe_object.ingredients = {
        {type="item",
        name=data.types_table.top_items.data[1].name,
        amount=amount}
    }
end
defines.set_function_by_keyword('simply_property', base_simply_property_stuff)

function defined_stuff(data)
    if data.define_recipe_table.type == "defined" then
        data.recipe_object.ingredients = data.define_recipe_table.recipe
    else
        log('recepie category mark as defined but recepy is not! '..data.recipe_object.name)
    end
end
defines.set_function_by_keyword('defined', defined_stuff)

for raw_type, types_table in pairs(defines.types) do
    func_apply_recipe = types_table.func
    for recipe, table in pairs(recipes) do
        if data.raw[raw_type][recipe] then
            func_apply_recipe(
                {
                    ["data_raw_category"] = data.raw[raw_type],
                    ["recipe_object"] = all_recipes[recipe],
                    ["define_recipe_table"] = table,
                    ["types_table"] = types_table,
                })
            if #all_recipes[recipe].ingredients > 0 then
                all_recipes[recipe].enabled = true
            end
        end
    end
end