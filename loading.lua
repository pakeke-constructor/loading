
--[[
planning:

3 balls: R G B

constantly rotating.


We need:
function to reflect the balls across the unit circle


]]


local loading_obj = {}
local mt = {__index = loading_obj}

local sin, cos = math.sin, math.cos
local pi2 = math.pi * 2
local abs = math.abs



local function initialize_balls(self)
    for i=0, 2 do
        local ball = self.balls[i + 1]
        local o = (i/3) * pi2
        ball.tick = o % pi2
        ball.draw_x = 0
        ball.draw_y = 0
    end
end


local function dist(x, y)
    return ((x*x) + (y*y))^0.5
end

local PROJECT_SPEED_RADIUS_RATIO = 8  -- balls move at speed X radius's per second

local function update_draw_pos(ball, loading_radius, dt)
    local x, y = ball.x, ball.y -- target x, y positions
    local dx, dy = ball.draw_x, ball.draw_y
    local max_dist = PROJECT_SPEED_RADIUS_RATIO * loading_radius * dt
    local dd = dist(x - dx, y - dy)
    if dd <= max_dist then
        ball.draw_x = x
        ball.draw_y = y
    else
        local proj_norm_x = (x - dx) / dd
        local proj_norm_y = (y - dy) / dd
        ball.draw_x = ball.draw_x + proj_norm_x * max_dist
        ball.draw_y = ball.draw_y + proj_norm_y * max_dist
    end
end


local function update_ball_positions(self, dt)
    for _, ball in ipairs(self.balls) do
        ball.tick = ball.tick + dt * self.rot_speed
        ball.x = self.radius * sin(ball.tick)
        ball.y = self.radius * cos(ball.tick)
        update_draw_pos(ball, self.radius, dt)
    end
end

local function update_shockwaves(self, dt)
    local time_since_last = self.time_since_last or 0
    self.time_since_last = time_since_last + dt
    if time_since_last > self.shockwave_freq then
        table.insert(self.shockwaves, 0, 0)
        self.time_since_last = self.time_since_last - self.shockwave_freq
    end

    for i, shock in ipairs(self.shockwaves) do
        self.shockwaves[i] = shock + dt
    end

    for i=#self.shockwaves, 1, -1 do
        local shock = self.shockwaves[i]
        if shock > self.shockwave_lifetime then
            self.shockwaves[i] = nil
        end
    end
end


local function ctor(radius, rot_speed, reflect_freq, shockwave_lifetime, shockwave_freq)
    local ret = {
        radius = radius;
        rot_speed = rot_speed;
        reflect_freq = reflect_freq;
        reflect_speed = reflect_freq / 1.5;

        shockwave_lifetime = shockwave_lifetime;
        shockwave_freq = shockwave_freq;

        balls = {{t=0}, {t=0}, {t=0}};

        shockwaves = {}
    }
    initialize_balls(ret)
    return setmetatable(ret, mt)
end


local SHIFT_AM = 2 * math.pi / 6



local function reflect_side(ball, targ_tick)
    local res_tp = (ball.tick + SHIFT_AM) % pi2
    local res_tm = (ball.tick - SHIFT_AM) % pi2

    -- It's either going to be + or -.
    -- We want to pick the tick value that is furtherest away from `targ_tick`.
    if abs(sin(targ_tick) - sin(res_tm)) > abs(sin(targ_tick) - sin(res_tp)) then
        ball.tick = res_tm
    else
        ball.tick = res_tp
    end
end


local function reflect(self, target_i)
    local balls = self.balls
    local i1, i3 = ((target_i-2) % 3) + 1, (target_i % 3) + 1
    local b1 = balls[i1]
    local targ = balls[((target_i-1) % 3) + 1]
    local b2 = balls[i3]

    assert(b1 ~= b2 and b2 ~= targ and b1 ~= targ,  "Ey?")

    targ.tick = (targ.tick + math.pi) % pi2
    reflect_side(b1, targ.tick)
    reflect_side(b2, targ.tick)
end

local function update_reflect(self, dt)
    --lol
    self.last_reflect_index = self.last_reflect_index or 1
    self.time_since_last_reflect = self.time_since_last_reflect or 0
    self.time_since_last_reflect = self.time_since_last_reflect + dt
    if self.time_since_last_reflect > self.reflect_freq then
        reflect(self, self.last_reflect_index)
        self.last_reflect_index = self.last_reflect_index + 1
        self.time_since_last_reflect = self.time_since_last_reflect - self.reflect_freq
    end
end


local cols = {
    {1,0,0};
    {0,1,0};
    {0,0,1}
}

local function ball_draw(ball, loading_radius, x, y, i)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("line", x + ball.draw_x, y + ball.draw_y, loading_radius / 4)
    love.graphics.setColor(cols[i])
    love.graphics.circle("fill", x + ball.draw_x, y + ball.draw_y, loading_radius / 4)
end


local function draw_connections(self, x, y)
    love.graphics.setLineWidth(self.radius/4)
    for i=1, 3 do
        local neighbour_i = (i % 3) + 1
        local col_r = cols[i][1] + cols[neighbour_i][1]
        local col_g = cols[i][2] + cols[neighbour_i][2]
        local col_b = cols[i][3] + cols[neighbour_i][3]

        local b1 = self.balls[i]
        local b2 = self.balls[neighbour_i]
        love.graphics.setColor(col_r, col_g, col_b, 0.6)
        love.graphics.line(x + b1.draw_x, y + b1.draw_y, x + b2.draw_x, y + b2.draw_y)
    end

end


function loading_obj:draw(x, y)
    love.graphics.push()
    love.graphics.setLineWidth(self.radius / 8)

    for _, shock in ipairs(self.shockwaves) do
        local alpha = (self.shockwave_lifetime - shock) / self.shockwave_lifetime
        love.graphics.setColor(1,1,1, alpha/1.2)
        love.graphics.circle("line", x, y, self.radius * 0.5 + (1-alpha) * (self.radius * 0.8))
    end

    draw_connections(self,x,y)

    love.graphics.setLineWidth(self.radius/8)
    for i=1, 3 do
        local ball = self.balls[i]
        ball_draw(ball, self.radius, x, y, i)
    end
    love.graphics.pop()
end




function loading_obj:update(dt)
    update_reflect(self, dt)
    update_ball_positions(self, dt)
    update_shockwaves(self, dt)
end



return ctor

