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

-- sounds

-- game state
actors = {} -- workers and stuff
furniture = {} -- desks etc
plants = {} -- plants
background = {} -- stuff to draw behind the actors
forground = {} -- stuff to draw in front of the actors
graph = {} -- graph for navigating around the play area
active_tasks = {} --

function _init()
	graph = generate_graph()
	generate_furniture()
	generate_workers()
	add(active_tasks, create_socialize_task(actors[1], actors[2]))
end

function generate_furniture()
	for t in all({17, 141}) do
		desk.create({
			tile = t
		})
	end
	for t in all({43, 100}) do
		create_plant(t)
	end
end

function generate_workers()
	for i=1,2 do
		worker.create({
			tile = random_spot()
		})
	end
	worker.create({
		tile = 17
	})
end

function _update()
	for a in all(actors) do
	  a:update()
	end
	for t in all(active_tasks) do
	  t:update()
	end
end

function _draw()
	cls()
	mapdraw(0,0,0,0,16,16)
	-- draw_indicies()
	for b in all (background) do
		b:draw()
	end
	for a in all(actors) do
		a:draw()
	end
	for f in all (forground) do
		f:draw()
	end
	-- draw_path(actors[1].path)
end

-->8
-- helper stuff

-- tables
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

-- priority queue!

-->8
-- map stuff

ui_offset = 3
min_graph_index = 0
max_graph_index = 16 * (16 - (ui_offset * 1))
min_x = 0
max_x = 15
min_y = ui_offset
max_y = 15 -- - ui_offset
impassible = 0

function point(x, y)
	return {x=x, y=y}
end

-- t1 and t2 are tiles
function distance(t1, t2)
	return manhattan_distance(graph[t1].pos, graph[t2].pos)
end

function get_flag(pos, flag)
	return fget(mget(pos.x, pos.y), flag)
end

-- create a cached graph of the map. each space on the map is indexed
function generate_graph()
	local graph = {}
	for i=min_graph_index,max_graph_index do
		local node = {}
		node.occupants = {}
		node.index = i
		node.pos = index_to_pos(i)
		node.passible = not get_flag(node.pos, impassible)
		node.neighbors = get_valid_neighbors(node)
		graph[i] = node
	end
	return graph
end

--[[
translate between map indexes and x,y coords
for instance:
	pos_to_index(point(4, 0)) -- 4
	pos_to_index(point(1, 4)) -- 65
	index_to_pos(255) -- 15, 16
-- ]]
function index_to_pos(index)
	local y = flr(index / 16) + ui_offset
	local x = index % 16
	return point(x, y)
end

function pos_to_index(pos)
	return ((pos.y - ui_offset) * 16) + pos.x
end

--[[
-- diagonals
function get_valid_neighbors(node)
	local neighbors = {}
	if not node.passible then
		return neighbors
	end
	local pos = node.pos
	for yi=-1,1 do
		for xi=-1,1 do
			local neighbor_pos = point(pos.x + xi,pos.y+yi)
			-- not out of the play area, not the current point, and passible tile
			if neighbor_pos.x >= min_x and neighbor_pos.x <= max_x and
				 neighbor_pos.y >= min_y and neighbor_pos.y <= max_y and
				 not (neighbor_pos.x == pos.x and neighbor_pos.y == pos.y) and
				 not get_flag(neighbor_pos, impassible)
			then
				add(neighbors, pos_to_index(neighbor_pos))
			end
		end
	end
	return neighbors
end
--]]
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
			add(neighbors, pos_to_index(neighbor_pos))
		end
	end
	return neighbors
end

function path(start, dest, prox)
	if not graph[dest] then
		printh('error node not found: ' .. dest)
	end
	local prox = prox or false

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
	local path = {}
	while current != start do
		add(path, current)
		current = came_from[current]
	end
	return path
end

