local all_recipes = data.raw.recipe
local start_settings = settings.startup

--recipes for which I can find legal crafting
local defines = require("defines")
local get_energy_value = require("__flib__/data-util").get_energy_value
local utils = require("utils")

-- stdlib is not available for 2.1, so keep the small helpers we used locally
local function table_filter(tbl, predicate)
    local result = {}
    for key, value in pairs(tbl) do
        if predicate(value, key) then
            result[key] = value
        end
    end
    return result
end

local function table_is_empty(tbl)
    return next(tbl) == nil
end

-- 1.1 used {bonus = number} for module effects, 2.0+ uses a plain number
local function effect_bonus(value)
    return type(value) == "table" and value.bonus or value
end

-- recipe item amounts and technology science pack amounts are uint16 in the engine (max 65535)
local MAX_ITEM_AMOUNT = 65535

local recipes = defines.recipes
local lev = utils.log_lev
local overpowered_ingredients = {}

defines.init_items_table(data.raw, start_settings)

--functions for generating recepies
----I decided to make this function as a separate one to make it easier to read
local top_module_crafting_time = 1
local function module_top_items_prepairing(data_raw_category, top_items)
    lev:add()
    utils.log("module_top_items_prepairing")
    local recepie_name
    local effect_value = 0
    local current_data
    top_items.data = defines.balancing_items_table.effect   --this will rewrite the defines table but I don’t care, having 2 tables is useless and leads to code bloat
    local top_items_data = top_items.data

    if start_settings["rfEE_always_overwrite_from_balancing"].value then
        lev:rem()
        return
    end

    for module, module_props in pairs(data_raw_category) do
        lev:add()
        utils.log("module "..module)
        if not defines.recipes[module] then
            for effect_name, v in pairs(module_props.effect) do
                lev:add()

                effect_value = effect_bonus(v)
                utils.log('effect_value: '..effect_value)
                current_data = utils.get_right_table_by_value(effect_value, top_items_data.positive, top_items_data.negative)

                local item_tech = utils.is_item_has_technology(module)
                if current_data[effect_name] and (math.abs(effect_value) > math.abs(current_data[effect_name][2])) and item_tech and item_tech[1] and item_tech[2] then
                    utils.log('effect_value: is > '..tostring(math.abs(current_data[effect_name][2])))

                    current_data[effect_name] = {module, effect_value}
                    recepie_name = item_tech[2]
                    if all_recipes[recepie_name].energy_required > top_module_crafting_time then
                        lev:add()
                        top_module_crafting_time = all_recipes[recepie_name].energy_required
                        utils.log('new module craft time '..tostring(top_module_crafting_time))
                        lev:rem()
                    end
                end
                lev:rem()
            end
        end
        lev:rem()
    end
    lev:rem()
end

--checking that the solution satisfies the condition(for modules)
local function is_solution_are_found(current_effects, top_items_data)
    local top_effect_val
    for effect_name, effect_value in pairs(current_effects) do
        local positive = top_items_data.positive[effect_name]
        local negative = top_items_data.negative[effect_name]
        if positive and negative then
            top_effect_val = utils.get_right_table_by_value(effect_value, positive, negative)
            if math.abs(effect_value)-math.abs(top_effect_val[2]) > 0 then
                return false
            end
        end
    end
    return true
end

