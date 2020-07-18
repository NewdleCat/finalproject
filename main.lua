require "things"

function love.load()
    love.window.setMode(1600, 1600*9/16, {vsync=true})
    UpdateController = 0

    Camera = {x=0,y=0, zoom=1/0.8}

    -- ThingList is the list of all currently active things in the game
    ThingList = {}
    AddToThingList(NewWizard(100,100))
    ThePlayer = AddToThingList(NewPlayer(500,500))
end

function AddToThingList(thing)
    table.insert(ThingList, thing)
    return thing
end

function love.update(dt)
    -- control the update cycle to always run at 60 times per second
    -- we could deltatime every physical interaction in the game, but eh fuck it
    UpdateController = UpdateController + dt
    while UpdateController > 1/60 do
        UpdateController = UpdateController - 1/60

        -- update all things in the ThingList
        for i,thing in pairs(ThingList) do
            -- if this thing's update function returns false, remove it from the list
            if not thing:update(1/60) then
                ThingList[i] = nil
            end
        end
    end

    Camera.x = ThePlayer.x - (love.graphics.getWidth()/2)*Camera.zoom
    Camera.y = ThePlayer.y - (love.graphics.getHeight()/2)*Camera.zoom
end

function love.draw()
    -- move and scale the game according to the camera
    love.graphics.push()
    love.graphics.scale(1/Camera.zoom,1/Camera.zoom)
    love.graphics.translate(math.floor(-1*Camera.x),math.floor(-1*Camera.y))

    -- draw the arena
    love.graphics.setLineWidth(8)
    local tileSize = 64
    for x=1, 16 do
        for y=1, 16 do
            love.graphics.setColor(0.425,0.425,0.425)
            love.graphics.rectangle("line", (x-1)*tileSize,(y-1)*tileSize, tileSize,tileSize)
            love.graphics.setColor(0.5,0.5,0.5)
            love.graphics.rectangle("fill", (x-1)*tileSize,(y-1)*tileSize, tileSize,tileSize)
        end
    end

    -- draw all things in the ThingList
    love.graphics.setLineWidth(5)
    for i,thing in pairs(ThingList) do
        love.graphics.setColor(1,1,1)
        thing:draw()
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
