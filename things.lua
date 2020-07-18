-- a function that acts like a class
-- it returns an instance of its class when it's called
function NewWizard(x,y)
    local self = {}
    self.x = x
    self.y = y
    self.xSpeed = 0
    self.ySpeed = 0
    self.direction = 0
    self.lastMoveDirection = 0
    self.health = 100
    self.mana = 100

    -- create my legs (just for looks)
    self.legs = {}
    self.legs[1] = NewWizardLeg(-7, self)
    self.legs[2] = NewWizardLeg(7, self)
    self.nextLeg = 2

    self.update = function (self, dt)
        -- make my legs be attached to me
        for i,leg in pairs(self.legs) do
            leg:tryToMove(dt)
        end

        self.legs[1].checkPoint[1], self.legs[1].checkPoint[2] = self.x, self.y
        local lookAhead = 8
        self.legs[2].checkPoint[1], self.legs[2].checkPoint[2] = self.x + math.cos(self.lastMoveDirection)*lookAhead, self.y + math.sin(self.lastMoveDirection)*lookAhead

        if self.xSpeed ~= 0 or self.ySpeed ~= 0 then
            self.lastMoveDirection = GetAngle(0,0, self.xSpeed,self.ySpeed)
        end

        return true
    end

    self.draw = function (self)
        local centerx, centery = self.x, self.y - 20

        for i,leg in pairs(self.legs) do
            leg:draw()
        end

        -- draw cloak
        love.graphics.setColor(0.5,0.5,0.5)
        for i=1, 8 do
            DrawOval(centerx,centery+Conversion(30,12, 1,8, i), Conversion(18,12, 1,8, i), 0.4)
        end

        -- draw hat
        love.graphics.setColor(0.25,0.5,1)
        love.graphics.circle("fill", centerx,centery, 12)
        love.graphics.setColor(0.5,0.5,0.5)
        DrawOval(centerx,centery-10, 28, 0.4)
        local hatwidth = 11
        local hatheight = 40
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.polygon("fill", centerx-hatwidth,centery-10, centerx+hatwidth,centery-10, centerx,centery-hatheight)
        DrawOval(centerx,centery-10, hatwidth, 0.4)

        -- draw line that represents pointing direction
        love.graphics.setColor(1,1,1)
        local internalradius = 40
        local radius = 64
        love.graphics.line(centerx + math.cos(self.direction)*internalradius,centery + math.sin(self.direction)*internalradius, centerx + math.cos(self.direction)*radius, centery + math.sin(self.direction)*radius)
    end

    return self
end

function NewWizardLeg(offset, owner)
    local self = {}
    self.offset = offset
    self.owner = owner
    self.checkPoint = {owner.x, owner.y}
    self.groundPoint = {owner.x, owner.y}

    self.tryToMove = function (self, dt)
        if Distance(self.groundPoint[1],self.groundPoint[2], self.checkPoint[1],self.checkPoint[2]) > 16 then
            self:step()
            return true
        end

        return false
    end

    self.step = function (self)
        local stepLength = 16
        self.groundPoint[1], self.groundPoint[2] = self.owner.x + math.cos(self.owner.lastMoveDirection)*stepLength, self.owner.y + math.sin(self.owner.lastMoveDirection)*stepLength
    end

    self.draw = function (self)
        love.graphics.setColor(1,1,1)
        love.graphics.line(self.owner.x + self.offset,self.owner.y, self.groundPoint[1] + self.offset, self.groundPoint[2]+30)
    end

    return self
end

function NewPlayer(x,y)
    -- this acts as inheritence, inheriting the stuff that the base Wizard class has
    local self = NewWizard(x,y)

    -- store the inherited update so that we can call it in our new update function
    self.parentUpdate = self.update
    self.update = function (self, dt)
        self:parentUpdate(dt)

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
