local define = require("defines")
local recipes = define.recipes
local tech_prefix = define.prefixes.mod

local function message_handler()
    if storage.message_was_shown then
        return
    end
    local message = ""  --{""}
    local fixed_recipes = 0
    local pref = define.prefixes
    for recipe in pairs(recipes) do
        local recipe_proto, tech_proto = prototypes.recipe[recipe], prototypes.technology[tech_prefix..recipe]

        if not (recipe_proto and recipe_proto.enabled)                      --if there is no recipe or it is turned off
            and not (tech_proto and tech_proto.enabled)                     --if there is no technology or it is turned off
            and settings.startup[pref.mod..pref.items_ctr..recipe].value    --and the item is enabled in settings
        then
            message = message..'`'..recipe..'`, '
            --disabled because I don’t want to deal with the problem of the translations limit yet
            --[[table.insert(message, key)
            if not (recipe_proto and recipe_proto.enabled) then
                --no recipe and technology as well
                table.insert(message, {"message.no-recipe"})
            else
                --have recipe but no technology
                table.insert(message, {"message.no-tech"})
            end
            table.insert(message, ', ')]]
        else
            --blocking recipes enabled without technology
            for _, force in pairs(game.forces) do
                if recipe_proto and tech_proto then
                    local tech = force.technologies[tech_proto.name]
                    local recip = force.recipes[recipe_proto.name]
                    if tech and recip and not tech.researched and recip.enabled then
                        recip.enabled = false
                        fixed_recipes = fixed_recipes + 1
                    end
                end
            end
        end
    end
    if #message > 1 then
        if settings.global["rfEE_report_missing_items"].value then
            game.print({"", {"rfEE_message.startup-message", message}})
        end
        log({"", {"rfEE_message.startup-message", message}})
    end
    if fixed_recipes > 0 then
        -- no chat notification here on purpose: the fix itself is enough,
        -- the message was only noise for players
        log("rfEE: disabled " .. fixed_recipes .. " recipe(s) that were enabled without a researched technology")
    end
    storage.message_was_shown = true
end

local function reinit()
    storage.message_was_shown = false
end

script.on_init(reinit)
script.on_configuration_changed(reinit)
commands.add_command("rfee-recheck-recipes", {"", "recheck recipes"}, reinit)
script.on_nth_tick(60, message_handler)
