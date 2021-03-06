pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- main

names = {
	"us sales operations",
	"dwarf office",
	"micro managers"
}
printh("\n\n-------\n-".. names[flr(rnd(#names))+1] .. "-\n-------")

-- constants
-- foo

-- sounds

-- game state
workers = {} -- workers and stuff
furniture = {} -- desks etc
plants = {} -- plants
copiers = {} -- copiers
background = {} -- stuff to draw behind the workers
forground = {} -- stuff to draw in front of the workers
graph = {} -- graph for navigating around the play area
active_tasks = {} --
cursors = {}

function _init()
	graph = generate_graph()
	generate_workers()
	generate_furniture()
	generate_cursors()
	add(active_tasks, create_socialize_task(workers[1], workers[2]))
end

function generate_furniture()
	local worker_index = 1
	for t in all({17, 141}) do
		local o = workers[worker_index]
		local d = desk.create({
			tile = t,
			owner = o
		})
		o.desk = d
		worker_index += 1
	end
	for t in all({43, 100}) do
		create_plant(t)
	end
	for t in all({103}) do
		create_copier(t)
	end
end

function generate_workers()
	for i=1,2 do
		worker.create({ tile = random_spot() })
	end
	worker.create({ tile = 25 })
end

function generate_cursors()
	for i=1,2 do
		add(cursors, cursor.create(i))
	end
end

function _update()
	assign_tasks()

	for t in all(active_tasks) do
		t:update()
	end
	for w in all(workers) do
		w:update()
	end
	for c in all(cursors) do
		c:update()
	end

	update_uis()
end

function _draw()
	cls()
	mapdraw(0,0,0,0,16,16)
	-- draw_indicies()
	for b in all(background) do
		b:draw()
	end
	for w in all(workers) do
		w:draw()
	end
	for f in all(forground) do
		f:draw()
	end
	for c in all(cursors) do
		c:draw()
	end
	-- draw_path(workers[1].path)
	draw_ui()
end

-->8
-- 1 helper stuff

-- timer class
timer = {
	max = 0,
	current = 0,
	done = false
}
function timer.new(max)
	local t = setmetatable({}, { __index = timer })
	t.max = max or 0
	t.current = t.max
	return t
end

function timer:update()
	if self.current > 0 then
		self.current -= 1
	else
		self.done = true
	end
end

function timer:finish()
	self.current = 0
	self.done = true
end

function timer:reset()
	self.current = self.max
	self.done = false
end
-->8
-- helper stuff

-- timer class
timer = {
	max = 0,
	current = 0,
	done = false
}
function timer.new(max)
	local t = setmetatable({}, { __index = timer })
	t.max = max or 0
	t.current = t.max
	return t
end

function timer:update()
	if self.current > 0 then
		self.current -= 1
	else
		self.done = true
	end
end

function timer:finish()
	self.current = 0
	self.done = true
end

function timer:reset()
	self.current = self.max
	self.done = false
end

-- table helpers

function includes(tab, val)
	for v in all(tab) do
		if(v == val) return true
	end
	return false
end

-- retrieve random table entry
function sample(t)
	return t[flr(rnd(#t))+1]
end

-- sub list meeting criteria supplied in function
function select(t, f)
	local list = {}
	for v in all(t) do
		if f(v) then
			add(list, v)
		end
	end
	return list
end

-- insert into table and sort by priority
function insert(t, val, p)
	if #t >= 1 then
		add(t, {})
		for i=(#t),2,-1 do
			local next = t[i-1]
			if p < next[2] then
				t[i] = {val, p}
				return
			else
				t[i] = next
			end
		end
		t[1] = {val, p}
	else
		add(t, {val, p})
	end
end

-- pop the last element off a table
function popend(t)
	local top = t[#t]
	del(t,t[#t])
	return top
end

-- math

-- p1 and p2 are points
function manhattan_distance(p1, p2)
	return abs(p1.x - p2.x) + abs(p1.y - p2.y)
end

-- sprites
function zspr(n,w,h,dx,dy,dz,f)
	local sx = shl(band(n, 0x0f), 3)
	local sy = shr(band(n, 0xf0), 1)
	local sw = shl(w, 3)
	local sh = shl(h, 3)
	local dw = sw * dz
	local dh = sh * dz
	sspr(sx,sy,sw,sh, dx,dy,dw,dh,f)
end
-->8
-- map stuff

ui_offset = 3
min_tile = 0
max_tile = 16 * (16 - (ui_offset * 1))
min_x = 0
max_x = 15
min_y = ui_offset
max_y = 15
impassible = 0

function point(x, y)
	return {x=x, y=y}
end

-- t1 and t2 are tiles
function distance(t1, t2)
	return manhattan_distance(graph[t1].pos, graph[t2].pos)
end

function closest(source, list)
	local closest
	local closest_d = 999
	for x in all(list) do
		local d = distance(x.tile, source.tile)
		if closest_d == nil or closest_d > d then
			closest = x
			closest_d = d
		end
	end
	return closest
end

function get_flag(pos, flag)
	return fget(mget(pos.x, pos.y), flag)
end

-- create a cached graph of the map. each space on the map is indexed
function generate_graph()
	local graph = {}
	for i=min_tile,max_tile do
		local node = {}
		node.occupants = {}
		node.tile = i
		node.pos = tile_to_pos(i)
		node.passible = not get_flag(node.pos, impassible)
		node.neighbors = get_valid_neighbors(node)
		graph[i] = node
	end
	return graph
end

--[[
translate between map indexes and x,y coords
for instance:
	pos_to_tile(point(4, 0)) -- 4
	pos_to_tile(point(1, 4)) -- 65
	tile_to_pos(255) -- 15, 16
-- ]]
function tile_to_pos(tile)
	local y = flr(tile / 16) + ui_offset
	local x = tile % 16
	return point(x, y)
end

function pos_to_tile(pos)
	return ((pos.y - ui_offset) * 16) + pos.x
end

offsets = {{-1, 0}, {1,0}, {0,-1}, {0,1}}
function get_valid_neighbors(node)
	local neighbors = {}
	if not node.passible then
		return neighbors
	end
	local pos = node.pos
	for offset in all(offsets) do
		local neighbor_pos = point(pos.x+offset[1], pos.y+offset[2])
		-- not out of the play area, not the current point, and passible tile
		if neighbor_pos.x >= min_x and neighbor_pos.x <= max_x and
			 neighbor_pos.y >= min_y and neighbor_pos.y <= max_y and
			 not get_flag(neighbor_pos, impassible)
		then
			add(neighbors, pos_to_tile(neighbor_pos))
		end
	end
	return neighbors
end

function path(start, dest, prox)
	if not graph[dest] then
		printh('error node not found: ' .. dest)
	end
	local prox = prox or 1

	local frontier = {}
	local came_from = {}
	local cost_so_far = {}
	insert(frontier, start, 0)
	came_from[start] = nil
	cost_so_far[start] = 0
	local tries = 500

	while (#frontier > 0 and #frontier < 1000) do
		tries -= 1
		if tries == 0 then
			return {} -- give up
		end
		local current = popend(frontier)[1]

		if close_enough(current, dest, prox) then
			dest = current
			break
		end

		local neighbors = graph[current].neighbors
		local new_cost = cost_so_far[current] + 1
		for next in all(neighbors) do
			if (cost_so_far[next] == nil) or (new_cost < cost_so_far[next]) then
				cost_so_far[next] = new_cost
				if not graph[next] then
					printh('error node not found: ' .. next)
				end
				local priority = new_cost + distance(dest, next)
				insert(frontier, next, priority)

				came_from[next] = current
			end
		end
	end

	local current = came_from[dest]
	local path = {dest}
	while current != start do
		add(path, current)
		current = came_from[current]
	end
	return path
end

-- a and b are expected to be tiles
function close_enough(a, b, prox)
	if prox > 1 then
		return distance(a, b) < prox
	else
		return a == b
	end
end

-- helper functions
function random_spot()
	while true do
		local node = sample(graph)
		if node and node.passible then
			return node.tile
		end
	end
end

local speed = 2
-- fancy smooth sprite movement
function update_sprite_pos(sprite_pos, target_tile)
	local target_pos = tile_to_pos(target_tile)

	for n in all({'x', 'y'}) do
		if sprite_pos[n] < target_pos[n] * 8 then
			sprite_pos[n] += speed
		elseif sprite_pos[n] > target_pos[n] * 8 then
			sprite_pos[n] -= speed
		end
	end
end

-- debug stuff. delete for tokens
function draw_indicies()
	for node in all(graph) do
		if node.passible then
			print(node.tile, node.pos.x * 8, node.pos.y * 8, 1)
		end
	end
end

function draw_path(p)
	for i in all(p) do
		spr(
			15,
			graph[i].pos.x * 8,
			graph[i].pos.y * 8
		)
	end
end

function print_path(p)
	local str = ''
	for i in all(p) do
		str = (str .. ', ' .. i)
	end
	printh(str)
end

function print_tile(t)
	local pos = graph(t).pos
	printh('tile: ' .. t .. ' x,y: ' .. pos.x .. ',' .. pos.y)
end

-->8
-- worker 'class'

default_step_time = 5
default_idle_time = 2 * 30 -- 2 seconds

nobody_sprite = 14

heads = { 0,1,2,3,4 }

bodies = { 16, 17 }

skins = { 4, 4, 9, 15, 15 }

hairs = { 5, 5, 5, 4, 7, 7, 9, 10, }

shirts = { 2, 3, 7, 7, 5 }

ties = { 2, 8, 12, 14 }

name_parts = {
	'jor', 'eth', 'ken', 'di', 'car', 'yuk', 'ist', 'ur',
	'jon', 'bil', 'liv', 'iv', 'ma', 'at', 'cor', 'hek', 'zoe'
}

worker = {
	type = 'worker',
	player = 0,
	tile = 0,
	sprite_pos = nil,
	name = 'foo',
	body = bodies[1],
	head = heads[1],
	skin = skins[1],
	hair = hairs[1],
	shirt = shirts[1],
	tie = ties[1],
	task = 'idle',
	action = 'idle',
	path = {},
	todo = {},
	desk = nil,
	path_index = 0,
	flip_facing = false,
	step_timer = nil,
}

function worker.create(settings)
	settings = settings or {}
	settings.body = settings.body or sample(bodies)
	settings.head = settings.head or sample(heads)
	settings.skin = settings.skin or sample(skins)
	settings.hair = settings.hair or sample(hairs)
	settings.shirt = settings.shirt or sample(shirts)
	settings.tie = settings.ties or sample(ties)
	settings.name = settings.names or ''
	local pos = tile_to_pos(settings.tile)
	settings.sprite_pos = point(pos.x * 8, pos.y * 8)

	-- one or two name_parts smooshed together
	local num_parts = flr(rnd(3))
	for i=0,num_parts do
		settings.name = settings.name .. sample(name_parts)
	end

	local w = worker.new(settings)
	add(graph[settings.tile].occupants, w)
	add(workers, w)
end

function worker.new(settings)
	local w = setmetatable((settings or {}), { __index = worker })
	w.step_timer = timer.new(default_step_time)
	w.idle_timer = timer.new(default_idle_time)
	return w
end

function worker:update()
	self:update_timers()
	self:update_task()
	self:move()
	update_sprite_pos(self.sprite_pos, self.tile)
end

function worker:update_timers()
	self.step_timer:update()
	self.idle_timer:update()
end

function worker:update_task()
	if self.task == 'idle' or self.task == 'slack off' then
		self:update_idle()
	end
end

function worker:idle()
	self.task = 'idle'
	self.action = 'idle'
	self.idle_timer:reset()
end

function worker:update_idle()
	if (not self.idle_timer.done) return
	local tile = sample(graph[self.tile].neighbors)
	local n = rnd(3)
	if n > 1 and #graph[tile].occupants < 1 then
		self:move_to(tile, 1)
	end
	self.idle_timer:reset()
end

function worker:draw(x, y, scale, no_flip)
	local pos = self.sprite_pos
	local x = x or pos.x
	local y = y or pos.y
	local scale = scale or 1
	local flip = self.flip_facing
	if no_flip then
		flip = false
	end
	pal(11, self.skin)
	pal(10, self.hair)
	pal(14, self.shirt)
	pal(12, self.tie)

	for sp in all({self.head, self.body}) do
		zspr(sp, 1, 1, x, y, scale, flip)
	end
	pal()
end

function worker:chat()
	self.action = 'chatting'
end

function worker:wait()
	self.action = 'waiting'
end

function worker:move_to(tile, prox)
	prox = prox or 2
	self.action = 'walking'
	if (distance(self.tile, tile) < prox) return
	self.path = path(self.tile, tile, prox)
	self.path_index = #self.path
end

function worker:move()
	if (not self.step_timer.done) or self.action != 'walking' or #self.path < 1 then
		return
	end
	self.step_timer:reset()
	local current_node = graph[self.tile]
	self.tile = popend(self.path)
	local new_node = graph[self.tile]

	del(current_node.occupants, self)
	add(new_node.occupants, self)

	local current_x = current_node.pos.x
	local new_x = new_node.pos.x
	if (new_x == current_x) return
	if new_x < current_x then
		self.flip_facing = true
	else
		self.flip_facing = false
	end
end

-- TODO: do we need this?
function worker:uncrowd()
	local current_node = graph[self.tile]
	if #current_node.occupants < 1 then
		return
	end
	for n in all(current_node.neighbors) do
		if #graph[n].occupants < 1 then
			self:move_to(n, 1)
			return
		end
	end
end

-->8
-- furniture
desk_sprite = 128
chair_sprite = 160
tray_sprite = 129
copier_sprite = 130
plant_sprites = {144, 145, 146}

desk = {
	type = 'desk',
	owner = nil,
	chair = nil,
	tile = 0
}

function desk.create(settings)
	settings = settings or {}
	local d = desk.new(settings)
	local c = create_chair(d.tile)
	d.chair = c
	add(graph[d.tile].occupants, d)
	add(background, c)
	add(furniture, d)
	add(forground, d)
	return d
end

function desk.new(settings)
	return setmetatable((settings or {}), { __index = desk })
end

function desk:draw()
	local x = graph[self.tile].pos.x * 8
	local y = graph[self.tile].pos.y * 8
	spr(desk_sprite, x, y)
	-- desks have 2 parts
	spr(tray_sprite, x + 8, y)
end

function desk:valid_workers()
	-- TODO: cache this
	return select(workers, function(w)
		return w.desk == nil or w.desk == self
	end)
end

function create_chair(tile)
	return {
		tile = tile,
		draw = draw_chair
	}
end

function draw_chair(self)
	local pos = graph[self.tile].pos
	spr(
		chair_sprite,
		pos.x * 8,
		pos.y * 8
	)
end

function create_plant(tile)
	local p = {
		type = 'plant',
		tile = tile,
		draw = draw_thing,
		sprite = sample(plant_sprites)
	}
	add(graph[tile].occupants, p)
	add(plants, p)
	add(forground, p)
end

function create_copier(tile)
	local p = {
		type = 'copier',
		tile = tile,
		draw = draw_thing,
		sprite = copier_sprite
	}
	add(copiers, p)
	add(forground, p)
end

function draw_thing(self)
	local pos = graph[self.tile].pos
	spr(
		self.sprite,
		pos.x * 8,
		pos.y * 8
	)
end
-->8
-- tasks

unassigned_tasks = {}

function assign_tasks()
	for w in all(workers) do
		if w.task == 'idle' then
			local viable_tasks = {
				create_admire_plant_task,
				create_slack_task
			}
			if w.desk != nil then
				add(viable_tasks, create_paperwork_task)
			end
			local f = sample(viable_tasks)
			add(active_tasks, f(w))
		end
	end
end

-- default_task_time = 15 * 30 -- 15 seconds
default_task_time = 5 * 30 -- 15 seconds

task = {
	name = 'working',
	timer = nil,
	state = 1,
	states = {
		'unclaimed',
		'init',
		'traveling',
		'running',
		'complete',
		'abort'
	}
}
function task.new(settings)
	local t = setmetatable((settings or {}), { __index = task })
	t.timer = timer.new(default_task_time)
	return t
end

function task:traveling()
end

function task:running()
	if self.timer.done then
		self:advance()
	end
end

function task:update()
	local state = self.states[self.state]
	if state == 'unclaimed' then return end
	self.timer:update()
	-- call the function on this task relevant to the current state
	state = self.states[self.state]
	if not self[state] then
		printh(state .. ' state not found')
	end
	self[state](self)

	if self.timer.done then
		self.state = #self.states -- out of time. abort
	end
end

function task:advance()
	self.state += 1
	self.timer:reset()
end

function task:complete()
	printh('task complete! ' .. self.name)
	if self.worker then
		self.worker:idle()
	end
	del(active_tasks, self)
end

function task:abort()
	del(active_tasks, self)
end

-- paper work task

default_print_time = 5 * 30 -- 5 seconds
default_desk_time = 5 * 30 -- 5 seconds

function create_paperwork_task(worker)
	local t = task.new({
		name = 'paperwork',
		worker = worker,
		init = paperwork_init,
		travel_to_copier = travel_to_copier,
		printing = printing,
		print_timer = timer.new(default_print_time),
		desk_timer = timer.new(default_desk_time),
		travel_to_desk = travel_to_desk,
		desking = desking,
		complete = paperwork_complete,
		abort = paperwork_abort,
		states = {
			'init',
			'travel_to_copier',
			'printing',
			'travel_to_desk',
			'desking',
			-- 'travel_to_outbox',
			'complete',
			'abort'
		}
	})
	t:init()
	return t
end

function paperwork_init(self)
	self.worker.task = 'paperwork'
	self.worker:move_to(copiers[1].tile)
	self:advance()
end

function travel_to_copier(self)
	if distance(self.worker.tile, copiers[1].tile) < 2 then
		self:advance()
	end
end

function printing(self)
	local t = self.print_timer
	t:update()
	if t.done then
		 if not self.worker.desk then
			return self:abort()
		 end
		self.worker:move_to(self.worker.desk.tile, 1)
		self:advance()
	end
end

function travel_to_desk(self)
	if distance(self.worker.tile, self.worker.desk.tile) < 1 then
		self:advance()
	end
end

function desking(self)
	local t = self.desk_timer
	t:update()
	if t.done then
		self:advance()
	end
end

function paperwork_complete(self)
	task.complete(self)
end

function paperwork_abort(self)
	printh(self.name .. 'task aborted aborted by' .. self.worker.name .. '!')
	self.worker.task = 'idle'
	del(active_tasks, self)
end

-- admire plant task

function create_admire_plant_task(worker)
	local t = task.new({
		name = 'admire_plant',
		worker = worker,
		plant = closest(worker, plants),
		init = admire_plant_init,
		traveling = travel_to_plant,
		complete = admire_plant_complete,
	})
	t:init()
	return t
end

function admire_plant_init(self)
	self.worker.task = 'admire plant'
	self.worker:move_to(self.plant.tile)
	self:advance()
end

function travel_to_plant(self)
	if distance(self.worker.tile, self.plant.tile) < 2 then
		self:advance()
	end
end

function admire_plant_complete(self)
	task.complete(self)
end

-- socialize task

-- TODO: make this a propper class
function create_socialize_task(a1, a2)
	local t = task.new({
		name = 'socializing',
		workers = {a1, a2},
		init = socialize_init,
		traveling = socialize_traveling,
		arriving = socialize_arriving,
		complete = socialize_complete,
		states = {
			'init',
			'traveling',
			'arriving',
			'running',
			'complete',
			'abort'
		}
	})
	t:init()
	return t
end

function socialize_init(self)
	local w1 = self.workers[1]
	local w2 = self.workers[2]
	w1.task = 'socializing'
	w2.task = 'socializing'
	w1:move_to(w2.tile)
	w2:move_to(w1.tile)
	self:advance()
end

function socialize_traveling(self)
	local w1 = self.workers[1]
	local w2 = self.workers[2]
	if distance(w1.tile, w2.tile) < 3 then
		w1:move_to(w2.tile, 1)
		w2:wait()
		self:advance()
		return
	end

	-- we might be oscillating. hang on a sec
	if self.timer.current < default_task_time - 30 * 2 then
		w2:wait()
	elseif self.timer.current % 15 == 0 then
	-- correct path every half second
		w1:move_to(w2.tile)
		w2:move_to(w1.tile)
	end
end

function socialize_arriving(self)
	local w1 = self.workers[1]
	local w2 = self.workers[2]
	if distance(w1.tile, w2.tile) < 2 then
		w1:chat()
		w2:chat()
		self:advance()
	end
end

function socialize_complete(self)
	for w in all(self.workers) do
		w:idle()
	end
	task.complete(self)
end

-- slack task

function create_slack_task(worker)
	local t = task.new({
		name = 'slack',
		worker = worker,
		init = slack_init,
		states = {
			'init',
			'running',
			'complete'
		}
	})
	t.timer = timer.new((rnd(default_task_time) + 30))
	t:init()
	return t
end

function slack_init(self)
	self.worker:idle()
	self.worker.task = 'slack off'
	self:advance()
end
-->8
-- ui

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

scroll_throttle_time = 2

cursor = {
	player = 1,
	tile = player == 1 and min_tile or max_tile,
	selection = nil,
	selection_index = 0,
	scroll_timer = nil,
	sprite_pos = nil,
}
function cursor.new(settings)
	local c = setmetatable((settings or {}), { __index = cursor })
	c.scroll_timer = timer.new(scroll_throttle_time)
	return c
end

function cursor.create(player)
	local tile = player == 1 and min_tile or max_tile
	local pos = tile_to_pos(tile)
	return cursor.new({
		player = player,
		clr = cursor_colors[player],
		tile = tile,
		sprite_pos = point(pos.x * 8, pos.y * 8)
	})
end

function cursor:update()
	self:check_select()
	self:check_move()
	update_sprite_pos(self.sprite_pos, self.tile)
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
	local x = self.sprite_pos.x
	local y = self.sprite_pos.y
	pal(11, self.clr)
	spr(cursor_sprite, x, y)
	if self.selection then
		spr(selected_sprite, x, y)
	end
	pal()
end
-->8
-- 7 tests
-- translation tests
--[[
printh(pos_to_tile(point(4, 0))) -- should be 4
printh(pos_to_tile(point(1, 4))) -- should be 65
local pos = tile_to_pos(5)
printh(pos.x .. ' ' .. pos.y) -- should be 5, 0
local pos2 = tile_to_pos(254)
printh(pos2.x .. ' ' .. pos2.y) -- should be 14, 15
--]]


-- get_valid_neighbors_tests
--[[
printh('--0,0--')
-- expected: 1, 16, 17
local n1 = get_valid_neighbors({pos = point(0,0)})
for n in all(n1) do
	local posn = tile_to_pos(n)
	printh('i:' .. n .. ' x,y: '.. posn.x .. ',' ..posn.y)
end
printh('--4,2--')
local n2 = get_valid_neighbors({pos = point(4,2)})
for n in all(n2) do
	local posn = tile_to_pos(n)
	printh('i:' .. n .. ' x,y: '.. posn.x .. ',' ..posn.y)
end
--]]

-- map_graph_tests
--[[
graph = generate_graph()

printh('--4,2--')
node = graph[36]
printh('passible: ' .. node.passible)

printh('--3,2--')
node = graph[35]
printh('passible: ' .. node.passible)
for n in all(node.neighbors) do
	local posn = tile_to_pos(n)
	printh('i:' .. n .. ' x,y: '.. posn.x .. ',' ..posn.y)
end
--]]
__gfx__
00aaaa0000aaaa0000aaaa00000bb00000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000dddd0000000000
00abaa000aabaa0000abbb0000bbbb00aabbbb0000000000000000000000000000000000000000000000000000000000000000000000000000dddd0000000000
0b5bb5000b5bb5000b5bb5000b5bb500ab5bb5000000000000000000000000000000000000000000000000000000000000000000000000000ddddd0000000000
00aaaa00aabbbb0000bbbb0000bbbb0000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000d7d70000028000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd7d000008e000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd7d70000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddd0000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00d0000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777700bb0000bb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000b
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000700000000
0eeebe000eeece000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000700000000
0beeee000beece000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000700000000
005555000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000b
005005000050050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777700bb0000bb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7d6666666666666d7d66666d7d66666d7d66666d7d6660000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7d6666666666666d7d66666d7d66666d7d66666d7d6660000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7d66666ddddddddd7d666ddd7d666ddd7ddddddd7dddd0000000000000000000000000000000000000000000000000000000000000000
6666d6666666666666d7d66666d677777776d6667776d66677767777777677770000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7d66666d7ddddddddd666ddd7d666ddddddddddd7dddd0000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7d66666d7d5ddddddd666ddd7d666ddddddddddd7d5dd0000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7d66666d7d555ddddd666ddd7d666ddddddddddd7d55d0000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7d66666d7d5555555566655d7d6665555555555d7d5550000000000000000000000000000000000000000000000000000000000000000
6666666666666666666666666666666666d7d6666666666666d7d666000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666666666666666666666d7d6666666666666d7d666000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666ddddddddddddd66666d7dddddddddddd66d7dddd000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666777777777776d66666d677777776777766d67777000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666d66ddddddddddd7d66666ddddddddd7dddd66d7dddd000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666ddddddddddd7d66666ddddddddd7d5dd66d7d5dd000000000000000000000000000000000000000000000000000000000000000000000000
6e66666666666666ddddddddddd7d66666ddddddddd7d55566d7d555000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666665555555555d7d6666655555555d7d555e6d7d555000000000000000000000000000000000000000000000000000000000000000000000000
01111000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110000222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11100001222000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000011220000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000111200002220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011110000222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000777000057775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000030000000000000777055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000777200000000007777770ffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffffffffffff000755557000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050005000000777777000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000555055500000550055005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003330000000b3000003b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b33300000b3b30003b370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b335b0000334353003b330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003b330000044400007b330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003300000045000003b330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd0000dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd0000dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d5000000d5000000d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd00003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d07702000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd0055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55500555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6060606060606060616161616161616100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6060606060606060616161616161616100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6060606060606060616161616161616100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4352525552525341505151414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4240514241414251414141414241415100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4250414240414241414151414241414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5441524652414451414141524752404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414140414141414141414241414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4151414241515040414141414041404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041414240414141414340525552405300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5041524752514141414250514241414200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414241415141514241414241514200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140414140504150415452524652524400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041404041435341404140414041414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041414141544441404141414141404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051514151505141505141515051415160600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
