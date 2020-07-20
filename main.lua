require "things"
require "wizards"
require "brain"

function love.load()
    love.window.setMode(1600, 1600*9/16, {vsync=true})
    UpdateController = 0

    Sounds = {
        fireball = love.audio.newSource("sounds/fireball.mp3", "static"),
        boom = love.audio.newSource("sounds/boom.mp3", "static"),
        death = love.audio.newSource("sounds/death.mp3", "static"),
        zap = love.audio.newSource("sounds/zap.mp3", "static"),
        oof = love.audio.newSource("sounds/oof.mp3", "static"),
        sniper = love.audio.newSource("sounds/sniper.mp3", "static"),
        heal = love.audio.newSource("sounds/heal.mp3", "static"),

        step1 = love.audio.newSource("sounds/step1.mp3", "static"),
        step2 = love.audio.newSource("sounds/step2.mp3", "static"),
        step3 = love.audio.newSource("sounds/step3.mp3", "static"),
        step4 = love.audio.newSource("sounds/step4.mp3", "static"),

        ocean = love.audio.newSource("sounds/ocean2.mp3", "stream"),
    }

    Paused = false

    love.audio.setVolume(0.2)
    Sounds.ocean:setLooping(true)
    Sounds.ocean:setVolume(0.5)
    Sounds.ocean:play()

    Timer = 0
    OceanShader = love.graphics.newShader [[
        uniform float timer;
        uniform float camerax;
        uniform float cameray;
        uniform float zoom;

        vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
        {
            vec4 texcolor = Texel(tex, texture_coords);

            float wave = sin((camerax + screen_coords.x*zoom)/24 - timer/zoom) + sin((cameray + screen_coords.y*zoom + sin((camerax + screen_coords.x*zoom)/40)*15)/24 - timer*0.6/zoom);

            if (wave < 0.1 && wave > -0.1)
            {
                float brightness = 1.4;
                return color * vec4(brightness, brightness, brightness, 1);
            }
            return texcolor * color;
        }
    ]]

    FLOOR_TILE = 0
    WALL_TILE = 1
    FIRE_TILE = 2
    HEAL_TILE = 3
    LoadLevelFromImage("maps/map1.png")
end

function LoadLevelFromImage(imagePath)
    -- initialize the map as a 2d array, all zeroes
    Map = {}
    MapThings = {}
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

    -- add the wizards to the scene
    ThePlayer = AddToThingList(NewPlayer(64*14.5,64*14.5))
    local bot = AddToThingList(NewBot(64*1.5, 64*1.5))
    bot.brain.root = NewSelectorNode()

    local goAway = NewSequenceNode("goAway")
    local goTowards = NewSequenceNode("goTowards")
    local runAwayFromDamage = NewSequenceNode("runAwyFrmDmg")
    goAway.children = {
        NewLineOfSightNode(),
        NewPointTowardsEnemyNode(),
        NewWalkAwayFromEnemyNode(),
        NewSnipeEnemyNode(),
    }
    goTowards.children = {
        NewPointTowardsEnemyNode(),
        NewWalkTowardsEnemyNode(),
    }
    runAwayFromDamage.children = {
        NewIsTakingDamageRightNowNode(),
        NewWalkAwayFromEnemyNode(),
    }

    bot.brain.root.children = {
        runAwayFromDamage,
        goAway,
        goTowards,
    }

    bot.enemy = ThePlayer


    -- load the image from the path and set tiles coresponding to the pixel at that position
    local image = love.image.newImageData(imagePath)
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

function AddToThingList(thing)
    table.insert(ThingList, thing)
    return thing
end

function love.update(dt)
    if Paused then return end

    -- control the update cycle to always run at 60 times per second
    -- we could deltatime every physical interaction in the game, but eh fuck it
    -- this also guarantees that the AI always has the same simulation time between evaluations
    UpdateController = UpdateController + dt

    while UpdateController > 1/60 do
        UpdateController = UpdateController - 1/60

        -- a global timer that's used for shader code
        Timer = Timer + 1/60

        -- update all things in the ThingList
        for i,thing in pairs(ThingList) do
            -- if this thing's update function returns false, remove it from the list
            if not thing:update(1/60) or thing.dead then
                -- if this thing has a death function, do it
                thing.dead = true

                if thing.onDeath then
                    thing:onDeath()
                end

                -- remove it from the list of things to be updated and drawn
                table.remove(ThingList, i)
            end
        end
    end
end

function love.mousepressed(x,y, button)
    -- relay this event to all things that exist
    for i,thing in pairs(ThingList) do
        if thing.mousepressed then
            thing:mousepressed(x,y, button)
        end
    end
end

function love.keypressed(key)
    -- relay this event to all things that exist
    for i,thing in pairs(ThingList) do
        if thing.keypressed then
            thing:keypressed(key)
        end
    end

    if key == "space" then
        Paused = not Paused
    end
end

function love.wheelmoved(x,y)
    Camera.zoom = Camera.zoom - y/10
end

function IsInsideArena(x,y)
    return x >= 0 and y >= 0 and x <= 16*64 and y <= 16*64
end