-- a and b are expected to be tiles
function close_enough(a, b, prox)
	if prox then
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
			return node.index
		end
	end
end

-- debug stuff. delete for tokens
function draw_indicies()
	for node in all(graph) do
		if node.passible then
			print(node.index, node.pos.x * 8, node.pos.y * 8, 1)
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

default_step_time = 4

heads = { 0,1,2,3,4 }

bodies = { 16, 17 }

skins = {
	4, 4,
	9,
	-- 12,
	-- 14,
	15, 15
}

hairs = {
	5, 5, 5,
	4,
	7, 7,
	9,
	10,
	--14,
}

shirts = {
	2,
	3,
	7,
	7,
	5
}

ties = {
	2,
	8,
	12,
	14
}

worker = {
	player = 0,
	tile = 0,
	body = bodies[1],
	head = heads[1],
	skin = skins[1],
	hair = hairs[1],
	shirt = shirts[1],
	tie = ties[1],
	task = 'idle',
	path = {},
	todo = {},
	desk = nil,
	path_index = 0,
	flip_facing = false,
	step_timer = default_step_time,
	max_step_time = default_step_time
}

function worker.new(settings)
	return setmetatable((settings or {}), { __index = worker })
end

function worker.create(settings)
	settings = settings or {}
	settings.body = settings.body or sample(bodies)
	settings.head = settings.head or sample(heads)
	settings.skin = settings.skin or sample(skins)
	settings.hair = settings.hair or sample(hairs)
	settings.shirt = settings.shirt or sample(shirts)
	settings.tie = settings.ties or sample(ties)
	settings.index = #actors+1

	add(graph[settings.tile].occupants, settings.index)
	add(actors, worker.new(settings))
end

function worker:draw()
	local x = graph[self.tile].pos.x * 8
	local y = graph[self.tile].pos.y * 8
	pal(11, self.skin)
	pal(10, self.hair)
	pal(14, self.shirt)
	pal(12, self.tie)
	spr(self.body, x, y, 1, 1, self.flip_facing)
	spr(self.head, x, y, 1, 1, self.flip_facing)
	pal()
end

function worker:update_timer()
	self.step_timer -= 1
	if self.step_timer < 0 then
		self.step_timer = self.max_step_time
	end
end

function worker.new(settings)
	local w = setmetatable((settings or {}), { __index = worker })
	return w
end

function worker:update()
	self:update_timer()
	self:update_task()
	self:move()
end

function worker:update_timer()
	self.step_timer -= 1
	if self.step_timer < 0 then
		self.step_timer = self.max_step_time
	end
end

function worker:update_task()
end

function worker:socialize()
	self.task = 'socializing'
end

function worker:wait()
	self.task = 'waiting'
end

function worker:move_to(tile, prox)
	prox = prox or 2
	self.task = 'walking'
	self.path = path(self.tile, tile, prox)
	self.path_index = #self.path
end

function worker:move()
	if (self.step_timer != 0 or self.task != 'walking' or #self.path < 1) return
	local current_node = graph[self.tile]
	self.tile = popend(self.path)
	local new_node = graph[self.tile]

	del(current_node.occupants, self.index)
	add(new_node.occupants, self.index)

	local current_x = current_node.pos.x
	local new_x = new_node.pos.x
	if (new_x == current_x) return
	if new_x < current_x then
		self.flip_facing = true
	else
		self.flip_facing = false
	end
end

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
plant_sprites = {144, 145}

desk = {
	owner = nil,
	chair = nil,
	tile = 0
}

function desk.create(settings)
	settings = settings or {}
	local d = desk.new(settings)
	local c = create_chair(d.tile)
	d.chair = c
	add(background, c)
	add(furniture, d)
	add(forground, d)
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
		tile = tile,
		draw = draw_plant,
		sprite = sample(plant_sprites)
	}
	add(plants, p)
	add(forground, p)
end

function draw_plant(self)
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
active_tasks = {}