local function module_processing(data_raw_category, recipe_object, recipes_table, types_table)
    lev:add()
    utils.log("module_processing work on "..recipe_object.name)
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
        if top_items_data.positive[effect_name] and top_items_data.negative[effect_name] then
            effect_value = effect_bonus(v) --pull out the desired value from the table
            current_effects[effect_name] = effect_value + effect_value*((start_settings["rfEE_recipes_ingredient_increase_percent"].value/100)-1)
        end
    end

    --now we can start looking for the number of items in the recipe
    local amount = 0
    while not is_solution_are_found(current_effects, top_items_data) do
        for effect_name, effect_value in pairs(current_effects) do
            local top_effect_val = utils.get_right_table_by_value(effect_value, top_items_data.positive[effect_name], top_items_data.negative[effect_name])
            if top_effect_val and math.abs(effect_value)-math.abs(top_effect_val[2]) > 0 then
                amount = math.ceil(math.abs(effect_value/top_effect_val[2]))
                if ingridients_raw[top_effect_val[1]] then
                    ingridients_raw[top_effect_val[1]] = ingridients_raw[top_effect_val[1]] + amount
                else
                    ingridients_raw[top_effect_val[1]] = amount
                end

                if data_raw_category[top_effect_val[1]] then
                    for effect_name_2, v in pairs(data_raw_category[top_effect_val[1]].effect) do
                        effect_value_2 = effect_bonus(v)
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
    lev:rem()
end
defines.set_function_by_keyword('modules', module_processing)

local function base_property_stuff(data_raw_category, recipe_object, recipes_table, types_table)
    lev:add()
    utils.log("base_property_stuff work on "..recipe_object.name)
    local max_value_for_target_item = math.abs(utils.find_diff_value(types_table.search_rows, data_raw_category[recipe_object.name]))
    local maxValue = 0
    local search_rows = types_table.search_rows
    if recipes_table.ignore_fields then
        search_rows = table_filter(search_rows, function (v, k)
            return not recipes_table.ignore_fields[k]
        end)
    end

    for _, item in pairs(data_raw_category) do
        lev:add()

        local pairValue = math.abs(utils.find_diff_value(search_rows, item))
        utils.log("comparing to "..item.name.." ("..tostring(pairValue)..")")
        if utils.is_item_NOT_from_EE(item.name)
            and (
                pairValue < max_value_for_target_item   --checking that the item does not have stats higher than those from the EE mod
                and maxValue < pairValue)               --checking that the item has stats greater than those already stored
            and utils.is_item_has_technology(item.name)
        then
            utils.log("better than previous "..tostring(maxValue)..' < '..tostring(pairValue))
            maxValue = pairValue
            types_table.top_items = {item, pairValue}
        end
        lev:rem()
    end
    if #types_table.top_items > 0 then
        local amount = math.ceil(max_value_for_target_item/types_table.top_items[2])

        --data.types_table.top_items
        recipe_object.ingredients = {
            {type="item",
            name=types_table.top_items[1].name,
            amount=amount + amount*((start_settings["rfEE_recipes_ingredient_increase_percent"].value/100)-1)}
        }
    end
    lev:rem()
end
defines.set_function_by_keyword('base_property', base_property_stuff)

--this function falls out of the principle of "code universality" that I adhere to, but I’m tired of putting all these filters in defined.lua
local function item_processing(data_raw_category, recipe_object, recipes_table, types_table)
    lev:add()
    utils.log("item_processing work on "..recipe_object.name)

    if recipes_table.type:find(defines.item_processing_prefix) then
        local fake_data_raw_category = {}
        for item_name, item_table in pairs(data_raw_category) do
            if item_name:find(recipes_table.name_filter) then
                fake_data_raw_category[item_name] = item_table
            end
        end

        recipes_table.top_items = {}
        base_property_stuff(fake_data_raw_category, recipe_object, recipes_table, recipes_table)
    end
    lev:rem()
end
defines.set_function_by_keyword('items', item_processing)

local function defined_stuff(data_raw_category, recipe_object, recipes_table, types_table)
    lev:add()
    utils.log("defined_stuff work on "..recipe_object.name)

    if recipes_table.type == "defined" then
        recipe_object.ingredients = recipes_table.recipe
    else
        log('-----------------------------------------------------------')
        log('recipe category mark as defined but recipe mark as '..recipes_table.type..'! '..recipe_object.name)
        log('-----------------------------------------------------------')
    end
    lev:rem()
