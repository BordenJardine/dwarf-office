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