default_ticks = 30 * 60 -- 30 seconds

-- socialize

function create_socialize_task(a1, a2)
	return task.new({
		name = 'socializing',
		workers = {a1, a2},
		init = socialize_init,
		traveling = socialize_traveling,
		arriving = socialize_arriving,
		states = {
			'init',
			'traveling',
			'arriving',
			'running',
			'complete',
			'aborted'
		}
	})
end

function socialize_init(self)
	local w1 = self.workers[1]
	local w2 = self.workers[2]
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
	if self.ticks < default_ticks - 60 * 1 then
		w2:wait()
	elseif self.ticks % 15 == 0 then
	-- correct path every half second
		w1:move_to(w2.tile)
		w2:move_to(w1.tile)
	end
end

function socialize_arriving(self)
	local w1 = self.workers[1]
	local w2 = self.workers[2]
	if distance(w1.tile, w2.tile) < 2 then
		w1:socialize()
		w2:socialize()
		self:advance()
	end
end

-- work

function create_work_task()
	t = task.new({
		target = nil
	})
	return t
end

task = {
	name = 'working',
	ticks = default_ticks, -- 30 secs
	state = 1,
	states = {
		'unclaimed',
		'init',
		'traveling',
		'running',
		'complete',
		'aborted',
	}
}

function task:traveling()
end

function task:running()
end

function task:complete()
end

function task.new(settings)
	return setmetatable((settings or {}), { __index = task })
end

function task:update()
	local state = self.states[self.state]
	if state == 'unclaimed' then return end
	self.ticks -= 1
	if self.ticks < 1 then
		self.state = #self.states --abort
		return
	end
	-- call the function on this task relevant to the current state
	state = self.states[self.state]
	self[state](self)
end

function task:advance()
	self.state += 1
	self.ticks = default_ticks
end
-->8
-- tests
-- translation tests
--[[
printh(pos_to_index(point(4, 0))) -- should be 4
printh(pos_to_index(point(1, 4))) -- should be 65
local pos = index_to_pos(5)
printh(pos.x .. ' ' .. pos.y) -- should be 5, 0
local pos2 = index_to_pos(254)
printh(pos2.x .. ' ' .. pos2.y) -- should be 14, 15
--]]


-- get_valid_neighbors_tests
--[[
printh('--0,0--')
-- expected: 1, 16, 17
local n1 = get_valid_neighbors({pos = point(0,0)})
for n in all(n1) do
	local posn = index_to_pos(n)
	printh('i:' .. n .. ' x,y: '.. posn.x .. ',' ..posn.y)
end
printh('--4,2--')
local n2 = get_valid_neighbors({pos = point(4,2)})
for n in all(n2) do
	local posn = index_to_pos(n)
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
	local posn = index_to_pos(n)
	printh('i:' .. n .. ' x,y: '.. posn.x .. ',' ..posn.y)
end
--]]

__gfx__
00aaaa0000aaaa0000aaaa00000bb00000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00abaa000aabaa0000abbb0000bbbb000abbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b5bb5000b5bb5000b5bb5000b5bb500ab5bb5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaa00aabbbb0000bbbb0000bbbb0000bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000028000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008e000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeebe000eeece000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0beeee000beece000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500500005005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000077000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000030500050000000770057775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077720555550000077770055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffffffffffff0000755700ffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055005500000077770000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050005000000077770000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000555055500000050050005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003330000000b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ba3300000b3b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b335b00003343530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003b3300000f44000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033000000450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d5000000d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
4352525552525351505151414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4240504251504251415151414241415100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4250414240414241404140414241404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5441524652414451414141524752404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414140414151414141414241505100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5151514251515040414041414041404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041404240514040404340525552405300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051524752515151514250514250414200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041414241415151514240504250504200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040414040505050405452524652524400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041404041435341404140414041404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041414041544441404140414041404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051515051505151505150515051505160600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