end
defines.set_function_by_keyword('defined', defined_stuff)

log('main cycle for apply/calc all recepies')
--main cycle for apply/calc all recepies
lev:add()
for recipe, table in pairs(recipes) do
    local raw_type = utils.find_prototype_category(recipe)
    local types_table = raw_type and defines.types[raw_type]
    if types_table and data.raw[raw_type] and data.raw[raw_type][recipe] and all_recipes[recipe] then
        local func_apply_recipe = types_table.func
        utils.log('recipe '..recipe)
        local success, reason = pcall(func_apply_recipe, data.raw[raw_type], all_recipes[recipe], table, types_table)
        if not success then
            log("error while processing recipe `"..recipe.."`: "..reason)
        end
        if #all_recipes[recipe].ingredients > 0 then
            all_recipes[recipe].enabled = false
        end
    else
        log("recipe `"..recipe.."` prototype not found, skipping")
    end
end
lev:rem()

log('init_balancing_items_table_post_recepies_process')
defines.init_balancing_items_table_post_recepies_process(data.raw, start_settings)

--free not needed variables
top_module_crafting_time = nil
processed_items = nil

log('allowing assemblers to make new recepies')
--allow assemblers to make new recepies
for _, prototype in pairs(data.raw["assembling-machine"]) do
    if prototype.name:find("assembling") then
        table.insert(prototype.crafting_categories, "ee-testing-tool")
    end
end

local energy_source_fields = {["input_flow_limit"]=true}
local recipe_item_template = {type="item", name=defines.balancing_items_table.energy.electric[1], amount=0}
local balancing_items = defines.balancing_items_table.energy.electric
local energy_fields = {
    ["energy_usage"]=true,
    ["energy_per_movement"]=true,
    ["energy_per_rotation"]=true,
    ["power"]=true,
    ["energy_consumption"]=true,
    ["energy_per_move"]=true,
    ["max_power"]=true
}

log('fixing amount of ingridients and fix "free energy items"')
lev:add()
for recipe, recipe_def_table in pairs(recipes) do
    --fixing amount of ingridients
    --there are plans to “fix” too expensive items here
    local max_ingrigient_amount = start_settings["rfEE_max_items_count"].value
    local total_power_req = 0
    for index, recipe_row in pairs(all_recipes[recipe].ingredients) do
        --fix "free energy items", part1, finding how much energy an object needs
        local entity_category = utils.find_prototype_category(recipe_row.name)
        local entity = entity_category and data.raw[entity_category][recipe_row.name] or nil
        local power_req = 0
        if entity and recipe_def_table.type ~= "defined" then
            if entity.energy_source then
                for key in pairs(energy_source_fields) do
                    power_req = power_req + (get_energy_value(entity.energy_source[key] or 0) or 0)
                end
            end
            for key in pairs(energy_fields) do
                power_req = power_req + (get_energy_value(entity[key] or 0) or 0)
            end
        end

        local amount = recipe_row.amount
        if amount > max_ingrigient_amount and (recipe_row.type or "item") ~= "fluid" then
            log('item '..all_recipes[recipe].name..' is too powerfull, '..recipe_row.name..' amount is '..amount..', will be compressed into packs')
            overpowered_ingredients[recipe] = overpowered_ingredients[recipe] or {}
            table.insert(overpowered_ingredients[recipe], {
                index = index,
                name = recipe_row.name,
                amount = amount,
                type = recipe_row.type or "item"
            })
        end
        total_power_req = total_power_req + (power_req * amount)
    end
    --fix "free energy items", part2, actual fixes
    if total_power_req > 0 and not defines.types[utils.find_prototype_category(recipe)].restrict_power_fix then
        utils.log('item '..all_recipes[recipe].name..' power require:'..tostring(total_power_req))
        local new_item = table.deepcopy(recipe_item_template)
        local bal_item = balancing_items[1]
        if total_power_req > bal_item[2] then
            for i = 1, #balancing_items do
                if total_power_req > balancing_items[i][2] then
                    bal_item = balancing_items[i]
                else
                    break
                end
            end
        end

        new_item.name = bal_item[1]
        new_item.amount = math.ceil(total_power_req/bal_item[2])

        if new_item.amount > max_ingrigient_amount then
            new_item.amount = max_ingrigient_amount
        end

        table.insert(all_recipes[recipe].ingredients, new_item)
    end