function love.draw()
    -- move and scale the game according to the camera
    love.graphics.push()
    love.graphics.scale(1/Camera.zoom,1/Camera.zoom)
    love.graphics.translate(math.floor(-1*Camera.x),math.floor(-1*Camera.y))

    -- draw the ocean
    OceanShader:send("timer", Timer)
    OceanShader:send("camerax", Camera.x)
    OceanShader:send("cameray", Camera.y)
    OceanShader:send("zoom", Camera.zoom)
    love.graphics.setShader(OceanShader)
    love.graphics.setColor(0,0.25,0.6)
    love.graphics.rectangle("fill", Camera.x,Camera.y, math.ceil(love.graphics.getWidth()*Camera.zoom)+4,math.ceil(love.graphics.getHeight()*Camera.zoom)+4)
    love.graphics.setShader()

    -- draw the arena
    love.graphics.setLineWidth(8)
    local tileSize = 64
    love.graphics.stencil(function () love.graphics.rectangle("fill", 0,0, 16*tileSize,16*tileSize) end, "replace", 0)
    for x=1, 16 do
        for y=1, 20 do
            if y < 17 then
                local tile = Map[x-1][y-1]
                local dx,dy = (x-1)*tileSize, (y-1)*tileSize
                love.graphics.stencil(function () love.graphics.rectangle("fill", dx,dy,tileSize,tileSize) end, "replace", 1, true)
                love.graphics.setColor(0.425,0.425,0.425)
                love.graphics.rectangle("line", dx,dy, tileSize,tileSize)
                love.graphics.setColor(0.5,0.5,0.5)
                love.graphics.rectangle("fill", dx,dy, tileSize,tileSize)
            else
                local alpha = Conversion(1,0, 17,20, y)
                love.graphics.setColor(0.2,0.2,0.2, alpha)
                love.graphics.rectangle("line", (x-1)*tileSize,(y-1)*tileSize, tileSize,tileSize/2)
                love.graphics.setColor(0.3,0.3,0.3, alpha)
                love.graphics.rectangle("fill", (x-1)*tileSize,(y-1)*tileSize, tileSize,tileSize/2)

                local y = y+0.5
                local alpha = Conversion(1,0, 17,20, y)
                love.graphics.setColor(0.2,0.2,0.2, alpha)
                love.graphics.rectangle("line", (x-1)*tileSize,(y-1)*tileSize, tileSize,tileSize/2)
                love.graphics.setColor(0.3,0.3,0.3, alpha)
                love.graphics.rectangle("fill", (x-1)*tileSize,(y-1)*tileSize, tileSize,tileSize/2)
            end
        end
    end

    -- make things "farther away" (bigger y value) go behind other things
    table.sort(ThingList, function (a,b)
        return a.y < b.y
    end)

    -- draw all things in the ThingList
    love.graphics.setLineWidth(5)
    for i,thing in pairs(ThingList) do
        love.graphics.setColor(1,1,1)
        thing:draw()
    end

    -- draw the shadows on top of the map and the things
    for x=0, 15 do
        for y=0, 15 do
            -- draw wall shadows
            local dx,dy = x*tileSize, y*tileSize
            love.graphics.setColor(0.1,0.1,0.1, 0.5)
            -- bottom right triangle
            if IsTileWalkable(x,y+1) then
                if GetTile(x-1,y+1) == WALL_TILE or GetTile(x,y+1) == WALL_TILE then
                    love.graphics.polygon("fill", dx,dy+tileSize, dx+tileSize,dy+tileSize, dx+tileSize,dy)
                end
            end

            if (IsTileWalkable(x,y) and IsTileWalkable(x,y+1))
            or (not IsTileWalkable(x-1,y+1) and not IsTileWalkable(x,y) and IsTileWalkable(x,y+1)) then
                -- top left triangle
                if GetTile(x-1,y) == WALL_TILE or GetTile(x-1, y+1) == WALL_TILE then
                    love.graphics.polygon("fill", dx,dy, dx+tileSize,dy, dx,dy+tileSize)
                end
            end
        end
    end

    -- draw the health bars on top of everything else
    for i,thing in pairs(ThingList) do
        if thing.drawGui then
            thing:drawGui()
        end
    end

    love.graphics.pop()
end

function DrawOval(x,y, r, squish)
    love.graphics.push()
    love.graphics.translate(x,y)
    love.graphics.scale(1,squish)
    love.graphics.circle("fill", 0,0, r)
    love.graphics.pop()
end

-- a bunch of useful math functions for common tasks
function Lerp(a,b,t) return (1-t)*a + t*b end
function DeltaLerp(a,b,t, dt) return Lerp(a,b, 1 - t^(dt)) end
function Conversion(a,b, p1,p2, t) return Lerp(a,b, Clamp((t-p1)/(p2-p1), 0,1)) end
function TableConversion(a,b, p1,p2, t) local ret = {} for i,v in pairs(a) do ret[i] = Conversion(a[i],b[i], p1,p2, t) end return ret end
function Clamp(n, min,max) return math.max(math.min(n, max),min) end
function Distance(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
function GetAngle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end
