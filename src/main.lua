require("libs/utils")
-- hot reload
local lick = require("libs/lick")
lick.reset = true
lick.debug = false
--

Board = {
  y_boxes = 12,
  x_boxes = 12,
  x = nil,
  y = nil,
  color = nil
}

COLOR_BLUE = { 0, 0, 255 }
COLOR_GREEN = { 0, 100, 0 }
COLOR_GREY = { 96, 96, 96 }
COLOR_RED = { 255, 0, 0 }
COLOR_WHITE = { 255, 255, 255 }

BOX_SIZE = 45
DOT_RADIUS = 8
DOT_RADIUS_SELECTED = 10

UI_LEFT_MARGIN_PERCENT = 15
UI_TOP_MARGIN_PERCENT = 15
UI_BACKGROUND = { love.math.colorFromBytes(96, 96, 96) }

assets = {

}

local board = Board
boxes = {}
dots = {}

-- movement coordinates & matching dots
movement_source = nil
movement_target = nil
dot_source = nil
dot_target = nil

local fontSize = 12

function coordinate (x, y)
  return {
    x = x,
    y = y
  }
end

function dot (x, y)
  return {
    x = x,
    y = y,
    player = nil
  }
end

function love.load()
  local width, height = love.graphics.getDimensions()

  board.x = (width * UI_LEFT_MARGIN_PERCENT) / 100
  board.y = (height * UI_TOP_MARGIN_PERCENT) / 100
  board.color = { love.math.colorFromBytes(COLOR_WHITE) }

  for i = 1, board.x_boxes + 1 do
    boxes[i] = {}
    dots[i] = {}
    for j = 1, board.y_boxes + 1 do
      local x = board.x + ((i - 1) * BOX_SIZE)
      local y = board.y + ((j - 1) * BOX_SIZE)
      if i <= board.x_boxes and j <= board.y_boxes then
        boxes[i][j] = coordinate(x, y)
      end
      dots[i][j] = coordinate(x, y)
    end
  end

  --local last_column = board.x_boxes + 1
  --local last_column_x = board.x + ((last_column - 1) * BOX_SIZE)
  --dots[last_column] = {}
  --for row = 1, board.y_boxes do
  --  local y = board.y + ((row - 1) * BOX_SIZE)
  --  dots[last_column][row] = coordinate(last_column_x, y)
  --end

  font = love.graphics.setNewFont(fontSize)
  --love.keyboard.setKeyRepeat(true)
end

function love.update(dt)

end

function love.keypressed(key, scancode, isrepeat)
  print("pressed " .. key, isrepeat)
  if key == "f1" then
    UI.debug = not UI.debug
  elseif key == "f2" then
    UI.layout = not UI.layout
  elseif key == "escape" then
    print("Bye!")
    love.event.quit()
  end
end

-- TODO optimize: this is used a lot
function find_dot (x, y)
  for i, _ in ipairs(dots) do
    for _, v in ipairs(dots[i]) do
      local dx, dy = x - v.x, y - v.y
      local distance = math.sqrt(dx * dx + dy * dy)
      if distance < DOT_RADIUS then
        return v
      end
    end
  end
  return nil
end

function love.mousepressed(x, y, button, istouch)
  if button == 1 then
    dot_source = find_dot(x, y)
    movement_source = { x, y }
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  if movement_source ~= nil then
    movement_target = { x, y }
    dot_target = find_dot(x, y)
  end
end

function love.mousereleased(x, y, button, istouch)
  --print("mousereleased", dump(click_pressed))
  dot_source, dot_target = nil
  movement_source, movement_target = nil
end

function drawLimits()
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle("line", board.x, board.y, BOX_SIZE * board.x_boxes, BOX_SIZE * board.y_boxes)
end

function is_pressed(dot)
  --print("is_pressed")
  if dot_source == nil then
    return false
  end
  return dot_source.x == dot.x and dot_source.y == dot.y
end

function draw_movement()
  if dot_source ~= nil then
    if movement_target ~= nil then
      love.graphics.setColor(unpack(COLOR_RED))
      love.graphics.setLineWidth(8)
      -- center line on dot if we are over it
      if dot_target then
        love.graphics.line(dot_source.x, dot_source.y, dot_target.x, dot_target.y)
      else
        love.graphics.line(dot_source.x, dot_source.y, movement_target[1], movement_target[2])
      end
      love.graphics.setLineWidth(1)
    end
  end
  if dot_target ~= nil then
    love.graphics.setColor(unpack(COLOR_RED))
    love.graphics.circle("fill", dot_target.x, dot_target.y, DOT_RADIUS_SELECTED)
  end
end

-- TODO refactor to extract pressed_dot logic
function draw_dot(dot, i, j)
  love.graphics.push()
  if is_pressed(dot) then
    love.graphics.setColor(unpack(COLOR_RED))
    love.graphics.circle("fill", dot.x, dot.y, DOT_RADIUS_SELECTED)
  else
    love.graphics.setColor(unpack(COLOR_WHITE))
    love.graphics.circle("fill", dot.x, dot.y, DOT_RADIUS)
  end

  love.graphics.pop()

  if UI.debug then
    love.graphics.push()
    love.graphics.translate(dot.x, dot.y)
    love.graphics.rotate(-0.3)
    if i ~= nil then
      love.graphics.setColor(unpack(COLOR_WHITE))
      love.graphics.print(i .. "," .. j, 0, 10)
    end
    love.graphics.pop()
  end
end

function draw_dots ()
  for i, _ in ipairs(dots) do
    for j, v in ipairs(dots[i]) do
      -- print(i, j, v.x, v.y)
      draw_dot(v, i, j)
    end
  end
end

function draw_layout()
  love.graphics.setColor(COLOR_GREEN)
  for i, _ in ipairs(boxes) do
    for j, v in ipairs(boxes[i]) do
      --print("box: " .. v.x .. v.y)
      love.graphics.rectangle("line", v.x, v.y, BOX_SIZE, BOX_SIZE)
    end
  end
end

function love.draw()
  -- safe color
  local originalColor = { love.graphics.getColor() }

  love.graphics.setBackgroundColor(UI_BACKGROUND)

  if UI.layout then
    -- TODO fix issue where first layout line has a softer green until a click on dot + drag happens
    draw_layout()
  end
  draw_dots()
  -- draw movement at the end to display line above all other elements
  draw_movement()
  -- drawLimits()

  -- restore color
  love.graphics.setColor(unpack(originalColor))

  if UI.debug then
    local rowHeight = fontSize + 2
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, rowHeight)
  end
end
