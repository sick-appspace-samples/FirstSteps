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
---@return  View.TextDecoration deco
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

---@param point1 float
---@param point2 float
---@param x float
---@return float
local function interpolate(point1, point2, x)
  local distance = Point.getX(point2) - Point.getX(point1)
  local xPos = (x - Point.getX(point1)) / distance
  return Point.getY(point1) * (1 - xPos) + Point.getY(point2) * xPos
end

local function polygonToProfile(polygon, sampleDistance)
  sampleDistance = sampleDistance or 0.1
  local valueVec = {}
  local coordinateVec = {}
  local curPointIndex = 1
  for mm = polygon[1]:getX(), polygon[#polygon]:getX(), sampleDistance do
    while polygon[curPointIndex + 1]:getX() < mm do
      curPointIndex = curPointIndex + 1
    end
    valueVec[#valueVec + 1] = interpolate(polygon[curPointIndex], polygon[curPointIndex + 1], mm)
    coordinateVec[#coordinateVec + 1] = mm
  end
  return Profile.createFromVector(valueVec, coordinateVec)
end

---@param profiles Profile
---@return float min
---@return float max
local function getProfileBoundingBox(profiles)
  if type(profiles) ~= 'table' then
    profiles = {profiles}
  end

  local min, max
  for _, p in pairs(profiles) do
    local minX = Profile.getCoordinate(p, 0)
    local maxX = Profile.getCoordinate(p, Profile.getSize(p) - 1)
    if type(minX) == 'userdata' then
      minX = minX:getX()
      maxX = maxX:getX()
    end
    local minY = Profile.getMin(p)
    local maxY = Profile.getMax(p)
    if not min then
      min = Point.create(minX, minY)
      max = Point.create(maxX, maxY)
    end
    if minX < min:getX() then min:setX(minX) end
    if minY < min:getY() then min:setY(minY) end
    if maxX > max:getX() then max:setX(maxX) end
    if maxY > max:getY() then max:setY(maxY) end
  end
  return min, max
end

local helper = {}
helper.getDeco = getDeco
helper.getTextDeco = getTextDeco
helper.interpolate = interpolate
helper.polygonToProfile = polygonToProfile
helper.getProfileBoundingBox = getProfileBoundingBox
return helper