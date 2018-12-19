pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
printh("\n\n-------\n-us sales operations-\n-------")

-- constants

-- sounds

-- game state
actors = {} -- workers and stuff

-- status
idle = 0
walking = 1


-- worker 'class'
worker = {
	player = 0,
	x = 1,
	y = 1,
	sprite = 1,
	task = idle,
}

function worker.new(settings)
	local w = setmetatable((settings or {}), { __index = worker })
	return w
end

function worker:draw()
	spr(
		self.sprite,
		self.x * 8,
		self.y * 8
	)
end

function worker:update()
end

-- game loop stuff
function _init()
	add(actors, worker.new({
		x = 0,
		y = 0,
		sprite = 1
	}))
	add(actors, worker.new({
		x = 15,
		y = 11,
		sprite = 0
	}))
end

function _update()
end

function _draw()
	cls()
	mapdraw(0,0,0,0,16,16)
	for a in all(actors) do
		a:draw()
	end
	draw_indicies()
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

function select(t)
	return t[flr(rnd(#t))+1]
end

-- printing

-- print string with outline.
function printo(str, startx, starty, col, col_bg)
	print(str,startx+1,starty,col_bg)
	print(str,startx-1,starty,col_bg)
	print(str,startx,starty+1,col_bg)
	print(str,startx,starty-1,col_bg)
	print(str,startx+1,starty-1,col_bg)
	print(str,startx-1,starty-1,col_bg)
	print(str,startx-1,starty+1,col_bg)
	print(str,startx+1,starty+1,col_bg)
	print(str,startx,starty,col)
end

--print string centered with
--outline.
function printc(str, x, y, col, col_bg, special_chars)
	local len=(#str*4)+(special_chars*3)
	local startx=x-(len/2)
	local starty=y-2
	printo(str,startx,starty,col,col_bg)
end

function copy(t) -- shallow-copy a table
	-- if type(t) ~= "table" then return t end
	-- local meta = getmetatable(t)
	local target = {}
	for k, v in pairs(t) do target[k] = v end
	-- setmetatable(target, meta)
	return target
end

function unshift(arr, val)
	local tmp = {val}
	for v in all(arr) do
		add(tmp,v)
	end
	return tmp
end

-- math

function distance(p1, p2)
	return sqrt(sqr(p1.x - p2.x) + sqr(p1.y - p2.y))
end

function sqr(x)
	return x * x
end

-- Priority Queue!

-->8

-- Map Stuff

map_graph = {}
min_graph_index = 1
max_graph_index = 16*16
min_x = 0
max_x = 16
min_y = 0
max_y = 16
impassible = 0

function poz(x, y)
	return {x=x, y=y}
end

function get_flag(pos, flag)
	return fget(mget(pos.x, pos.y), flag)
end

-- create a cached graph of the map. Each space on the map is indexed
function generate_map_graph()
	local graph = {}
	for i=min_graph_index,max_graph_index do
		local node = {}
		node.occupants = {}
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
	pos_to_index(poz(4, 0)) -- 4
	pos_to_index(poz(1, 4)) -- 65
	index_to_pos(255) -- 15, 16
-- ]]
function index_to_pos(index)
	local y = flr(index/16)
	local x = index % 16
	return poz(x, y)
end

function pos_to_index(pos)
	return ((pos.y) * 16) + pos.x
end

function get_valid_neighbors(node)
	local neighbors = {}
	if not node.passible then
		return neighbors
	end
	local pos = node.pos
	for yi=-1,1 do
		for xi=-1,1 do
			local neighbor_pos = poz(pos.x + xi,pos.y+yi)
			-- not out of the play area, not the current pos, and passible tile
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

-- helper function that can eventually go away
function draw_indicies()
	for i=min_graph_index,max_graph_index do
		local pos = index_to_pos(i)
		print(i, pos.x * 8, pos.y * 8, 1)
	end
end

-- translation tests
--[[
printh(pos_to_index(pos(4, 0))) -- should be 4
printh(pos_to_index(pos(1, 4))) -- should be 65
local pos = index_to_pos(5)
printh(pos.x .. ' ' .. pos.y) -- should be 5, 0
local pos2 = index_to_pos(254)
printh(pos2.x .. ' ' .. pos2.y) -- should be 14, 15
--]]


-- get_valid_neighbors_tests
--[[
printh('--0,0--')
-- expected: 1, 16, 17
local n1 = get_valid_neighbors({pos = poz(0,0)})
for n in all(n1) do
	local posn = index_to_pos(n)
	printh('i:' .. n .. ' x,y: '.. posn.x .. ',' ..posn.y)
end
printh('--4,2--')
local n2 = get_valid_neighbors({pos = poz(4,2)})
for n in all(n2) do
	local posn = index_to_pos(n)
	printh('i:' .. n .. ' x,y: '.. posn.x .. ',' ..posn.y)
end
--]]

-- map_graph_tests
graph = generate_map_graph()

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




__gfx__
0044440000eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
004f44000eefee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f5ff5000fdffd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffff00eeffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07772700077727000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07772700077727000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500500005005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00544400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04544500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccc4c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
666666666666666666d7dd666666666666d7dd6666d7dd6666d7dd6666d7dd660000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7dd666666666666d7dd6666d7dd6666d7dd6666d7dd660000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7dd6666ddddddddd7dd66ddd7dd66ddd7ddddddd7dddd0000000000000000000000000000000000000000000000000000000000000000
6666d6666666666666d7dd6666d777777777dd667777dd6677777777777777770000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7dd6666d7dddddddddd66ddd7dd66ddddddddddd7dddd0000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7dd6666d7dddddddddd66ddd7dd66ddddddddddd7dddd0000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7dd6666d7dddddddddd66ddd7dd66ddddddddddd7dddd0000000000000000000000000000000000000000000000000000000000000000
666666666666666666d7dd6666d7dddddddddd66ddd7dd66ddddddddddd7dddd0000000000000000000000000000000000000000000000000000000000000000
6666666666666666666666666666666666d7dd666666666666d7dd66000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666666666666666666666d7dd666666666666d7dd66000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666dddddddddddddd6666d7dddddddddddd66d7dddd000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666777777777777dd6666d777777777777766d77777000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666d66ddddddddddd7dd6666ddddddddd7dddd66d7dddd000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666ddddddddddd7dd6666ddddddddd7dddd66d7dddd000000000000000000000000000000000000000000000000000000000000000000000000
6e66666666666666ddddddddddd7dd6666ddddddddd7dddd66d7dddd000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666ddddddddddd7dd6666ddddddddd7dddde6d7dddd000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010000000000000000000001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4140414041414142415141414150414041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4151415051415142514141414141514151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041414143525247525341414141414150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5041515142414142504240414141414141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041414142404142414250414141415150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4150414056524146514440414141404140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414142404141405041414352524141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414142414141414141414250515040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041404142414141415040414241424141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141505141504041435252524541565252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4151414141415041424141414250424141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041415041414151424152524441424151000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5252525552525252455041415041425141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051414241414151424152525252455051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5141414251414143444151414151424141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141404141414140414141414150414140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041415041514141414050514151415050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000