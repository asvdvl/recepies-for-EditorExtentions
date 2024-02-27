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
            all_recipes[recipe].enabled = true
        end
    end
end