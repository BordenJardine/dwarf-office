-->8
-- tasks

unassigned_tasks = {}

function assign_tasks()
	for w in all(workers) do
		if w.task == 'idle' and w.desk != nil then
			add(active_tasks, create_paperwork_task(w))
		end
	end
end

default_task_time = 15 * 30 -- 15 seconds
copy_time = 5 * 30

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
		'abort',
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
	self.worker.task = 'idle'
	task.complete(self)
end

function paperwork_abort(self)
	printh(self.name .. 'task aborted aborted by' .. self.worker.name .. '!')
	self.worker.task = 'idle'
	del(active_tasks, self)
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
		w.task = 'idle'
	end
	task.complete(self)
end

