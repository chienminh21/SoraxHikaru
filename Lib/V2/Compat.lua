-- Lib/V2/Compat.lua
-- Lets code written for UI v1 run on v2: window:create_tab(title, icon):create_module{...} becomes a feature card and
-- create_checkbox / create_slider / create_dropdown / create_button / create_divider / create_paragraph / create_text
-- keep their v1 arguments and callbacks. Other v1 controls are reported, not silently dropped.
-- Differences: a module toggle is a feature switch (startup state comes from its settings, not the saved v1 flag),
-- and multi-select dropdowns are not supported yet.

local Compat = {}

local function unsupported(name)
    return function()
        warn("[Sora x Hikaru] UI v2: " .. name .. " is not available in v2 yet and was skipped")
        return {}
    end
end

function Compat.apply(window)
    function window:create_tab(title, icon)
        local tab = self:AddTab(title, icon)
        local v1Tab = { Native = tab }

        function v1Tab:create_module(settings)
            settings = settings or {}
            local card = tab:AddFeature({
                Id = settings.flag,
                Name = settings.title or "Module",
                Description = settings.description or "",
                Callback = settings.callback,
                Setting = true,
                Notification = true,
                Column = settings.section == "right" and 2 or 1,
            })

            local module = { Native = card }

            function module:create_checkbox(options)
                return card:AddToggle({ Id = options.flag, Name = options.title, Callback = options.callback, Setting = true, Notification = true })
            end

            function module:create_slider(options)
                return card:AddSlider({
                    Id = options.flag,
                    Name = options.title,
                    Min = options.minimum_value,
                    Max = options.maximum_value,
                    Default = options.value,
                    Step = options.round_number and 1 or 0.1,
                    Callback = options.callback,
                })
            end

            function module:create_dropdown(options)
                if options.multi_dropdown then
                    warn("[Sora x Hikaru] UI v2: multi-select dropdowns are not available yet ('" .. tostring(options.title) .. "' skipped)")
                    return {}
                end
                return card:AddDropdown({ Id = options.flag, Name = options.title, Options = options.options, Callback = options.callback })
            end

            function module:create_button(options)
                return card:AddButton({ Name = options.title, Callback = options.callback })
            end

            function module:create_divider()
                return card:AddDivider()
            end

            function module:create_paragraph(options)
                return card:AddText({ Text = options.text or options.title })
            end

            function module:create_text(options)
                return card:AddText({ Text = options.text })
            end

            for _, name in ipairs({ "create_textbox", "create_colorpicker", "create_range_slider", "create_keybind", "create_code", "create_image", "create_feature", "create_section", "create_playerlist", "create_tooltip", "create_space" }) do
                module[name] = unsupported(name)
            end
            return module
        end

        return v1Tab
    end

    -- v1 builds everything first and then calls load()
    function window:load()
        return self
    end

    function window:UIVisiblity()
        self:Toggle()
    end
end

return Compat