end
lev:rem()

log('adding items to the technology tree')
--and finally, adding items to the technology tree
lev:add()
for recipe in pairs(recipes) do
    local recipe_proto = all_recipes[recipe]
    local category = utils.find_prototype_category(recipe)
    local item = data.raw.item[recipe] or (category and data.raw[category] and data.raw[category][recipe])
    if recipe_proto and item then
    utils.log('apply tech for '..recipe)
    local ingredients_req = {}
    local ingredients_index = {}
    local prerequisites_set = {}
    local total_count = 10
    local total_time = 10

    local new_tech = {
        type = "technology",
        name = "rfEE_",
        localised_name={"?", {"entity-name."..recipe}, {"item-name."..recipe}, {"equipment-name."..recipe}, },
        localised_description={"?", {"entity-description."..recipe}, {"item-description."..recipe}, {"equipment-description."..recipe}, },
        enabled = false,
        hidden = true,
        effects =
        {
          {
            type = "unlock-recipe",
            recipe = ""
          }
        },
        prerequisites = {},
        unit =
        {
          count = total_count,
          ingredients = ingredients_req, --["automation-science-pack"] = {"automation-science-pack", 1}},  --This is what the final table looks like, using a dictionary simplifies searching through the array
          time = total_time
        },
        order = "z"
    }

    if item and (item.icons or item.icon) then
        new_tech.icons = item.icons or {{icon = item.icon, icon_size = item.icon_size, tint = item.tint}}
    elseif item and item.sprite then
        local sprite = item.sprite
        new_tech.icon = sprite.filename
        new_tech.icon_size = utils.get_right_table_by_value(sprite.height - sprite.width, sprite.width, sprite.height)
        new_tech.icon_mipmaps = 1
        new_tech.tint = sprite.tint
    end
    new_tech.name = new_tech.name..recipe
    new_tech.effects[1].recipe = recipe

    if utils.is_techORrecipe_enabled(all_recipes[recipe]) then
        local item_left = #all_recipes[recipe].ingredients
        for _, ingr_row in pairs(all_recipes[recipe].ingredients) do
            item_left = item_left - 1
            local tech_name_table = utils.is_item_has_technology(ingr_row.name)
            if not tech_name_table and item_left == 0 and table_is_empty(ingredients_req) and defines.types[utils.find_prototype_category(recipe)].fallback_research then
                local ingr_proto = utils.find_prototype_category(recipe)
                --table.insert(new_tech.prerequisites, defines.types[ingr_proto].fallback_research)
                tech_name_table = {defines.types[ingr_proto].fallback_research}
            end
            if tech_name_table and tech_name_table[1] then
                local tech_name = tech_name_table[1]
                local tech = data.raw.technology[tech_name]
                -- the same technology can unlock several ingredients, count it only once
                if tech and tech.unit and not prerequisites_set[tech_name] then
                    prerequisites_set[tech_name] = true
                    total_count = total_count + (tech.unit.count or 0)
                    total_time  = total_time  + (tech.unit.time or 0)
                    table.insert(new_tech.prerequisites, tech_name)
                    for _, tech_science_row in pairs(tech.unit.ingredients or {}) do
                        local science_name = tech_science_row[1]
                        local science_value = tech_science_row[2]
                        local existing = ingredients_index[science_name]
                        if existing then
                            existing[2] = math.min(MAX_ITEM_AMOUNT, existing[2] + science_value)
                        else
                            local row = {science_name, math.min(MAX_ITEM_AMOUNT, science_value)}
                            ingredients_index[science_name] = row
                            table.insert(ingredients_req, row)
                        end
                    end
                end
            end
        end
        local percent = (start_settings["rfEE_recipes_ingredient_increase_percent"].value/100)-1
        new_tech.unit.count = total_count  + total_count*percent
        new_tech.unit.time = total_time  + total_time*percent

        if not table_is_empty(new_tech.unit.ingredients) or start_settings["rfEE_ignore_empty_technologies"].value then
            new_tech.enabled = true
            new_tech.hidden = false
            utils.log(recipe..' enabled. req: '..serpent.block(ingredients_req))

        else
            log('recipe `'..recipe..'` was defined(and ingredients was assigned) but no ingridients for technology')
        end
    elseif start_settings["rfEE_allow_all_items"].value then
        all_recipes[recipe].enabled = true
    else
        log('recipe `'..recipe..'` was defined but ingredients were not assigned')
    end
    data:extend({new_tech})
    end
