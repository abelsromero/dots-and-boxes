require("libs/utils")
require("coordinates")

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
UI_FONT_SIZE = 16
UI_FONT = nil
UI_PANELS_FONT = nil

assets = {}

local board = Board
boxes = {}
dots = {}

-- movement coordinates & matching dots
movement_source = nil
movement_target = nil
dot_source = nil
dot_target = nil

players_count = 2
current_player = 1

player_lines = {}
player_points = {}
-- consecutive squares done
current_squares = nil
-- signals to continue with the current player
square_closed_in_turn = nil

players_colors = {
  COLOR_BLUE,
  COLOR_WHITE
}

function dot (x, y)
  return {
    x = x,
    y = y,
    player = nil
  }
end

function players_init()
  for i = 1, players_count do
    player_lines[i] = {}
    player_points[i] = 0
  end
end

function score_init()
  current_squares = 0
  square_closed_in_turn = false
end

function love.load()
  players_init()
  score_init()

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

  UI_DOTS = love.graphics.setNewFont(12)
  UI_PANELS_FONT = love.graphics.setNewFont(UI_FONT_SIZE)
  UI_FONT = love.graphics.newFont("assets/BalonkuRegular-la1w.otf", 40)

  --love.keyboard.setKeyRepeat(true)
end

function love.update(dt)

end

function love.keypressed(key, scancode, isrepeat)
  if key == "r" then
    players_init()
  end

  if key == "f1" then
    UI.debug = not UI.debug
  elseif key == "f2" then
    UI.layout = not UI.layout
  elseif key == "escape" then
    print("Bye!")
    love.event.quit()
  end
end

function distance (x, y, i, j)
  local dx, dy = x - i, y - j
  return math.sqrt((dx * dx) + (dy * dy))
end

-- TODO optimize: this is used a lot
function find_dot (x, y)
  for i, _ in ipairs(dots) do
    for _, v in ipairs(dots[i]) do
      local distance = distance(x, y, v.x, v.y)
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

    if dot_source and dot_target then
      -- Q: distance(unpack(dot_source), (dot_target)) caused to pass nil
      local distance = distance(dot_source.x, dot_source.y, dot_target.x, dot_target.y)
      if distance > BOX_SIZE then
        dot_target = nil
      end
    end
  end
end

function is_horizontal (dot_source, dot_target)
  return dot_source.y == dot_target.y
end

