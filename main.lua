


local loading_ctor = require("loading")

local loading = loading_ctor(60, 0.8, 0.35, 1, 0.4)

function love.draw()
    local w,h = love.graphics.getWidth(), love.graphics.getHeight()
    loading:draw(w/2, h/2)
end


function love.update(dt)
    loading:update(dt)
end