end
lev:rem()

log('compressing overpowered ingredients into packs')
if next(overpowered_ingredients) then
    -- the engine limit for one item ingredient is uint16 (65535)
    local PACK_FACTOR = MAX_ITEM_AMOUNT
    -- keep the input rate reasonable: 100 items per second at 100% crafting speed
    local PACK_ITEMS_PER_SECOND = 100
    local pack_subgroup = "intermediate-product"
    if data.raw["item-group"]["ee-tools"] then
        pack_subgroup = "rfEE-packs"
        if not data.raw["item-subgroup"]["rfEE-packs"] then
            data:extend({
                {
                    type = "item-subgroup",
                    name = "rfEE-packs",
                    group = "ee-tools",
                    order = "z"
                }
            })
        end
    end

    -- the pack icon is the target item's icon with a tier digit on top
    local function get_target_icons(recipe)
        local tech = data.raw.technology["rfEE_"..recipe]
        if tech and tech.icons then
            return table.deepcopy(tech.icons)
        elseif tech and tech.icon then
            return {{icon = tech.icon, icon_size = tech.icon_size or 64}}
        end
        local category = utils.find_prototype_category(recipe)
        local item = data.raw.item[recipe] or (category and data.raw[category] and data.raw[category][recipe])
        if item then
            if item.icons then
                return table.deepcopy(item.icons)
            end
            if item.icon then
                return {{icon = item.icon, icon_size = item.icon_size or 64}}
            end
        end
        return {{icon = "__base__/graphics/icons/iron-plate.png", icon_size = 64}}
    end

    for recipe, rows in pairs(overpowered_ingredients) do
        local max_amount = start_settings["rfEE_max_items_count"].value
        local target_icons = get_target_icons(recipe)
        for _, row in pairs(rows) do
            local tiers = 0
            local remaining = row.amount
            while remaining > max_amount do
                remaining = math.ceil(remaining / PACK_FACTOR)
                tiers = tiers + 1
            end

            if tiers > 0 then
                local previous_name = row.name
                local previous_type = row.type

                for tier = 1, tiers do
                    local pack_name = "rfEE-"..recipe.."-"..row.name.."-pack-"..tier
                    local pack_icons = table.deepcopy(target_icons)
                    if tier <= 9 then
                        table.insert(pack_icons, {
                            icon = "__base__/graphics/icons/signal/signal_"..tier..".png",
                            icon_size = 64,
                            scale = 0.45,
                            shift = {16, 16}
                        })
                    end

                    local pack_localised_name = {"", {"?", {"entity-name."..recipe}, {"item-name."..recipe}, {"equipment-name."..recipe}}, " ", {"rfee.pack-suffix"}}
                    if tiers > 1 then
                        table.insert(pack_localised_name, " (")
                        table.insert(pack_localised_name, {"rfee.tier-suffix", tostring(tier), tostring(tiers)})
                        table.insert(pack_localised_name, ")")
                    end

                    local pack_item = {
                        type = "item",
                        name = pack_name,
                        icons = pack_icons,
                        subgroup = pack_subgroup,
                        order = "a["..recipe.."]-"..tier,
                        stack_size = 100,
                        localised_name = pack_localised_name
                    }

                    data:extend({
                        pack_item,
                        {
                            type = "recipe",
                            name = pack_name,
                            ingredients = {{type = previous_type, name = previous_name, amount = PACK_FACTOR}},
                            results = {{type = "item", name = pack_name, amount = 1}},
                            enabled = false,
                            energy_required = PACK_FACTOR / PACK_ITEMS_PER_SECOND
                        }
                    })

                    -- unlock the pack together with the item's technology
                    local tech = data.raw.technology["rfEE_"..recipe]
                    if tech then
                        tech.effects = tech.effects or {}
                        table.insert(tech.effects, {type = "unlock-recipe", recipe = pack_name})
                    end

                    -- decompress the pack through the recycler
                    if data.raw["recipe-category"]["recycling"] then
                        local return_amount = PACK_FACTOR
                        local recycling_name = pack_name.."-recycling"
                        data:extend({
                            {
                                type = "recipe",
                                name = recycling_name,
                                localised_name = {"recipe-name.recycling", pack_localised_name},
                                categories = {"recycling"},
                                ingredients = {{type = "item", name = pack_name, amount = 1}},
                                results = {{type = "item", name = previous_name, amount = return_amount}},
                                energy_required = (PACK_FACTOR / PACK_ITEMS_PER_SECOND) / 16,
                                enabled = false,
                                hidden = true,
                                allow_decomposition = false,
                                unlock_results = false,
                                subgroup = pack_subgroup,
                                icons = {
                                    {icon = "__recycler__/graphics/icons/recycling.png"},
                                    {icon = "__recycler__/graphics/icons/recycling-top.png"}
                                }
                            }
                        })
                        if tech then
                            table.insert(tech.effects, {type = "unlock-recipe", recipe = recycling_name})
                        end
                    end

                    previous_name = pack_name
                    previous_type = "item"
                end

                local final_row = all_recipes[recipe].ingredients[row.index]
                final_row.type = "item"
                final_row.name = previous_name
                final_row.amount = math.ceil(row.amount / (PACK_FACTOR ^ tiers))
            end
        end
    end
