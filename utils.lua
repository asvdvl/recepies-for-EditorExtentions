local utils = {}
local defines = require("defines")
local all_technologies = data.raw.technology
local all_recipes = data.raw.recipe
local local_defines = {}

--need for checking that we are not working with an item from the EE mod
function utils.is_item_NOT_from_EE(item_name)
    return defines.recipes[item_name] or string.sub(item_name, 1, 3) ~= "ee-"
end

--allows to specify some "code" in a string that is executed here. for example (25, '^2') -> 625
function utils.perfom_math_from_string(x, multiplier)
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

--{item-name=tech-name}
--true means item enabled by default
local tech_cache = {}

--the task is to find the “unlock-recipe” type from the effects of technology, and in it the desired item in the recipe
function utils.is_item_has_technology(item_name)
    if tech_cache[item_name] then
        log('tech cache hit! yey!')
        return tech_cache[item_name]    --I don’t know for sure whether it will be needed more than once, I left it just in case
    end

    for tech_name, tech in pairs(all_technologies) do
        if tech.effects then
            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" then
                    local recipe = all_recipes[effect.recipe]
                    if recipe.result and recipe.result == item_name then
                        tech_cache[item_name] = tech_name
                        return tech_name
                    elseif recipe.results then
                        for _, results in pairs(recipe.results) do
                            if results.name == item_name then
                                return tech_name
                            end
                        end
                    end
                end
            end
        end
    end

    --The game has items that are enabled by default
    if all_recipes[item_name] and (all_recipes[item_name].enabled or type(all_recipes[item_name].enabled) == "nil") then  --WTF?! Why do some recipes that are enabled first have enabled = true and some do not?!
        tech_cache[item_name] = true
        return true
    else
        --hello wube, i love you...
        --some recipes have a different name than the result,
        --I'm just wondering how the game determines the amount of raw resources in runtime? builds a table of items->recipes where is it?
        for _, recipe in pairs(all_recipes) do
            if recipe.result == item_name and (recipe.enabled or type(recipe.enabled) == "nil") then
                tech_cache[item_name] = true
                return true
            elseif recipe.results and (recipe.enabled or type(recipe.enabled) == "nil") then
                for _, results in pairs(recipe.results) do
                    if results.name == item_name then
                        tech_cache[item_name] = true
                        return true
                    end
                end
            end
        end
    end

    return false
end

function utils.get_right_table_by_value(value, pos_data, neg_data)
    if value >= 0 then
        return pos_data
    elseif value < 0 then
        return neg_data
    end
end

--a hash tables is used here for a quick search; the fields can have any value
local_defines.fpc_delay_this_categories = {
    ["item"] = true,
}
local_defines.fpc_blacklist_categories = {
    ["recipe"] = true,
    ["font"] = true,
    ["noise-layer"] = true,
    ["gui-style"] = true,
    ["utility-constants"] = true,
    ["utility-sounds"] = true,
    ["sprite"] = true,
    ["utility-sprites"] = true,
    ["god-controller"] = true,
    ["editor-controller"] = true,
    ["spectator-controller"] = true,
    ["noise-expression"] = true,
    ["mouse-cursor"] = true,
    ["custom-input"] = true,
    ["item-with-entity-data"] = true,
    ["technology"] = true,
}

--fpc = find_prototype_category
local fpc_cache, fpc_delayed = {}, {}
local function find_prototype_category_logic(category_name, category_data, item_name)
    if not local_defines.fpc_blacklist_categories[category_name] then
        if category_data[item_name] then
            if not fpc_cache[item_name] then
                fpc_cache[item_name] = {category_name}
            else
                table.insert(fpc_cache[item_name], category_name)
            end
            return true
        end
    end
end

function utils.find_prototype_category(item_name)
    if fpc_cache[item_name] then
        return fpc_cache[item_name][1]  --here return only 1 
    end

    for category_name, category_data in pairs(data.raw) do
        if not local_defines.fpc_delay_this_categories[category_name] then
            find_prototype_category_logic(category_name, category_data, item_name)
        else
            fpc_delayed[category_name] = true
        end
    end

    for category_name, _ in pairs(fpc_delayed) do
        find_prototype_category_logic(category_name, data.raw[category_name], item_name)
    end
    if fpc_cache[item_name] then
        return fpc_cache[item_name][1]  --here return only 1 
    end
end

return utils