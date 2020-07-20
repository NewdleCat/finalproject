function LoadLevelFromImage(imagePath)
    -- initialize the map as a 2d array, all zeroes
    Map = {}
    MapThings = {}
    CurrentlyActiveWizards = {}
    local image = love.image.newImageData(imagePath)
    MapSize = 16
    for x=0, MapSize-1 do
        Map[x] = {}
        MapThings[x] = {}
        for y=0, MapSize-1 do
            Map[x][y] = 0
        end
    end

    -- reset the camera
    -- and list of all objects in the scene (ThingList)
    Camera = {x=64*8,y=64*8, zoom=1/0.8}
    Camera.x = Camera.x - love.graphics.getWidth()*Camera.zoom/2
    Camera.y = Camera.y - love.graphics.getHeight()*Camera.zoom/2
    ThingList = {}

    -- load the image from the path and set tiles coresponding to the pixel at that position
    for x=0, MapSize-1 do
        for y=0, MapSize-1 do
            local r,g,b,a = image:getPixel(x,y)

            if r == 0 and g == 0 and b == 0 then
                SetTile(x,y, WALL_TILE)
            end
        end
    end
end

function GetTile(x,y)
    if x < 0 or y < 0 or x >= MapSize or y >= MapSize then return false end
    return Map[x][y]
end

function SetTile(x,y, value)
    if x < 0 or y < 0 or x >= MapSize or y >= MapSize then return end
    Map[x][y] = value

    -- if there was a visual at this tile displaying it, then destroy the old visual
    if MapThings[x][y] then
        MapThings[x][y].dead = true
    end

    -- add a visual just to display the tile
    if value == FIRE_TILE then
        MapThings[x][y] = AddToThingList(NewFireTileVisual(x,y))
    end

    if value == WALL_TILE then
        MapThings[x][y] = AddToThingList(NewWall(x,y))
    end

    if value == HEAL_TILE then
        MapThings[x][y] = AddToThingList(NewHealTileVisual(x, y))
    end
end

function IsTileWalkable(x,y)
    if x < 0 or y < 0 or x >= MapSize or y >= MapSize then return false end
    return Map[x][y] ~= WALL_TILE
end

function WorldToTileCoords(x,y)
    return math.floor(x/64), math.floor(y/64)
end

function IsInsideArena(x,y)
    return x >= 0 and y >= 0 and x <= 16*64 and y <= 16*64
end