end

log('adding achievements')
for recipe in pairs(recipes) do
    local item = data.raw.item[recipe]
    local tech = data.raw.technology["rfEE_"..recipe]
    local recipe_proto = all_recipes[recipe]
    if item and ((tech and tech.enabled) or (recipe_proto and recipe_proto.enabled == true)) then
        local achievement = {
            type = "produce-achievement",
            name = "rfEE_"..recipe,
            item_product = recipe,
            amount = 1,
            allowed_without_fight = true,
            limited_to_one_game = false,
            localised_name = {"", {"?", {"entity-name."..recipe}, {"item-name."..recipe}, {"equipment-name."..recipe}}, " ", {"rfee.achievement-suffix"}},
            localised_description = {"rfee.achievement-description", {"?", {"entity-name."..recipe}, {"item-name."..recipe}, {"equipment-name."..recipe}}},
            order = "z"
        }
        if tech and tech.icons then
            achievement.icons = table.deepcopy(tech.icons)
        elseif tech and tech.icon then
            achievement.icon = tech.icon
            achievement.icon_size = tech.icon_size
        elseif item.icons then
            achievement.icons = table.deepcopy(item.icons)
        elseif item.icon then
            achievement.icon = item.icon
            achievement.icon_size = item.icon_size
        else
            achievement.icon = "__base__/graphics/icons/iron-plate.png"
            achievement.icon_size = 64
        end
        data:extend({achievement})
    end
end
