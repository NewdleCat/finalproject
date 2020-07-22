require "level"
require "fight"
require "things"
require "wizards"
require "nodes"
require "brain"

function love.load(args)
    love.math.setRandomSeed(os.time())
    love.window.setMode(1600, 1600*9/16, {vsync=true})
    UpdateController = 0
    Paused = false
    ShowBehaviorTree = false
    ShowVerticalTree = true
    SimulationMultiplier = 1
    CountdownFont = love.graphics.newFont("comicneue.ttf", 200)
    Font = love.graphics.newFont("comicneue.ttf", 40)
    TreeFont = love.graphics.newFont("comicneue.ttf", 16)
    love.graphics.setFont(Font)
    DevPlayerEnabled = true
    Fastforward = 1
    FastforwardMax = 9

    -- if you give the program "player" as a command line argument, you can be a participant in the tournament
    love.audio.setVolume(0.2)
    for i,v in pairs(args) do
        if v == "sim" then
            DevPlayerEnabled = false
        end

        if v == "player" then
            DevPlayerEnabled = true
        end

        if v == "volume" then
            love.audio.setVolume(args[i+1])
        end

        if v == "skip" then
            SkipCountdown = true
        end
    end

    -- load sounds that will be used in the game
    Sounds = {
        fireball = love.audio.newSource("sounds/fireball.mp3", "static"),
        boom = love.audio.newSource("sounds/boom.mp3", "static"),
        death = love.audio.newSource("sounds/death.mp3", "static"),
        zap = love.audio.newSource("sounds/zap.mp3", "static"),
        oof = love.audio.newSource("sounds/oof.mp3", "static"),
        sniper = love.audio.newSource("sounds/sniper.mp3", "static"),
        heal = love.audio.newSource("sounds/heal.mp3", "static"),
        cheering = love.audio.newSource("sounds/cheering.mp3", "stream"),
        countdown = love.audio.newSource("sounds/countdown.mp3", "stream"),
        matchstart = love.audio.newSource("sounds/matchstart.mp3", "stream"),

        step1 = love.audio.newSource("sounds/step1.mp3", "static"),
        step2 = love.audio.newSource("sounds/step2.mp3", "static"),
        step3 = love.audio.newSource("sounds/step3.mp3", "static"),
        step4 = love.audio.newSource("sounds/step4.mp3", "static"),

        ocean = love.audio.newSource("sounds/ocean2.mp3", "stream"),
    }
    Sounds.ocean:setLooping(true)
    Sounds.ocean:setVolume(0.5)
    Sounds.ocean:play()

    -- load the shader that is used for the ocean
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

    ROUND_COUNT = 4 -- 2^4 = 16 contestants
    CONTESTANT_COUNT = 2^ROUND_COUNT
    InitializeTournament()
end

function AddToThingList(thing)
    table.insert(ThingList, thing)
    return thing
end

function love.update(dt)
    -- fast forward matches where the player is not involved
    if not ContainsPlayer then
        SimulationMultiplier = math.max(Conversion(0,24, 1,FastforwardMax, Fastforward), 1)
        if MatchOver then
            SimulationMultiplier = 1
        end
    else
        SimulationMultiplier = 1
    end

    -- if the game is paused, just don't update anything
    if Paused then return end

    -- control the update cycle to always run at 60 times per second
    -- we could deltatime every physical interaction in the game, but eh fuck it
    -- this also guarantees that the AI always has the same simulation time between evaluations
    UpdateController = UpdateController + dt

    -- pitch up sounds that happen in sped up simulations
    for i,v in pairs(Sounds) do
        v:setPitch(SimulationMultiplier)
    end

    while UpdateController > 1/60 do
        UpdateMatch()
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

    -- space toggles pause
    if key == "space" then
        Paused = not Paused
    end

    -- b toggles showing the behavior tree
    if key == "b" then
        ShowBehaviorTree = not ShowBehaviorTree
    end

    if key == "v" then
        ShowVerticalTree = not ShowVerticalTree
    end

    if key == "f" then
        if not love.keyboard.isDown("lshift") then
            Fastforward = math.min(Fastforward + 1, FastforwardMax)
        else
            Fastforward = math.max(Fastforward - 1, 1)
        end
    end

    if key == "r" then
        InitializeTournament()
    end
