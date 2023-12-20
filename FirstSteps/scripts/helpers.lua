-------------------------------------
-- Basic helper functions -----------
-------------------------------------

---@param rgba table
---@param lineWidth float
---@param pointSize float
---@return View.ShapeDecoration deco
local function getDeco(rgba, lineWidth, pointSize)
  lineWidth = lineWidth or 1
  pointSize = pointSize or 1
  rgba = rgba or {0, 0, 0}

  if #rgba == 3 then
    rgba[4] = 255
  end

  local deco = View.ShapeDecoration.create()
  deco:setLineColor(rgba[1], rgba[2], rgba[3], rgba[4])
  deco:setFillColor(rgba[1], rgba[2], rgba[3], rgba[4])
  deco:setLineWidth(lineWidth)
  deco:setPointSize(pointSize)
  return deco
end

---@param rgba table
---@param size float
---@param xPos float
---@param yPos float
---@return View.TextDecoration deco
local function getTextDeco(rgba, size, xPos, yPos)
  size = size or 1
  xPos = xPos or 0
  yPos = yPos or 0
  rgba = rgba or {0, 0, 0}

  if #rgba == 3 then
    rgba[4] = 255
  end

  local deco = View.TextDecoration.create()
  deco:setSize(size)
  deco:setColor(rgba[1], rgba[2], rgba[3], rgba[4])
  deco:setPosition(xPos, yPos)
  return deco
end

local helper = {}
helper.getDeco = getDeco
helper.getTextDeco = getTextDeco
return helper