function coordinate (x, y)
  return {
    x = x,
    y = y
  }
end

function coordinate_to_string(c)
  return "{ x:" .. c.x .. ", y: " .. c.y .. "}"
end

function movement_to_string (source, target)
  return coordinate_to_string(source) .. " -> " .. coordinate_to_string(target)
end

-- sort so returned source is top-left
function movement_sort (source, target)
  if source.x == target.x and source.y > target.y then
    return target, source
  end
  if source.x > target.x then
    return target, source
  end
  return source, target
end
