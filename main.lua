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
    -- we could deltatime every physical interaction in the game, but that might be more difficult here
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

-- a function that acts like a class
-- it returns an instance of its class when it's called
function NewWizard(x,y)
    local self = {}
    self.x = x
    self.y = y
    self.xSpeed = 0
    self.ySpeed = 0
    self.direction = 0
    self.health = 100
    self.mana = 100

    self.update = function (self, dt)
        return true
    end

    self.draw = function (self)
        love.graphics.setColor(0.25,0.5,1)
        love.graphics.circle("fill", self.x,self.y, 16,16)

        love.graphics.setColor(1,1,1)
        local radius = 24
        love.graphics.line(self.x,self.y, self.x + math.cos(self.direction)*radius, self.y + math.sin(self.direction)*radius)
    end

    return self
end

function NewPlayer(x,y)
    -- this acts as inheritence, inheriting the stuff that the base Wizard class has
    local self = NewWizard(x,y)

    self.update = function (self, dt)
        local walkSpeed = 0.8

        -- walk according to keyboard input
        if love.keyboard.isDown("w") then
            self.ySpeed = self.ySpeed - walkSpeed
        end
        if love.keyboard.isDown("s") then
            self.ySpeed = self.ySpeed + walkSpeed
        end
        if love.keyboard.isDown("a") then
            self.xSpeed = self.xSpeed - walkSpeed
        end
        if love.keyboard.isDown("d") then
            self.xSpeed = self.xSpeed + walkSpeed
        end

        -- apply some friction to be able to stop walking
        local friction = 0.8
        self.xSpeed = self.xSpeed * friction
        self.ySpeed = self.ySpeed * friction

        -- integrate velocity into position
        self.x = self.x + self.xSpeed
        self.y = self.y + self.ySpeed

        -- always point towards the mouse
        self.direction = math.pi + math.atan2(self.y - love.mouse.getY(), self.x - love.mouse.getX())

        return true
    end

    return self
end
