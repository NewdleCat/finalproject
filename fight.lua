function InitializeTournament()
    BrainList = CreateBrainList()
    ColorList = CreateColorList()
    FLOOR_TILE = 0
    WALL_TILE = 1
    FIRE_TILE = 2
    HEAL_TILE = 3

    Bracket = {}
    CurrentlyActiveWizards = {}
    RoundIndex = 1
    MatchIndex = 1

    -- formatted like Bracket[round][match]
    for i=1, ROUND_COUNT do
        Bracket[i] = {}
    end
    for i=1, CONTESTANT_COUNT/2 do
        Bracket[1][i] = {i*2-1, i*2}
    end

    LoadMatch()
end

function MoveWinnerToNextMatch()
    -- determine which wizard won
    local winner = CurrentlyActiveWizards[WinningWizard]

    -- move the winner into the next match
    if RoundIndex+1 <= ROUND_COUNT then
        local nextMatch = math.floor((MatchIndex-1)/2) +1
        if not Bracket[RoundIndex+1][nextMatch] then
            Bracket[RoundIndex+1][nextMatch] = {}
        end
        table.insert(Bracket[RoundIndex+1][nextMatch], winner.id)
        print("wizard " .. winner.brainIndex .. " moves on to match " .. nextMatch .. " of round " .. RoundIndex+1)
    else
        print(winner.id .. " wins the tournament!")
        TournamentOver = true
    end
end

function NextMatch()
    -- move on to the next match
    if RoundIndex <= ROUND_COUNT then
        MatchIndex = MatchIndex + 1
        if MatchIndex > #Bracket[RoundIndex] then
            MatchIndex = 1
            RoundIndex = RoundIndex + 1
        end
    end

    if RoundIndex <= ROUND_COUNT then
        LoadMatch()
        print("on to match " .. MatchIndex .. " of round " .. RoundIndex)
    end
end

function LoadMatch()
    -- reset arena
    LoadLevelFromImage("maps/map1.png")

    -- add the wizards to the scene
    local match = Bracket[RoundIndex][MatchIndex]
    local wizard1 = match[1]
    local wizard2 = match[2]
    local x1,y1 = 64*14.5, 64*14.5
    local x2,y2 = 64*1.5, 64*1.5
    ContainsPlayer = false

    if BrainList[wizard1] then
        local bot = AddToThingList(NewBot(x1,y1, ColorList[wizard1]))
        bot.brain = BrainList[wizard1]
        bot.brain.owner = bot
        bot.brainIndex = wizard1
        wizard1 = bot
    else
        ThePlayer = AddToThingList(NewPlayer(x1,y1, ColorList[wizard1]))
        ThePlayer.brainIndex = wizard1
        wizard1 = ThePlayer
        ContainsPlayer = true
    end

    if BrainList[wizard2] then
        local bot = AddToThingList(NewBot(x2,y2, ColorList[wizard2]))
        bot.brain = BrainList[wizard2]
        bot.brain.owner = bot
        bot.brainIndex = wizard2
        wizard2 = bot
    else
        ThePlayer = AddToThingList(NewPlayer(x2,y2, ColorList[wizard2]))
        ThePlayer.brainIndex = wizard2
        wizard2 = ThePlayer
        ContainsPlayer = true
    end

    -- make the wizards enemies
    wizard1.enemy = wizard2
    wizard2.enemy = wizard1

    -- bookkeeping so the game knows who the wizards are
    CurrentlyActiveWizards[1] = wizard1
    CurrentlyActiveWizards[1].id = match[1]
    CurrentlyActiveWizards[2] = wizard2
    CurrentlyActiveWizards[2].id = match[2]

    -- set a time limit for the match and how long the victory animation should be
    MatchTimeLimit = 60
    MatchStartTime = 4
    MatchWinTime = 5
    WinningWizard = nil
    MatchOver = false

    KNOCKOUT = 1
    TIMEOUT = 2
    WinType = KNOCKOUT

    love.audio.play(Sounds.countdown)
end

function UpdateMatch()
    UpdateController = UpdateController - 1/60

    -- run the update function multiple times based on the SimulationMultiplier variable
    for s=1, SimulationMultiplier do
        local wasMatchOver = MatchOver

        -- a global timer that's used for shader code
        Timer = Timer + 1/60

        -- for some weird reason i can't figure out, even tho SimulationMultiplier is higher than 1 in the intro
        -- it doesn't do the for loop multiple times (which seems impossible!)
        -- so to fix this, i just multiplied the deltatime by SimulationMultiplier
        if MatchStartTime > 0 then
            local lastMatchStartTime = MatchStartTime
            MatchStartTime = MatchStartTime - SimulationMultiplier*1/60

            if lastMatchStartTime > 1 and MatchStartTime <= 1 then
                love.audio.play(Sounds.matchstart)
            end

            if MatchStartTime > 1 then
                return
            end
        end

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

            -- check for dead wizards
            -- do this inside the thing update loop so that if two wizards die on the same frame
            -- one is caught before the other and a winner is still found
            MatchOver = false
            if CurrentlyActiveWizards[1].dead then
                WinningWizard = 2
                MatchOver = true
            elseif CurrentlyActiveWizards[2].dead then
                WinningWizard = 1
                MatchOver = true
            end
        end

        -- slowly pan the camera over to the winner
        if MatchOver then
            if not wasMatchOver then
                MoveWinnerToNextMatch()
            end

            if MatchWinTime == 5 then
                SimulationMultiplier = 1
                love.audio.stop(Sounds.cheering)
                love.audio.play(Sounds.cheering)
            end

            MatchWinTime = MatchWinTime - 1/60
            Camera.x = Lerp(Camera.x, CurrentlyActiveWizards[WinningWizard].x - love.graphics.getWidth()*Camera.zoom/2, 0.075)
            Camera.y = Lerp(Camera.y, CurrentlyActiveWizards[WinningWizard].y - love.graphics.getHeight()*Camera.zoom/2, 0.075)
        end

        -- if the match goes on for too long, kill a random wizard
        if not MatchOver then
            MatchTimeLimit = math.max(MatchTimeLimit - 1/60, 0)
        end
        if MatchTimeLimit <= 0 and not MatchOver then
            WinType = TIMEOUT
            CurrentlyActiveWizards[Choose{1,2}].dead = true
        end

        if MatchWinTime <= 0 then
            NextMatch()
        end
    end
end

function DrawMatch()
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
