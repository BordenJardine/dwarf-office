pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- A* pathfinding
-- by @richy486

function _init()

 printh("---------------")
 printh("starting a star")

 wallId = 1
 start = getSpecialTile(17)
 goal = getSpecialTile(16)

 


 printh("start...")

 frontier = {}
 insert(frontier, start, 0)
 came_from = {}
 came_from[vectoindex(start)] = nil
 cost_so_far = {}
 cost_so_far[vectoindex(start)] = 0

 while (#frontier > 0 and #frontier < 1000) do
  current = popEnd(frontier)

  if vectoindex(current) == vectoindex(goal) then
   break
  end

  local neighbours = getNeighbours(current)
  for next in all(neighbours) do
   local nextIndex = vectoindex(next)
  
   local new_cost = cost_so_far[vectoindex(current)]  + 1 -- add extra costs here

   if (cost_so_far[nextIndex] == nil) or (new_cost < cost_so_far[nextIndex]) then
    cost_so_far[nextIndex] = new_cost
    local priority = new_cost + heuristic(goal, next)
    insert(frontier, next, priority)
    
    came_from[nextIndex] = current
    
    if (nextIndex != vectoindex(start)) and (nextIndex != vectoindex(goal)) then
     mset(next[1],next[2],19)
    end
   end 
  end
 end

 printh("find goal..")
 current = came_from[vectoindex(goal)]
 path = {}
 local cindex = vectoindex(current)
 local sindex = vectoindex(start)

 while cindex != sindex do
  add(path, current)
  current = came_from[cindex]
  cindex = vectoindex(current)
 end
 reverse(path)

 for point in all(path) do
  mset(point[1],point[2],18)
 end

 printh("..done")


end

function _update()
 
end

function _draw()
 cls()
 mapdraw(0,0,0,0,16,16)
end

-- manhattan distance on a square grid
function heuristic(a, b)
 return abs(a[1] - b[1]) + abs(a[2] - b[2])
end

-- find all existing neighbours of a position that are not walls
function getNeighbours(pos)
 local neighbours={}
 local x = pos[1]
 local y = pos[2]
 if x > 0 and (mget(x-1,y) != wallId) then
  add(neighbours,{x-1,y})
 end
 if x < 15 and (mget(x+1,y) != wallId) then
  add(neighbours,{x+1,y})
 end
 if y > 0 and (mget(x,y-1) != wallId) then
  add(neighbours,{x,y-1})
 end
 if y < 15 and (mget(x,y+1) != wallId) then
  add(neighbours,{x,y+1})
 end

 -- for making diagonals
 if (x+y) % 2 == 0 then
  reverse(neighbours)
 end
 return neighbours
end

-- find the first location of a specific tile type
function getSpecialTile(tileid)
 for x=0,15 do
  for y=0,15 do
   local tile = mget(x,y)
   if tile == tileid then
    return {x,y}
   end
  end
 end
 printh("did not find tile: "..tileid)
end

-- insert into start of table
function insert(t, val)
 for i=(#t+1),2,-1 do
  t[i] = t[i-1]
 end
 t[1] = val
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
function popEnd(t)
 local top = t[#t]
 del(t,t[#t])
 return top[1]
end

function reverse(t)
 for i=1,(#t/2) do
  local temp = t[i]
  local oppindex = #t-(i-1)
  t[i] = t[oppindex]
  t[oppindex] = temp
 end
end

-- translate a 2d x,y coordinate to a 1d index and back again
function vectoindex(vec)
 return maptoindex(vec[1],vec[2])
end
function maptoindex(x, y)
 return ((x+1) * 16) + y
end
function indextomap(index)
 local x = (index-1)/16
 local y = index - (x*w)
 return {x,y}
end






-- pop the first element off a table (unused
function pop(t)
 local top = t[1]
 for i=1,(#t) do
  if i == (#t) then
   del(t,t[i])
  else
   t[i] = t[i+1]
  end
 end
 return top
end



__gfx__
000000000ccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08999980070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08988980070000700002800000015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08988980070000700008800000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08999980070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccc000000000000000000000000000000000ccccccc0ccccccc000000000000000000000000000000000ccccccc0ccccccc00000000000000000ccccccc
c111111c07777770000000000000000000000000c111111cc111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111c
c111111c07000070000000000000000000000000c111111cc111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111c
c111111c07000070000150000001500000015000c111111cc111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111c
c111111c07000070000550000005500000055000c111111cc111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111c
c111111c07000070000000000000000000000000c111111cc111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111c
c111111c07777770000000000000000000000000c111111cc111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111c
cccccccc00000000000000000000000000000000cccccccccccccccc00000000000000000000000000000000cccccccccccccccc0000000000000000cccccccc
0ccccccc000000000000000000000000000000000ccccccc0ccccccc00000000000000000000000000000000000000000ccccccc0ccccccc000000000ccccccc
c111111c00000000000000000000000000000000c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c
c111111c00000000000000000000000000000000c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c
c111111c00028000000280000001500000015000c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c
c111111c00088000000880000005500000055000c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c
c111111c00000000000000000000000000000000c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c
c111111c00000000000000000000000000000000c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c
cccccccc00000000000000000000000000000000cccccccccccccccc0000000000000000000000000000000000000000cccccccccccccccc00000000cccccccc
0ccccccc000000000000000000000000000000000ccccccc0ccccccc00000000000000000ccccccc0ccccccc000000000000000000000000000000000ccccccc
c111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111c00015000000280000002800000015000c111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111c00055000000880000008800000055000c111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111c00000000000000000000000000000000c111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
cccccccc00000000000000000000000000000000cccccccccccccccc0000000000000000cccccccccccccccc00000000000000000000000000000000cccccccc
0ccccccc0ccccccc00000000000000000ccccccc0ccccccc0ccccccc00000000000000000ccccccc0ccccccc000000000000000000000000000000000ccccccc
c111111cc111111c0000000000000000c111111cc111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111cc111111c0001500000028000c111111cc111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111cc111111c0005500000088000c111111cc111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111cc111111c0000000000000000c111111cc111111c00000000000000000000000000000000c111111c
cccccccccccccccc0000000000000000cccccccccccccccccccccccc0000000000000000cccccccccccccccc00000000000000000000000000000000cccccccc
0ccccccc0ccccccc00000000000000000ccccccc0ccccccc0ccccccc000000000ccccccc0ccccccc00000000000000000000000000000000000000000ccccccc
c111111cc111111c0000000000000000c111111cc111111cc111111c00000000c111111cc111111c0000000000000000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111cc111111c00000000c111111cc111111c0000000000000000000000000000000000000000c111111c
c111111cc111111c0001500000028000c111111cc111111cc111111c00000000c111111cc111111c0000000000000000000000000000000000000000c111111c
c111111cc111111c0005500000088000c111111cc111111cc111111c00000000c111111cc111111c0000000000000000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111cc111111c00000000c111111cc111111c0000000000000000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111cc111111c00000000c111111cc111111c0000000000000000000000000000000000000000c111111c
cccccccccccccccc0000000000000000cccccccccccccccccccccccc00000000cccccccccccccccc0000000000000000000000000000000000000000cccccccc
0ccccccc0ccccccc00000000000000000ccccccc0ccccccc00000000000000000ccccccc0000000000000000000000000000000000000000000000000ccccccc
c111111cc111111c0000000000000000c111111cc111111c0000000000000000c111111c000000000000000000000000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111c0000000000000000c111111c000000000000000000000000000000000000000000000000c111111c
c111111cc111111c0001500000028000c111111cc111111c0001500000015000c111111c000150000001500000015000000000000000000000000000c111111c
c111111cc111111c0005500000088000c111111cc111111c0005500000055000c111111c000550000005500000055000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111c0000000000000000c111111c000000000000000000000000000000000000000000000000c111111c
c111111cc111111c0000000000000000c111111cc111111c0000000000000000c111111c000000000000000000000000000000000000000000000000c111111c
cccccccccccccccc0000000000000000cccccccccccccccc0000000000000000cccccccc000000000000000000000000000000000000000000000000cccccccc
0ccccccc0ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
c111111cc111111c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111cc111111c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111cc111111c00015000000280000001500000015000000150000001500000015000000150000001500000015000000150000000000000000000c111111c
c111111cc111111c00055000000880000005500000055000000550000005500000055000000550000005500000055000000550000000000000000000c111111c
c111111cc111111c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111cc111111c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc
0ccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111c0001500000015000000280000002800000015000000150000001500000015000000150000001500000015000000150000000000000000000c111111c
c111111c0005500000055000000880000008800000055000000550000005500000055000000550000005500000055000000550000000000000000000c111111c
c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc
0ccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111c0001500000015000000150000002800000028000000280000002800000028000000280000001500000015000000150000000000000000000c111111c
c111111c0005500000055000000550000008800000088000000880000008800000088000000880000005500000055000000550000000000000000000c111111c
c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
c111111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c111111c
cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc
0ccccccc000000000000000000000000000000000000000000000000000000000ccccccc000000000000000000000000000000000ccccccc000000000ccccccc
c111111c00000000000000000000000000000000000000000000000000000000c111111c00000000000000000000000000000000c111111c00000000c111111c
c111111c00000000000000000000000000000000000000000000000000000000c111111c00000000000000000000000000000000c111111c00000000c111111c
c111111c00015000000150000001500000015000000150000001500000015000c111111c00028000000280000002800000015000c111111c00000000c111111c
c111111c00055000000550000005500000055000000550000005500000055000c111111c00088000000880000008800000055000c111111c00000000c111111c
c111111c00000000000000000000000000000000000000000000000000000000c111111c00000000000000000000000000000000c111111c00000000c111111c
c111111c00000000000000000000000000000000000000000000000000000000c111111c00000000000000000000000000000000c111111c00000000c111111c
cccccccc00000000000000000000000000000000000000000000000000000000cccccccc00000000000000000000000000000000cccccccc00000000cccccccc
0ccccccc000000000000000000000000000000000000000000000000000000000ccccccc000000000ccccccc00000000000000000ccccccc000000000ccccccc
c111111c00000000000000000000000000000000000000000000000000000000c111111c00000000c111111c0000000000000000c111111c00000000c111111c
c111111c00000000000000000000000000000000000000000000000000000000c111111c00000000c111111c0000000000000000c111111c00000000c111111c
c111111c00015000000150000001500000015000000150000001500000015000c111111c00015000c111111c0002800000015000c111111c00000000c111111c
c111111c00055000000550000005500000055000000550000005500000055000c111111c00055000c111111c0008800000055000c111111c00000000c111111c
c111111c00000000000000000000000000000000000000000000000000000000c111111c00000000c111111c0000000000000000c111111c00000000c111111c
c111111c00000000000000000000000000000000000000000000000000000000c111111c00000000c111111c0000000000000000c111111c00000000c111111c
cccccccc00000000000000000000000000000000000000000000000000000000cccccccc00000000cccccccc0000000000000000cccccccc00000000cccccccc
0ccccccc0ccccccc00000000000000000000000000000000000000000ccccccc0ccccccc000000000ccccccc00000000000000000ccccccc0ccccccc0ccccccc
c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c0088880000000000c111111cc111111cc111111c
c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c0899998000000000c111111cc111111cc111111c
c111111cc111111c0001500000015000000150000001500000015000c111111cc111111c00015000c111111c0898898000000000c111111cc111111cc111111c
c111111cc111111c0005500000055000000550000005500000055000c111111cc111111c00055000c111111c0898898000000000c111111cc111111cc111111c
c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c0899998000000000c111111cc111111cc111111c
c111111cc111111c0000000000000000000000000000000000000000c111111cc111111c00000000c111111c0088880000000000c111111cc111111cc111111c
cccccccccccccccc0000000000000000000000000000000000000000cccccccccccccccc00000000cccccccc0000000000000000cccccccccccccccccccccccc
0ccccccc0ccccccc0ccccccc000000000000000000000000000000000ccccccc00000000000000000000000000000000000000000ccccccc0ccccccc0ccccccc
c111111cc111111cc111111c00000000000000000000000000000000c111111c0000000000000000000000000000000000000000c111111cc111111cc111111c
c111111cc111111cc111111c00000000000000000000000000000000c111111c0000000000000000000000000000000000000000c111111cc111111cc111111c
c111111cc111111cc111111c00015000000150000001500000015000c111111c0000000000015000000000000000000000000000c111111cc111111cc111111c
c111111cc111111cc111111c00055000000550000005500000055000c111111c0000000000055000000000000000000000000000c111111cc111111cc111111c
c111111cc111111cc111111c00000000000000000000000000000000c111111c0000000000000000000000000000000000000000c111111cc111111cc111111c
c111111cc111111cc111111c00000000000000000000000000000000c111111c0000000000000000000000000000000000000000c111111cc111111cc111111c
cccccccccccccccccccccccc00000000000000000000000000000000cccccccc0000000000000000000000000000000000000000cccccccccccccccccccccccc
0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0000000000000000000000000000000000000000000000000ccccccc0ccccccc
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c000000000000000000000000000000000000000000000000c111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c000000000000000000000000000000000000000000000000c111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c000000000000000000000000000000000000000000000000c111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c000000000000000000000000000000000000000000000000c111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c000000000000000000000000000000000000000000000000c111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c000000000000000000000000000000000000000000000000c111111cc111111c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000cccccccccccccccc
0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
c111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111cc111111c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0111000000010100000000010100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000010100000000000101000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000010100000101000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000001010100000101000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000001010100010100000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000001010000010000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000010000000001000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000010001000001000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000001010001100001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010000000001000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000632001320043200130001300013000330001300013001230012300123001230012300123001230012300123001230012300123001230012300173001230012300123001730017300173001730017300
