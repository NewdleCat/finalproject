require "things"

function love.load()
    love.window.setMode(1600, 1600*9/16, {vsync=true})
    UpdateController = 0

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
end

function love.draw()
    -- draw all things in the ThingList
    for i,thing in pairs(ThingList) do
        thing:draw()
    end
end
