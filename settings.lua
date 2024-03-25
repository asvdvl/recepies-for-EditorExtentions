local defines = require("defines")
local prefixes = defines.prefixes

data:extend({
    {
        type = "bool-setting",
        name = "rfEE_allow_all_items",
        setting_type = "startup",
        default_value = false,
        order = "a"
    },
    {
        type = "int-setting",
        name = "rfEE_max_items_count",
        setting_type = "startup",
        default_value = 65535,
        minimum_value = 1,
        maximum_value = 65535,
        order = "b"
    },
    {
        type = "int-setting",
        name = "rfEE_recipes_ingredient_increase_percent",
        setting_type = "startup",
        default_value = 120,
        minimum_value = 0,
        order = "c"
    },
    {
        type = "string-setting",
        name = "rfEE_type_of_compensation_category",
        setting_type = "startup",
        default_value = "generator-equipment",
        order = "d"
    },
    {
        type = "int-setting",
        name = "rfEE_divider_time_to_craft_overpower_items",
        setting_type = "startup",
        default_value = 1,
        minimum_value = 1,
        order = "e"
    },
    {
        type = "bool-setting",
        name = "rfEE_ignore_empty_technologies",
        setting_type = "startup",
        default_value = false,
        order = "f"
    },
    {
        type = "bool-setting",
        name = "rfEE_debug",
        setting_type = "startup",
        default_value = false,
        order = "f"
    },
    {
        type = "bool-setting",
        name = "rfEE_always_overwrite_from_balancing",
        setting_type = "startup",
        default_value = false,
        order = "x"
    },
})

for effect_sign, effect_names in pairs(defines.balancing_items_table.effect) do
    for effect_name, eff_defined_data in pairs(effect_names) do
        data:extend({
            {
                type = "string-setting",
                name = prefixes.mod..effect_sign..prefixes.balancing..prefixes.name..effect_name,
                setting_type = "startup",
                default_value = eff_defined_data[1],
                minimum_value = prefixes.effect_values[effect_sign][1],
                maximum_value = prefixes.effect_values[effect_sign][2],
                order = "z-"..effect_sign..effect_name..prefixes.name
            },
            {
                type = "double-setting",
                name = prefixes.mod..effect_sign..prefixes.balancing..prefixes.value..effect_name,
                setting_type = "startup",
                default_value = eff_defined_data[2],
                minimum_value = prefixes.effect_values[effect_sign][1],
                maximum_value = prefixes.effect_values[effect_sign][2],
                order = "z-"..effect_sign..effect_name..prefixes.value
            },
        })
        --only needed for automatic generation strings for locale
        --log(prefixes.mod..effect_sign..prefixes.balancing..prefixes.name..effect_name)
        --log(prefixes.mod..effect_sign..prefixes.balancing..prefixes.value..effect_name)
    end
end