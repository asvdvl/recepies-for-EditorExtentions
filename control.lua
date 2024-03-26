local define = require("defines")
local recipes = define.recipes
local tech_prefix = define.prefixes.mod

local function message_handler()
    if global.message_was_shown then
        return
    end
    local message = ""
    for key in pairs(recipes) do
        local recipe_proto, tech_proto = game.recipe_prototypes[key], game.technology_prototypes[tech_prefix..key]
        if not (recipe_proto and recipe_proto.enabled) or (tech_proto and not tech_proto.enabled) then
            message = message..'`'..key..'`, '
        end
    end
    if #message > 0 then
        game.print({"", {"message.startup-message-base"}, message, {"message.startup-message-end"}})
        log({"", {"message.startup-message-base"}, message, {"message.startup-message-end"}})
    end
    global.message_was_shown = true
end

local function reinit()
    global.message_was_shown = false
end

script.on_init(reinit)
script.on_configuration_changed(reinit)
script.on_nth_tick(60, message_handler)
