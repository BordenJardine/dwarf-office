-- 6 ui

function update_uis()
	for c in all(cursors) do
		update_ui(c)
	end
end

function update_ui(cursor)
	local selection = cursor.selection
	if selection and selection.type == 'desk' then
		update_desk_ui(selection, cursor)
	end
end

function update_desk_ui(desk, cursor)
	-- scroll throttling
	if (not cursor:check_scroll_timer()) return
	local bl=btn(0, cursor.player)
	local br=btn(1, cursor.player)
	local valid_workers = desk:valid_workers()
	local current_worker_index = 0
	for i=1,#valid_workers do
		if desk.owner == valid_workers[i] then
			current_worker_index = i
			break
		end
	end
	local current_worker = valid_workers[current_worker_index]
	if bl and current_worker_index <= 1 then
		if (current_worker) current_worker.desk = nil
		desk.owner = nil
		return
	end
	if br and current_worker_index >= #valid_workers then
		return
	end
	local offset = bl and -1 or 1
	if (current_worker) current_worker.desk = nil
	local new_owner = valid_workers[current_worker_index + offset]
	new_owner.desk = desk
	desk.owner = new_owner
end

function draw_ui()
	for c in all(cursors) do
		draw_selection(c)
	end
end

function draw_selection(cursor)
	local selection = cursor.selection
	if not selection then
		return
	end

	ui_drawers[selection.type](selection)
end

function draw_worker_ui(worker, offset)
	offset = offset or 0
	local margin = 1
	print(worker.name, (2 + offset) * 8, margin, 7)
	worker:draw((6 + offset) * 8 - margin, margin, 2, true)
	print(worker.task, (2 + offset) * 8, 2 * 8, 7)
end

function draw_desk_ui(desk, offset)
	offset = offset or 0
	local margin = 1
	local owner = desk.owner
	local label = 'unowned'
	if owner and owner.name then
		label = owner.name .. "'s"
	end
	print(label ..' desk', (offset * 8) + margin, margin, 7)
	zspr(desk_sprite, 1, 1, (4 + offset) * 8, margin, 2)
	zspr(desk_sprite + 1, 1, 1, (6 + offset) * 8, margin, 2)
	local w_x = (offset * 8) + 8
	local w_y = 2 * 8
	-- empty sprite
	spr(nobody_sprite, w_x, w_y)
	if owner == nil then
		spr(cursor_sprite, w_x, w_y)
	end
	w_x += 8
	for w in all(desk:valid_workers()) do
		w:draw(w_x, w_y, 1, true)
		if owner == w then
			spr(cursor_sprite, w_x, w_y)
		end
		w_x += 8
	end
end

function draw_plant_ui(plant, offset)
	offset = offset or 0
	local margin = 1
	print('a plant', (offset * 8) + margin, margin, 7)
	zspr(plant.sprite, 1, 1, (6 + offset) * 8 - margin, margin, 2)
	print('how nice', (offset * 8) + margin, 2 * 8, 7)
end

ui_drawers = {
	worker = draw_worker_ui,
	plant = draw_plant_ui,
	desk = draw_desk_ui,
}

-- cursor
cursor_sprite = 31
selected_sprite = 30
cursor_colors = {
	5,
	15
}

scroll_throttle_time = 3
cursor = {
	player = 1,
	tile = player == 1 and min_tile or max_tile,
	selection = nil,
	selection_index = 0,
	scroll_timer = nil
}
function cursor.new(settings)
	local c = setmetatable((settings or {}), { __index = cursor })
	c.scroll_timer = timer.new(scroll_throttle_time)
	return c
end

function cursor.create(player)
	return cursor.new({
		player = player,
		clr = cursor_colors[player],
		tile = player == 1 and min_tile or max_tile,
	})
end

function cursor:update()
	self:check_select()
	self:check_move()
end

local selectable = {'worker', 'plant', 'desk'}
function cursor:check_select()
	local bo=btn(4, self.player) -- select
	local bx=btn(5, self.player) -- unselect

	if bx then -- unselect button
		self.selection = nil
		self.selection_index = 0
		return
	end
	
	if self.selection or not bo then -- already something selected
		return
	end

	for o in all(graph[self.tile].occupants) do
		if includes(selectable, o.type) then
			self.selection = o
			return
		end
	end
end

function cursor:check_scroll_timer()
	local bl=btn(0, self.player)
	local br=btn(1, self.player)
	local bu=btn(2, self.player)
	local bd=btn(3, self.player)
	if not (bl or br or bu or bd) then
		self.scroll_timer:finish()
		return false
	end
	if self.scroll_timer.done then
		self.scroll_timer:reset()
		return true
	end
	self.scroll_timer:update()
	return false
end

function cursor:check_move()
	-- the selected object(worker) might have moved
	if self.selection then
		self.tile = self.selection.tile
		return
	end

	-- scroll throttling
	if (not self:check_scroll_timer()) return

	local pos = tile_to_pos(self.tile)
	local bl=btn(0, self.player)
	local br=btn(1, self.player)
	local bu=btn(2, self.player)
	local bd=btn(3, self.player)

	if bl and pos.x > min_x then
		pos.x -= 1
	elseif br and pos.x < max_x then
		pos.x += 1
	end
	if bu and pos.y > min_y then
		pos.y -= 1
	elseif bd and pos.y < max_y then
		pos.y += 1
	end
	self.tile = pos_to_tile(pos)
end

function cursor:draw()
	local pos = graph[self.tile].pos
	local x = x or (pos.x * 8)
	local y = y or (pos.y * 8)
	pal(11, self.clr)
	spr(cursor_sprite, x, y)
	if self.selection then
		spr(selected_sprite, x, y)
	end
	pal()
end
