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
