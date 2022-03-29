local module = DMod:new("character_n_mask_in_loadout", {
	name = "Character and Mask in loadout menu",
	abbr = "CML",
	version = "1.0.3",
	author = "zneix",
	categories = { "qol" },
	description = {
		english = "Allows you to change your character and the mask in the loadout menu.",
	},
	update = {
		id = "character_n_mask_in_loadout",
		url = "https://cdn.zneix.eu/pdthmods/versions.json",
		notes_url = "https://github.com/zneix/character_n_mask_in_loadout/blob/master/CHANGELOG.md",
	},
})

-- makes sure chat box is always visible in loadout menu (useful in e.g. singleplayer mode)
module:add_config_option("cml_always_show_chat", false)

-- hook to the "kit_menu", which represents the 'loadout menu' - the one you see right before readying up
module:hook("OnMenuSetup", "OnMenuSetup_AddCharAndMaskSelect", "kit_menu", function(self, menu, nodes)
	local character_options = { type = "MenuItemMultiChoice" }
	for _, data in ipairs({
		{ stencil_align_percent = "65", stencil_image = "bg_lobby_fullteam", text_id = "menu_character_random", value = "random" },
		{ stencil_align_percent = "65", stencil_image = "bg_dallas", text_id = "debug_russian", value = "russian" },
		{ stencil_align_percent = "65", stencil_image = "bg_hoxton", text_id = "debug_american", value = "american" },
		{ stencil_align_percent = "55", stencil_image = "bg_wolf", text_id = "debug_german", value = "german" },
		{ stencil_align_percent = "60", stencil_image = "bg_chains", text_id = "debug_spanish", value = "spanish" }
	}) do
		table.insert(character_options, tablex.merge({ _meta = "option", stencil_align = "manual" }, data))
	end

	-- add character selector item
	self:insert_menu_item(nodes.kit, false, { before = "ready" }, {
		name = "choose_character",
		callback = "choice_choose_character",
		-- TODO: Figure out proper visible_callback for this one. For now, it'll just be visible at all times
		-- however, it shouldn't be - if you are dropping in to a game that has already started ypu'll get a random character anyway
		-- visible_callback = "check_choose_character",
		-- visible_callback = "is_dropin",
		text_id = "menu_choose_character",
		menu_name = menu.name,
	}, character_options)

	-- MaskOptionInitiator has to be added as a modifier to kit_menu's node, so it is able to inject options to the "choose_mask" item
	local node_params = nodes.kit:parameters()
	local MaskOptionInitiator = module:hook_class("MaskOptionInitiator")
	local moi = MaskOptionInitiator:new()

	table.insert(node_params.modifier, callback(moi, moi, "modify_node"))

	-- add mask selector item
	self:insert_menu_item(nodes.kit, false, { before = "ready" }, {
		name = "choose_mask",
		callback = "choice_mask",
		text_id = "menu_choose_mask",
		menu_name = menu.name,
	}, { type = "MenuItemMultiChoice" })

	-- make chat visible at all times
	if D:conf("cml_always_show_chat") then
		local chat_item = nodes.kit:item("chat")
		chat_item:parameters().visible_callback = ""
		chat_item._visible_callback_list = {}
		chat_item._visible_callback_name_list = ""
	end
end)

module:hook_post_require("lib/managers/menu/menukitrenderer", function(self_parent)
	local MenuKitRenderer = module:hook_class("MenuKitRenderer")
	-- override original function to also set "multi_choice" items respectively to the ready button instead of having them active all the time
	module:hook(MenuKitRenderer, "set_ready_items_enabled", function(self, enabled)
		if not self._all_items_enabled then
			return
		end
		for _, node in ipairs(self._logic._node_stack) do
			for _, item in ipairs(node:items()) do
				if item:type() == "kitslot" or item:type() == "multi_choice" then
					item:set_enabled(enabled)
				end
			end
		end
	end)
end)

return module
