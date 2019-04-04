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

