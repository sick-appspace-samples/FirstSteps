--[[----------------------------------------------------------------------------

  Application Name:
  FirstSteps

  Summary:
  Introduction to the possibilities of the Profile API

  Description:
  This Sample shows how to use the basic algorithms of the Profile API. It is
  related to the according tutorial and shows for example how to calculate metadata,
  use the derivatives or smooth data.

  How to run:
  Starting this sample is possible either by running the app (F5) or
  debugging (F7+F10). Setting breakpoint on the first row inside the 'main'
  function allows debugging step-by-step after 'Engine.OnStarted' event.
  Results can be seen in the viewer on the DevicePage.
  Restarting the Sample may be necessary to show the profiles after loading the webpage.
  To run this Sample a device with SICK Algorithm API and AppEngine >= V2.5.0 is
  required. For example SIM4000 with latest firmware. Alternatively the Emulator
  on AppStudio 2.3 or higher can be used.

  More Information:
  Tutorial "Algorithms - Profile - FirstSteps".

------------------------------------------------------------------------------]]

--Start of Global Scope---------------------------------------------------------

local helper = require('helpers')

local POLYGON = {
  Point.create(10, 0),
  Point.create(20, 0),
  Point.create(20.1, 25),
  Point.create(30, 25),
  Point.create(35, 40),
  Point.create(51, 31),
  Point.create(57, 18),
  Point.create(58, 0),
  Point.create(70, 0)
}

local POLYGON_CHANGED = {
  Point.create(10, 0),
  Point.create(20, 0),
  Point.create(20.1, 25),
  Point.create(35, 40),
  Point.create(51, 31),
  Point.create(57, 18),
  Point.create(58, 0),
  Point.create(70, 0)
}

local BLUE = {59, 156, 208}
local GRAY = {200, 200, 200}
local ORANGE = {242, 148, 0}
local DARK_GRAY = {150, 150, 150}
local RED = {200, 0, 0}

local SAMPLE_DISTANCE = 0.05 --mm

local DELAY = 1500

local viewer = View.create()
local xAxis
local background

local function graphDeco(color, headline, overlay)
  local deco = View.GraphDecoration.create()
  deco:setGraphColor(color[1], color[2], color[3], color[4] or 255)
  deco:setTitle(headline or '')
  deco:setGraphType('LINE')
  deco:setAspectRatio('EQUAL')
  deco:setDrawSize(0.5)
  if overlay then
    deco:setAxisVisible(false)
    deco:setBackgroundVisible(false)
    deco:setGridVisible(false)
    deco:setLabelsVisible(false)
    deco:setTicksVisible(false)
  end
  return deco
end

--@createMeasurementShape(p1:Point, p2:Point)
local function createMeasurementShape(p1, p2)
  local mainLine = Shape.createLineSegment(p1, p2)
  local orthogonalVector = Point.transform(p2:subtract(p1), Transform.createRigid2D(math.pi / 2, 0, 0))
  orthogonalVector = orthogonalVector:normalize()
  local subline1 = Shape.createLineSegment(p1:add(orthogonalVector), p1:subtract(orthogonalVector))
  local subline2 = Shape.createLineSegment(p2:add(orthogonalVector), p2:subtract(orthogonalVector))
  local shapes = {mainLine, subline1, subline2}
  shapes = Shape.transform(shapes, Transform.createTranslation2D(2.5 * orthogonalVector:getX(),
                                                                 -2.5 * orthogonalVector:getY()))
  return shapes
end

local function addProfile(p, c, headline, overlay)
  if (overlay) then
    viewer:addProfile(p, graphDeco(c, headline, overlay), 'overlay')
  else
    viewer:addProfile(p, graphDeco(c, headline, false), 'profile')
  end
end

--@addShape(s:Shape, c:table, lw:float, ps:float)
local function addShape(s, c, lw, ps)
  viewer:addShape(s, helper.getDeco(c, lw, ps))
end

--@addText(t:string, c:table, s:float, x:float, y:float)
local function addText(t, c, s, x, y)
  viewer:addText(t, helper.getTextDeco(c, s, x, y))
end

local function resetView()
  viewer:clear()
  addShape(background, {255, 255, 255})
  addShape(xAxis, DARK_GRAY, 0.3)
end

--@presentAndWait(delay:float)
local function presentAndWait(delay)
  delay = delay or DELAY
  viewer:present()
  Script.sleep(delay)
end

