function Resolution(width, height)
  return {
    width = width,
    height = height
  }
end

resolutions = {}
resolutions['720p-square'] = Resolution(720, 720)
resolutions['720p'] = Resolution(1280, 720)
resolutions['1080p'] = Resolution(1920, 1080)
resolutions['1080p-square'] = Resolution(1080, 1080)

UI = {
  debug = true,
  layout = true
}

function love.conf(t)
  local defaultResolution = resolutions['1080p-square']
  t.window.width = defaultResolution.width
  t.window.height = defaultResolution.height
end