end

function love.wheelmoved(x,y)
    Camera.zoom = Camera.zoom - y/10
end

function love.draw()
    -- draw the fight
    DrawMatch()

    -- draw the time remaining in the upper left corner
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Time: " .. math.floor(MatchTimeLimit + 0.5), 32,32)

    -- draw countdown text
    local text = "" .. math.ceil(MatchStartTime -1)
    if MatchStartTime <= 1 then
        text = "Go!"
    end
    if MatchStartTime > 0 then
        love.graphics.setFont(CountdownFont)
        local scale = Conversion(1, 0.5/4, 1,0, 1 - ((MatchStartTime%1)^2))
        love.graphics.setColor(0.8, 0.8, 0.8, Conversion(1,0, 0.85,1, 1 - MatchStartTime%1))
        love.graphics.print(text, love.graphics.getWidth()/2 - CountdownFont:getWidth(text)*scale/2, love.graphics.getHeight()/2 - 40 - CountdownFont:getHeight(text)*scale/2, 0, scale,scale)
        love.graphics.setFont(Font)
    end
    love.graphics.setColor(0.8, 0.8, 0.8)

    -- draw fastforward icon
    if SimulationMultiplier > 1 then
        local cx,cy = love.graphics.getWidth() - 150, 100
        local sep = 25
        love.graphics.circle("fill", cx-sep,cy, 80,3)
        love.graphics.circle("fill", cx+sep,cy, 80,3)
        love.graphics.print("x" .. math.floor(SimulationMultiplier + 0.5), cx,cy + 65)
    end

    -- draw win text when match is over
    if MatchOver then
        local text = "Wizard " .. CurrentlyActiveWizards[WinningWizard].id .. " wins!"
        if WinType == TIMEOUT then
            text = "Wizard " .. CurrentlyActiveWizards[WinningWizard].id .. " wins by timeout!"
        end
        local textWidth = Font:getWidth(text)
        love.graphics.print(text, love.graphics.getWidth()/2 - textWidth/2, love.graphics.getHeight()/2 - 150)
    end

    -- draw the bracket after the match is over for a little while
    if MatchWinTime < 3 then
        DrawBracket()
    end

    -- draw the visualized behavior tree if it exists
    if ShowBehaviorTree and VisualizedTree then
        love.graphics.push()
        love.graphics.scale(0.3,0.3)
        love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()*-1)
        DrawBT(VisualizedTree)
        love.graphics.pop()
    end

    -- draw the vertical behavior trees if enabled
    love.graphics.setFont(TreeFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    verticalTree = nil
    if CurrentlyActiveWizards[1].brain ~= nil and ShowVerticalTree then
        love.graphics.print("Wizard " .. CurrentlyActiveWizards[1].id .. createVerticalTree(CurrentlyActiveWizards[1].brain.root), 1300, 200 ,0 , 1)
    end
    if CurrentlyActiveWizards[2].brain ~= nil and ShowVerticalTree then
        love.graphics.print("Wizard " .. CurrentlyActiveWizards[2].id .. createVerticalTree(CurrentlyActiveWizards[2].brain.root), 50, 200 ,0 , 1)
    end
    love.graphics.setFont(Font)

    -- draw pause screen
    if Paused then
        love.graphics.print("Paused", love.graphics.getWidth()/2 - Font:getWidth("Paused")/2, love.graphics.getHeight()/2 - 200)

        local tips = {
            "B - Display visualized tree",
            "V - Display vertial tree",
            "F - Increase simulation speed",
            "Shift-F - Decrease simulation speed",
        }

        for i,v in pairs(tips) do
            love.graphics.print(v, love.graphics.getWidth()/2 - Font:getWidth(v)/2, love.graphics.getHeight()/2 + 50 + (i-1)*64)
        end
    end
end

function createVerticalTree(root, indent, verticalTree) -- wizardNum is one or 2, same as index for CurrentlyActiveWizards
    if not indent then indent = "" end
    if not verticalTree then verticalTree = "" end

    verticalTree = verticalTree .. "\n".. indent .. root.name

    if root.children then
        for i,v in pairs(root.children) do
            verticalTree = createVerticalTree(v, indent .. "|  ", verticalTree)
        end
    end

    return verticalTree
end

wizardCoords = {}
function DrawBracket()
    local function drawWizardIcon(wizardID, centerx,centery)
        local colorScheme = ColorList[wizardID]
        love.graphics.setColor(unpack(colorScheme[3]))
        love.graphics.circle("fill", centerx,centery, 12)
        love.graphics.setColor(unpack(colorScheme[2]))
        DrawOval(centerx,centery-10, 28, 0.4)
        local hatwidth = 11
        local hatheight = 40
        love.graphics.setColor(unpack(colorScheme[1]))
        love.graphics.polygon("fill", centerx-hatwidth,centery-10, centerx+hatwidth,centery-10, centerx,centery-hatheight)
        DrawOval(centerx,centery-10, hatwidth, 0.4)
    end

    local function addWizardCoords(wizard, round, x, y)
        w = {}
        w.wizardID = wizard
        w.round = round
        w.x = x
        w.y = y
        exists = false

        for _,w in pairs(wizardCoords) do
            if w.wizardID == wizard and w.round == round and w.x == x and w.y == y then
                exists = true
            end
        end

        if exists == false then
            table.insert(wizardCoords, w)
        end
    end

    local function getWizardCoords(wizard, round)
        for _,w in pairs(wizardCoords) do
            if w.wizardID == wizard and w.round == round then
                return w.x, w.y
            end
        end

        return nil
    end

    love.graphics.setColor(0.25,0,0.5, 0.5)
    love.graphics.rectangle("fill", 0,0, love.graphics.getWidth(),love.graphics.getHeight())

    local darkLine = {0.1,0.1,0.1}
    local lightLine = {0.8,0.8,0.8}

    local xvalues = {}
    for r=1, ROUND_COUNT do
        local count = GetContestantsAtLayer(r)
        for i=1, count do
            local x = Conversion(0.1,0.9, 1,count, i)*love.graphics.getWidth()
            local y = Conversion(0.8,0.2, 1,ROUND_COUNT, r)*love.graphics.getHeight()

            if r == 1 then
                xvalues[i] = x
            else
                x = (xvalues[i*2] + xvalues[i*2 -1])/2
                xvalues[i] = x
                -- lastxvalues[i] = x
            end

            if Bracket[r][math.floor((i-1)/2) +1] then
                local wizard = Bracket[r][math.floor((i-1)/2) +1][(i-1)%2 +1]
                addWizardCoords(wizard, r, x, y)

                if r-1 >= 1 then
                    local lastMatch = Bracket[r - 1][i]

                    love.graphics.setColor(1,1,1)

                    x1, y1 = getWizardCoords(lastMatch[1], r - 1)
                    x2, y2 = getWizardCoords(lastMatch[2], r - 1)

                    if lastMatch[1] == wizard then --Check to see which wizard is the winner
                        love.graphics.setColor(unpack(darkLine))
                        love.graphics.line(x2, y2 - 45, x2, math.floor((y + y2)/2))
                        love.graphics.line(x - 2, math.floor((y + y2)/2), x2 + 2, math.floor((y + y2)/2))

                        love.graphics.setColor(unpack(lightLine))
                        love.graphics.line(x, y, x, math.floor((y + y1)/2))
                        love.graphics.line(x1, y1 - 45, x1, math.floor((y + y1)/2))
                        love.graphics.line(x + 2, math.floor((y + y1)/2), x1 - 2, math.floor((y + y1)/2))

                    elseif lastMatch[2] == wizard then
                        love.graphics.setColor(unpack(darkLine))
                        love.graphics.line(x1, y1 - 45, x1, math.floor((y + y1)/2))
                        love.graphics.line(x + 2, math.floor((y + y1)/2), x1 - 2, math.floor((y + y1)/2))

                        love.graphics.setColor(unpack(lightLine))
                        love.graphics.line(x, y, x, math.floor((y + y2)/2))
                        love.graphics.line(x2, y2 - 45, x2, math.floor((y + y2)/2))
                        love.graphics.line(x - 2, math.floor((y + y2)/2), x2 + 2, math.floor((y + y2)/2))
                    end
                end

                if wizard then
                    drawWizardIcon(wizard, x,y)
                end
            end
        end
    end

    --[[
    if TournamentOver then
        love.graphics.setColor(unpack(lightLine))
        tx = (xvalues[1] + xvalues[2]) / 2
        love.graphics.line(tx, 100, tx ,200)
    end
    ]]
end

function GetContestantsAtLayer(i)
    return CONTESTANT_COUNT/(2^(i-1))
end

function DrawOval(x,y, r, squish)
    love.graphics.push()
    love.graphics.translate(x,y)
    love.graphics.scale(1,squish)
    love.graphics.circle("fill", 0,0, r)
    love.graphics.pop()
end

function GenerateColorscheme()
    drips = {
        -- original
        {
            {63/255, 63/255, 76/255},
            {102/255, 102/255, 107/255},
        },

        -- pink
        {
            {215/255, 139/255, 156/255},
            {255/255, 179/255, 186/255},
        },

        -- blue
        {
            {49/255,73/255,124/255},
            {49/255,111/255,124/255},
        },

        -- purple
        {
            {54/255, 49/255, 124/255},
            {92/255, 49/255, 124/255},
        },

        -- orange
        {
            {124/255,54/255,49/255},
            {124/255,92/255,49/255},
        },

        -- green
        {
            {63/255, 80/255, 63/255},
            {95/255, 112/255, 95/255},
        },
    }

    return drips[love.math.random(1, 6)]
end

function CreateColorList()
    local list = {}

    for i=1, CONTESTANT_COUNT do
        list[i] = GenerateColorscheme()
        if not list[i][3] then list[i][3] = {} end
        list[i][3][1] = love.math.random()
        list[i][3][2] = love.math.random()
        list[i][3][3] = love.math.random()

        -- make the player always look the same
        if i == 1 then
            list[i] = PlayerColors
        end
    end

    return list
end

function GetMousePosition()
    return love.mouse.getX()*Camera.zoom + Camera.x, love.mouse.getY()*Camera.zoom + Camera.y
end

PlayerColors = {
    {63/255, 63/255, 76/255}, -- legs/top of hat (darker, more unsaturated version of cloak)
    {102/255, 102/255, 107/255}, -- cloak (unsaturated color)
    {1/4, 1/2, 1}, -- face, keep it a bright color (not skintone)
}

-- a bunch of useful math functions for common tasks
function Lerp(a,b,t) return (1-t)*a + t*b end
function DeltaLerp(a,b,t, dt) return Lerp(a,b, 1 - t^(dt)) end
function Conversion(a,b, p1,p2, t) return Lerp(a,b, Clamp((t-p1)/(p2-p1), 0,1)) end
function TableConversion(a,b, p1,p2, t) local ret = {} for i,v in pairs(a) do ret[i] = Conversion(a[i],b[i], p1,p2, t) end return ret end
function Clamp(n, min,max) return math.max(math.min(n, max),min) end
function Distance(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
function GetAngle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end
function RandomInt(min,max) return math.floor(love.math.random()*(max-min) +min +0.5) end
function Choose(t) return t[RandomInt(1,#t)] end
