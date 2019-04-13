-->8
-- worker 'class'

default_step_time = 5
default_idle_time = 5 * 30 -- 5 seconds

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
end

function worker:update_task()
	if self.task == 'idle' then
		self:update_idle()
	end
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