local function main()
  local profile = helper.polygonToProfile(POLYGON, SAMPLE_DISTANCE)
  local profileChanged = helper.polygonToProfile(POLYGON_CHANGED, SAMPLE_DISTANCE)

  -- Derivatives
  local firstDerivative = profile:gaussDerivative(15, 'FIRST')
  firstDerivative = firstDerivative:multiplyConstant(6.5) --amplify derivative
  local secondDerivative = profile:gaussDerivative(45, 'SECOND')
  secondDerivative = secondDerivative:multiplyConstant(100) --amplify derivative

  -- Delta to existing profile
  local absDiff = profile:subtract(profileChanged):abs()
  local validVector = absDiff:binarize(0.1):toVector()
  local valueVector, coordVector = profileChanged:toVector()
  local delta = Profile.createFromVector(valueVector, coordVector, validVector)

  -- Knees
  local extremaIndices = secondDerivative:findLocalExtrema('MAX', 15, 0.1)
  for _, min in pairs(secondDerivative:findLocalExtrema('MIN', 15, 0.1)) do
    extremaIndices[#extremaIndices + 1] = min
  end
  table.sort(extremaIndices)
  local knees = {}
  for _, extremaIndex in pairs(extremaIndices) do
    knees[#knees + 1] = Point.create(profile:getCoordinate(extremaIndex), profile:getValue(extremaIndex))
  end

  -- Gauss
  local gaussedProfile = profile:gauss(45)

  -- Crop
  local croppedProfile = profile:crop(extremaIndices[2], extremaIndices[#knees - 1])

  -- Metadata
  local areaProfile = profile:crop(extremaIndices[1], extremaIndices[#extremaIndices])
  local area = areaProfile:getSum() * SAMPLE_DISTANCE
  local origin = Point.create(areaProfile:getCoordinate(0), areaProfile:getValue(0))
  local pMin, minIndex = areaProfile:getMin()
  local pMax, _ = areaProfile:getMax()
  local width = areaProfile:getCoordinate(areaProfile:getSize() - 1) - areaProfile:getCoordinate(0)
  local height = areaProfile:getMax() - areaProfile:getMin()
  local mean = areaProfile:getMean() --luacheck: ignore

  local maxPoint = Point.create(areaProfile:getCoordinate(minIndex), pMax)
  local minPoint = Point.create(maxPoint:getX(), pMin)

  -------------------------
  -- View -----------------
  -------------------------
  local min, max = helper.getProfileBoundingBox({profile, profileChanged, firstDerivative, secondDerivative})
  xAxis = Shape.createLineSegment(Point.create(min:getX(), 0), Point.create(max:getX(), 0))
  background = Shape.createRectangle(Point.divideConstant(max:add(min), 2),
                                     max:getX() - min:getX() + 20, max:getY() - min:getY() + 20)

  -- Display reference profile
  resetView()
  addProfile(profile, BLUE, 'Reference profile')
  presentAndWait()

  -- Display smoothed profile
  resetView()
  addProfile(profile, GRAY)
  addProfile(gaussedProfile, BLUE, 'Smoothed profile')
  presentAndWait()

  -- Display cropped profile
  resetView()
  addProfile(profile, GRAY, 'Cropped profile')
  addProfile(croppedProfile, BLUE, '', true)
  presentAndWait()

  -- Display first derivative
  resetView()
  addProfile(firstDerivative, BLUE, 'First derivative')
  presentAndWait()

  -- Display second derivative
  resetView()
  addProfile(profile, GRAY)
  addProfile(secondDerivative, BLUE, 'Second derivative')
  presentAndWait()

  -- Display defect
  resetView()
  addProfile(profile, GRAY, 'Defect in profile')
  addProfile(profileChanged, BLUE, '', true)
  presentAndWait(DELAY)
  addProfile(delta, RED, '', true)
  presentAndWait()

  -- Display knees
  resetView()
  addProfile(profile, BLUE, 'Knees of profile')
  addShape(knees, ORANGE, nil, 1.5)
  presentAndWait()

  --Display area
  resetView()
  addProfile(profile, GRAY, 'Metadata of profile')
  addProfile(areaProfile, BLUE, '', true)
  addShape(createMeasurementShape(knees[1], knees[#knees]), RED, 0.5) --width measurement
  addShape(createMeasurementShape(minPoint, maxPoint), RED, 0.5) --height measurement
  addText(area .. "mm²", BLUE, 2.5, origin:getX() + width / 4, origin:getY() + height / 4)
  addText(math.floor(width * 10) / 10 .. " mm", RED, 2, origin:getX() + width / 2.5, origin:getY() - 4.5)
  addText(math.floor(height * 10) / 10 .. " mm", RED, 2, origin:getX() - width / 3, origin:getY() + height / 2)
  presentAndWait()

  print('App finished.')
end
Script.register('Engine.OnStarted', main)
-- serve API in global scope