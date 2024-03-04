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
})