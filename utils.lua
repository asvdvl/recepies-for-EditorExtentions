local utils = {}
local defines = require("defines")
local get_energy_value = require("__flib__/data-util").get_energy_value
local all_technologies = data.raw.technology
local all_recipes = data.raw.recipe
local local_defines = {}

--- need for checking that we are not working with an item from the EE mod
--- @param item_name string input item name for checking
--- @return table|number|nil
function utils.is_item_NOT_from_EE(item_name)
    return defines.recipes[item_name] or string.sub(item_name, 1, 3) ~= "ee-"
end

--- allows to specify some "code" in a string that is executed here. for example (25, '^2') -> 625
--- @param x integer|string
--- @param multiplier integer|string
--- @return integer
function utils.perfom_math_from_string(x, multiplier)
    local func, errorMsg = load("return "..x..multiplier)
    if func then
        local status, result = pcall(func)
        if status then
            return result
        else
            error('error when executing expression ('..x..', '..multiplier..') by reason '..result)
        end
    else
        error('error when executing expression ('..x..', '..multiplier..') by reason '..errorMsg)
    end
end

--{item-name={tech-name, recipe-name}}
--true means item enabled by default
local tech_cache = {}

--the task is to find the “unlock-recipe” type from the effects of technology, and in it the desired item in the recipe
--- @param proto_name string input item(or entity) name for checking
--- @return table<string|boolean, string>|boolean {tech-name, recipe-name}; true means item enabled by default
function utils.is_item_has_technology(proto_name)
    if tech_cache[proto_name] then
        return tech_cache[proto_name]    --I don’t know for sure whether it will be needed more than once, I left it just in case
    end

    for tech_name, tech in pairs(all_technologies) do
        if tech.effects then
            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" then
                    local recipe = all_recipes[effect.recipe]
                    if recipe then
                        local results = recipe.results or (recipe.normal and recipe.normal.results) or (recipe.expensive and recipe.expensive.results)
                        if (recipe.result or (recipe.normal and recipe.normal.result) or (recipe.expensive and recipe.expensive.result)) == proto_name then
                            tech_cache[proto_name] = {tech_name, recipe.name}
                            return tech_cache[proto_name]
                        elseif results then
                            for _, results in pairs(results) do
                                if results.name == proto_name then
                                    tech_cache[proto_name] = {tech_name, recipe.name}
                                    return tech_cache[proto_name]
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    --The game has items that are enabled by default
    --{false, item_name} because there is no technology but there is a recipe
    if all_recipes[proto_name] and (all_recipes[proto_name].enabled or type(all_recipes[proto_name].enabled) == "nil") then  --WTF?! Why do some recipes that are pre-enabled have enabled = true and some do not?!
        tech_cache[proto_name] = {false, proto_name}
        return tech_cache[proto_name]
    else
        --hello wube, i love you...
        --some recipes have a different name than the result,
        --I'm just wondering how the game determines the amount of raw resources in runtime? builds a table of items->recipes where is it?
        for _, recipe in pairs(all_recipes) do
            if recipe.result == proto_name and (recipe.enabled or type(recipe.enabled) == "nil") then
                tech_cache[proto_name] = {false, proto_name}
                return tech_cache[proto_name]
            elseif recipe.results and (recipe.enabled or type(recipe.enabled) == "nil") then
                for _, results in pairs(recipe.results) do
                    if results.name == proto_name then
                        tech_cache[proto_name] = {false, proto_name}
                        return tech_cache[proto_name]
                    end
                end
            end
        end
    end

    return false
end

--- small function to select from 2 tables
--- @param value integer
--- @param pos_data any
--- @param neg_data any
--- @return any
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

--- @param item_name string input item name for find category
--- @return string|nil category-name
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

--- function for splitting strings of the form "table/subtable" -> {"table", "subtable"}
--- @param str string input string
--- @param sep string separator
--- @return table 
function utils.split(str, sep)
    local result = {}
    for token in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, token)
    end
    return result
end

--[[
    a function that returns the "sum" of properties for a specified entity,
    to determine how the entity's properties differ from the properties of another entity
]]
--- @param search_rows table table of string from defines
--- @param item table working item
--- @return integer|number 
function utils.find_diff_value(search_rows, item)
    local totalSum = 0
    local value = 0
    local row, subrow, parts
    for row_name, multiplier in pairs(search_rows) do
        if row_name:find("/") then
            --I'm too lazy to implement a recursive property lookup, so we'll limit ourselves to only level 2
            parts = utils.split(row_name, "/")
            subrow = item[parts[1]]
            if subrow then
                row = subrow[parts[2]]
            end
        else
            row = item[row_name]
        end
        if row then
            value = 0
            if type(row) == "number" then
                value = row
            elseif type(row) == "string" then
                value = get_energy_value(row) or tostring(row) or 0
            elseif type(row) == "boolean" then
                value = 1
            end
            if type(multiplier) == "number" then
                totalSum = totalSum + (value * multiplier)
            elseif type(multiplier) == "string" then
                totalSum = totalSum + utils.perfom_math_from_string(value, multiplier)
            end
        else
            log('property `'..row_name..'` is `'..tostring(row)..'`. prototype `'..item.name..'` (just warning, you can ignore this)')
        end
    end
    return totalSum
end

--- checks that the table is sorted using the comp function
--- @param array table
--- @param comp function(a, b): boolean
--- @return boolean
function utils.is_sorted(array, comp)
    if #array == 1 then
        return true
    end
    for i = 2, #array do
        if not comp(array[i-1], array[i]) then
            return false
        end
    end
    return true
end

local is_debug = settings.startup["rfEE_debug"].value
utils.log_lev = {
    v = 0,
    add = function (self, v)
        self.v = self.v + (v or 1)
    end,
    rem = function (self, v)
        self.v = self.v - (v or 1)
    end,
    set = function (self, v)
        self.v = v
    end,
}
if type(__DebugAdapter) == "table" then
    is_debug = true
    log('detect debug adapter, logs enabled')
end
--- custom logging
--- @param message string|nil
function utils.log(message)
	if is_debug then
        log(string.rep('|-', utils.log_lev.v)..message)
    end
end

function utils.is_techORrecipe_enabled(tech_or_recipe)
    assert(type(tech_or_recipe)=="table", "wrong type! must be table")
    if tech_or_recipe.type == "technology" then
        local f1 = type(tech_or_recipe.enabled) == "nil" or (type(tech_or_recipe.enabled) == "boolean" and tech_or_recipe.enabled)
        local f2 = not tech_or_recipe.hidden == true
        return f1 and f2
    elseif tech_or_recipe.type == "recipe" then
        local recipe = tech_or_recipe
        local f1 = type(recipe.enabled) == "nil" or (type(recipe.enabled) == "boolean" and recipe.enabled)
        local ingredients = recipe.ingredients or (recipe.normal and recipe.normal.ingredients) or (recipe.expensive and recipe.expensive.ingredients)
        local results = recipe.results or (recipe.normal and recipe.normal.results) or (recipe.expensive and recipe.expensive.results) or (recipe.result and {recipe.result})
        if not f1 and utils.is_item_has_technology(results[1]) then
            f1 = utils.is_item_has_technology(results[1])[1] ~= false      --i just hope that recipe.name == recipe.result because i want to release this mod
        end
        local f2 = #(ingredients) > 0
        return f1 and f2
    end
end

return utils