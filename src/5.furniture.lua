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
