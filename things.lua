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
