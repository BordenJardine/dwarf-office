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
