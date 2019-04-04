-- helper stuff

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
