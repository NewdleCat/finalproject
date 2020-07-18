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
    self.legs[1] = NewWizardLeg(math.pi/-4, 7, self)
    self.legs[2] = NewWizardLeg(math.pi/4, 7, self)

    self.update = function (self, dt)
        -- make my legs be attached to me
        local centerOfBalance = {(self.legs[1].x + self.legs[2].x)/2, (self.legs[1].y + self.legs[2].y)/2}
        local nearestLeg = self.legs[2]
        local furthestLeg = self.legs[1]
        if Distance(self.legs[1].x, self.legs[1].y, self.x,self.y) < Distance(self.legs[2].x,self.legs[2].y, self.x,self.y) then
            nearestLeg = self.legs[1]
            furthestLeg = self.legs[2]
        end

        if Distance(self.x,self.y, centerOfBalance[1],centerOfBalance[2]) > 8 then
            local angle = self.lastMoveDirection--GetAngle(nearestLeg.x,nearestLeg.y, self.x,self.y)
            if furthestLeg == self.legs[2] then
                angle = angle + math.pi/8
            else
                angle = angle - math.pi/8
            end
            local rad = 20
            furthestLeg.x,furthestLeg.y = self.x + math.cos(angle)*rad, self.y + math.sin(angle)*rad
        end

        self.lastMoveDirection = GetAngle(0,0, self.xSpeed,self.ySpeed)

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

function NewWizardLeg(angle, radius, owner)
    local self = {}
    self.angle = angle
    self.radius = radius
    self.owner = owner
    self.x = owner.x + math.cos(angle)*radius
    self.y = owner.y + math.sin(angle)*radius

    self.draw = function (self)
        love.graphics.setColor(1,1,1)
        local ox,oy = self.owner.x + math.cos(self.owner.lastMoveDirection + angle)*radius, self.owner.y + math.sin(self.owner.lastMoveDirection + angle)*radius
        love.graphics.line(ox,oy, self.x, self.y+24)
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
