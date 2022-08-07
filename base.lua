local mod_id = "character_n_mask_in_loadout"
return DMod:new(mod_id, {
	name = "Character and Mask in loadout menu",
	abbr = "CML",
	version = "1.1.0",
	author = "zneix",
	categories = { "qol" },
	description = {
		english = "Allows you to change your character and the mask in the loadout menu.",
	},
	update = {
		id = mod_id,
		url = "https://cdn.zneix.eu/pdthmods/versions.json",
	},
	--config_prefix = "cml",
	config = {
		-- makes sure chat box is always visible in loadout menu (useful in e.g. singleplayer mode)
		{ "cml_always_show_chat", false },
	},
	hooks = {
		{
			-- add things of our interest to the "kit_menu" (the 'loadout menu' - one you see right before readying up)
			"event", "OnMenuSetup", "OnMenuSetup_AddCharAndMaskSelect", "kit_menu", function(self, menu, nodes)
				local module = D:module(mod_id)
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
			end
		},
		{
			"post_require", "lib/managers/menu/menukitrenderer", function(module)
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
			end
		},
		{
			"post_require", "lib/managers/criminalsmanager", function(module)
				local CriminalsManager = module:hook_class("CriminalsManager")
				-- TODO: update character and mask of a player
				module:post_hook(CriminalsManager, "add_character", function(self, name, unit, peer_id, ai)
					for id, data in pairs(self._characters) do
						if data.name == name then
							data.unit = unit
							data.peer_id = peer_id or 0
							data.data.ai = ai or false
							local mask_set = self:_get_mask_set(data)
							-- if tweak_data.mask_sets[mask_set or false] == nil then
							--     mask_set = "clowns"
							-- end
							Util:say_to_chat(string.format("add_character: #%d, %s%s, mask: %s",
								peer_id or "0",
								name,
								ai and " [[AI]" or "",
								tostring(mask_set) or "?"
							), false, "DEBUG")
						end
					end
				end)
			end
		},
	},
})
