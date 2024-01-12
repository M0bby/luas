

local notifications = {}
	local draw_gamesense_ui = {}
	draw_gamesense_ui.alpha = function(color, alpha)
		color[4] = alpha
		return color
	end
	draw_gamesense_ui.colors = {
		main = {12, 12, 12},
		border_edge = {60, 60, 60},
		border_inner = {40, 40, 40},
		gradient = {
			top = {
				left = {55, 177, 218},
				middle = {204, 70, 205},
				right = {204, 227, 53}
			},
			bottom = {
				left = {29, 94, 116},
				middle = {109, 37, 109},
				right = {109, 121, 28}
			},
			pixel_three = {6, 6, 6}
		},
		combine = function(color1, color2, ...)
			local t = {unpack(color1)}
			for i = 1, #color2 do
				table.insert(t, color2[i])
			end
			local args = {...}
			for i = 1, #args do
				table.insert(t, args[i])
			end
			return t
		end
	}
	draw_gamesense_ui.border = function(x, y, width, height, alpha)
		local x = x - 7 - 1
		local y = y - 7 - 5
		local w = width + 14 + 2
		local h = height + 14 + 10
		renderer.rectangle(x, y, w, h, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.main, alpha)))
		renderer.rectangle(x + 1, y + 1, w - 2, h - 2, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_edge, alpha)))
		renderer.rectangle(x + 2, y + 2, w - 4, h - 4, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_inner, alpha)))
		renderer.rectangle(x + 6, y + 6, w - 12, h - 12, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_edge, alpha)))
	end
	draw_gamesense_ui.gradient = function(x, y, width, alpha)
		local full_width = width
		local width = math.floor(width / 2)
		local top_left = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.left, alpha)
		local top_middle = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.middle, alpha)
		local top_right = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.right, alpha)
		local bottom_left = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.left, alpha)
		local bottom_middle = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.middle, alpha)
		local bottom_right = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.right, alpha)
		top_left = draw_gamesense_ui.colors.combine(top_left, top_middle, true)
		top_right = draw_gamesense_ui.colors.combine(top_middle, top_right, true)
		bottom_left = draw_gamesense_ui.colors.combine(bottom_left, bottom_middle, true)
		bottom_right = draw_gamesense_ui.colors.combine(bottom_middle, bottom_right, true)
		local oddfix = math.ceil(full_width / 2)
		renderer.gradient(x, y - 4, width, 1, unpack(top_left))
		renderer.gradient(x + width, y - 4, oddfix, 1, unpack(top_right))
		renderer.gradient(x, y - 3, width, 1, unpack(bottom_left))
		renderer.gradient(x + width, y - 3, oddfix, 1, unpack(bottom_right))
		renderer.rectangle(x, y - 2, full_width, 1, unpack(draw_gamesense_ui.colors.gradient.pixel_three))
	end
	draw_gamesense_ui.draw = function(x, y, width, height, alpha)
		y = y - 7
		draw_gamesense_ui.border(x, y, width, height, alpha)
		renderer.rectangle(x - 1, y - 5, width + 2, height + 10, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.main, alpha)))
		draw_gamesense_ui.gradient(x, y, width, alpha)
	end
	local function push_notify(text)
        if tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "old") then
            notify.new_bottom(179, 255, 18, { { text } }) 
        else
            table.insert(notifications, 1, {
                text = text,
                alpha = 255,
                spacer = 0,
                lifetime = client.timestamp() + (10.0 * 100),
            })
        end
    end
	local lerp = function(current, to_reach, t) return current + (to_reach - current) * t end
	client.set_event_callback("paint_ui", function()
		local width, height = client.screen_size()
		local frametime = globals.frametime()
		local timestamp = client.timestamp()
		for idx, notification in next, notifications do
			if timestamp > notification.lifetime then
				notification.alpha = lerp(255, 0, 1 - (notification.alpha / 255) + frametime * (1 / 7.5 * 10))
			end
			if notification.alpha <= 0 then
				notifications[idx] = nil
			else
				notification.spacer = lerp(notification.spacer, idx * 40, frametime)
				local text_width = renderer.measure_text("c", notification.text) + 10
				draw_gamesense_ui.draw(width/2 - text_width / 2, height/2 + 300 + notification.spacer, text_width, 12, notification.alpha)
				renderer.text(width/2, height/2 + 300 + notification.spacer, 255, 255, 255, notification.alpha, "c", 0, notification.text:gsub("\a%x%x%x%x%x%x%x%x", function(color)
					return color:sub(1, #color - 2)..string.format("%02x", notification.alpha)
				end):sub(1, -1))
			end
		end
	end)