function line_is_drawn(x, y, i, j)
  for player = 1, players_count do
    for _, v in ipairs(player_lines[player]) do
      local source, target = v[1], v[2]
      --print("player_line: ", i, #player_lines[player], dump(v), ">>", "(" .. x .. "," .. y .. ")" .. "," .. "(" .. i .. "," .. j .. ")")
      if source.x == x and source.y == y and target.x == i and target.y == j then
        --print("match 1")
        return true
      end
      if source.x == i and source.y == j and target.x == x and target.y == y then
        --print("match 2")
        return true
      end
    end
  end
  return false
end

function score_increase()
  player_points[current_player] = player_points[current_player] + 1
  current_squares = current_squares + 1
  square_closed_in_turn = true
end

-- params are coordinates
function score_check (source, target)
  local side = BOX_SIZE
  local x, y = source.x, source.y
  local i, j = target.x, target.y
  -- VERTICAL
  if is_horizontal(source, target) then
    -- TODO is it worth filtering invalid dots?
    --print("*** Checking H: ", dump(source), dump(target))
    local top = line_is_drawn(x, y - side, i, j - side)
    local top_left = line_is_drawn(x, y, i - side, j - side)
    local top_right = line_is_drawn(x + side, y - side, i, j)

    --print("Top:    " .. tostring(top) .. " | top-L: " .. tostring(top_left) .. " | top-R: " .. tostring(top_right))
    if top and top_left and top_right then
      score_increase()
      return
    end

    local bottom = line_is_drawn(x, y + side, i, j + side)
    local bottom_left = line_is_drawn(x, y, i - side, j + side)
    local bottom_right = line_is_drawn(x + side, y + side, i, j)

    --print("Bottom: " .. tostring(bottom) .. " | bot-L: " .. tostring(bottom_left) .. " | bot-R: " .. tostring(bottom_right))
    if bottom and bottom_left and bottom_right then
      score_increase()
      return
    end
    -- VERTICAL
  else
    --print("*** Checking V: ", dump(source), dump(target))
    local left = line_is_drawn(x - side, y, i - side, j)
    local left_top = line_is_drawn(x, y, i - side, j - side)
    local left_bottom = line_is_drawn(x - side, y + side, i, j)

    --print("Left: " .. tostring(left) .. " | left-T: " .. tostring(left_top) .. " | left-B: " .. tostring(left_bottom))
    if left and left_top and left_bottom then
      score_increase()
      return
    end

    local right = line_is_drawn(x + side, y, i + side, j)
    local right_top = line_is_drawn(x, y, i + side, j - side)
    local right_bottom = line_is_drawn(x + side, y + side, i, j)

    --print("Right: " .. tostring(right) .. " | right-T: " .. tostring(right_top) .. " | right-B: " .. tostring(right_bottom))
    if right and right_top and right_bottom then
      score_increase()
      --print("*** Checking V: ", dump(source), dump(target))
    end

    square_closed_in_turn = false
  end

end

-- TODO prevent inserting the same twice, or same movement as another player
function player_save_movement (source, target)
  -- sort is done before, keeping this to be 100% sure until test is in place
  local movement = { movement_sort(source, target) }
  table.insert(player_lines[current_player], movement)
end

function movement_clear ()
  dot_source, dot_target = nil
  movement_source, movement_target = nil
end

function players_next ()
  if not square_closed_in_turn then
    local next_player = current_player + 1
    if next_player > players_count then
      current_player = 1
    else
      current_player = next_player
      current_squares = 0
    end
  end
end

function love.mousereleased (x, y, button, istouch)
  -- user is selecting 2 valid dots
  if dot_source and dot_target then
    local source, target = movement_sort(dot_source, dot_target)
    player_save_movement(source, target)
    score_check(source, target)
    players_next()
  end

  movement_clear()
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

function draw_player_lines (lines, color)
  --love.graphics.push("all")
  if next(lines) then
    local originalColor = { love.graphics.getColor() }
    local originalLineWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(DOT_RADIUS * 2 - 2)
    for i, v in ipairs(lines) do
      --print("color", dump(color))
      love.graphics.setColor(color[1], color[2], color[3])
      local source, target = v[1], v[2]
      love.graphics.line(source.x, source.y, target.x, target.y)
    end
    love.graphics.setColor(originalColor)
    love.graphics.setLineWidth(originalLineWidth)
  end
  --love.graphics.pop()
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
    -- FIXME grey does not work?
    love.graphics.setColor(unpack(COLOR_WHITE))
    love.graphics.circle("fill", dot.x, dot.y, DOT_RADIUS)
  end

  love.graphics.pop()

  if UI.debug then
    love.graphics.push()
    love.graphics.setFont(UI_DOTS)
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
      draw_dot(v, i, j)
    end
  end
end

function draw_layout()
  love.graphics.setColor(COLOR_GREEN)
  for i, _ in ipairs(boxes) do
    for _, v in ipairs(boxes[i]) do
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

  for i = 1, players_count do
    draw_player_lines(player_lines[i], players_colors[i])
  end
  draw_dots()
  -- draw movement at the end to display line above all other elements
  draw_movement()
  -- drawLimits()

  -- restore color
  love.graphics.setColor(unpack(originalColor))

  if UI.debug then
    love.graphics.setFont(UI_PANELS_FONT)
    local rowHeight = UI_FONT_SIZE + 2
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, rowHeight)
    love.graphics.print("Player 1 (lin/squ): " .. #player_lines[1] .. "/" .. player_points[1], 10, UI_FONT_SIZE + (rowHeight * 1))
    love.graphics.print("Player 2 (lin/squ): " .. #player_lines[2] .. "/" .. player_points[2], 10, UI_FONT_SIZE + (rowHeight * 2))
    love.graphics.print("Dots: " .. dump(dot_source) .. "->" .. dump(dot_target), 10, UI_FONT_SIZE + (rowHeight * 3))
  end

  local width, height = love.graphics.getDimensions()

  love.graphics.push("all")
  love.graphics.setFont(UI_FONT)
  love.graphics.setColor(COLOR_GREEN)
  local topMargin = 20
  if square_closed_in_turn then
    love.graphics.print("Player " .. current_player .. " continues!", width - 550, topMargin)
  else
    love.graphics.print("Go player " .. current_player .. " !", width - 500, topMargin)
  end
  love.graphics.pop()
end
