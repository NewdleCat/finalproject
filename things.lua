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
    self.name = "wizard"
    self.living = true

    -- create my legs (just for looks)
    self.legs = {}
    self.legs[1] = NewWizardLeg(math.pi/-4, 7, self)
    self.legs[2] = NewWizardLeg(math.pi/4, 7, self)

    self.update = function (self, dt)
        -- leg code

        -- determine center of balance by averaging the positions of my two legs
        local centerOfBalance = {(self.legs[1].x + self.legs[2].x)/2, (self.legs[1].y + self.legs[2].y)/2}

        -- determine what my nearest and furthest legs are
        local nearestLeg = self.legs[2]
        local furthestLeg = self.legs[1]
        if Distance(self.legs[1].x, self.legs[1].y, self.x,self.y) < Distance(self.legs[2].x,self.legs[2].y, self.x,self.y) then
            nearestLeg = self.legs[1]
            furthestLeg = self.legs[2]
        end

        -- if i'm far away from my center of balance, update my furthest leg
        if Distance(self.x,self.y, centerOfBalance[1],centerOfBalance[2]) > 8 then
            -- move my furthest leg in the direction that i'm moving
            local angle = self.lastMoveDirection

            -- give it an angle offset depending on if it is my right or left leg
            if furthestLeg == self.legs[2] then
                angle = angle + math.pi/8
            else
                angle = angle - math.pi/8
            end

            -- set the leg to its new position
            local rad = 20
            furthestLeg.x,furthestLeg.y = self.x + math.cos(angle)*rad, self.y + math.sin(angle)*rad
        end

        -- save the radian angle of the last direction i moved for walking animation purposes
        self.lastMoveDirection = GetAngle(0,0, self.xSpeed,self.ySpeed)

        -- slowly regenerate mana, but don't go past 100
        self.mana = math.min(self.mana + 0.1, 100)

        -- die if out of health
        return self.health > 0
    end

    self.onDeath = function (self)
        love.audio.stop(Sounds.death)
        love.audio.play(Sounds.death)
    end

    self.drawArm = function (self)
        love.graphics.setColor(1,1,1)
        local internalradius = 30
        local radius = 64
        local perspective = 0.6
        local chestx, chesty = self.x, self.y - 14
        love.graphics.line(chestx + math.cos(self.direction)*internalradius,chesty + math.sin(self.direction)*internalradius*perspective, chestx + math.cos(self.direction)*radius, chesty + math.sin(self.direction)*radius*perspective)
    end

    self.draw = function (self)
        love.graphics.setLineWidth(5)
        local centerx, centery = self.x, self.y - 28

        -- draw legs
        love.graphics.setColor(0.25,0.25,0.3)
        for i,leg in pairs(self.legs) do
            leg:draw()
        end

        -- if my arm is behind me, draw it now so i can draw the cloak on top of it
        local drawnArm = false
        if math.sin(self.direction) < 0 then
            self:drawArm()
            drawnArm = true
        end

        -- draw cloak
        love.graphics.setColor(0.4,0.4,0.5)
        for i=1, 8 do
            DrawOval(centerx,centery+Conversion(30,12, 1,8, i), Conversion(18,12, 1,8, i), 0.4)
        end

        -- draw hat
        love.graphics.setColor(0.25,0.5,1)
        love.graphics.circle("fill", centerx,centery, 12)
        love.graphics.setColor(0.4,0.4,0.5)
        DrawOval(centerx,centery-10, 28, 0.4)
        local hatwidth = 11
        local hatheight = 40
        love.graphics.setColor(0.25,0.25,0.3)
        love.graphics.polygon("fill", centerx-hatwidth,centery-10, centerx+hatwidth,centery-10, centerx,centery-hatheight)
        DrawOval(centerx,centery-10, hatwidth, 0.4)

        if not drawnArm then
            -- i guess my arm wasn't behind me, draw it on top of evething else
            self:drawArm()
        end
    end

    self.drawGui = function (self)
        -- draw health bar
        local width = 120
        love.graphics.setColor(1,0,0.2)
        love.graphics.rectangle("fill", self.x -width/2, self.y - 100, width*(self.health/100), 10)
        love.graphics.setColor(0.1,0.1,0.1, 0.5)
        love.graphics.rectangle("fill", self.x -width/2 + width, self.y - 100, -1*width*(1 - self.health/100), 10)
        love.graphics.setColor(0.2,0,1)
        love.graphics.rectangle("fill", self.x -width/2, self.y - 100 + 16, width*(self.mana/100), 10)
        love.graphics.setColor(0.1,0.1,0.1, 0.5)
        love.graphics.rectangle("fill", self.x -width/2 + width, self.y - 100 + 16, -1*width*(1 - self.mana/100), 10)
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
    self.name = "wizardleg"

    self.draw = function (self)
        local ox,oy = self.owner.x + math.cos(self.owner.lastMoveDirection + angle)*radius, self.owner.y + math.sin(self.owner.lastMoveDirection + angle)*radius
        love.graphics.line(ox,oy, self.x, self.y+16)
    end

    return self
end

function NewPlayer(x,y)
    -- this acts as inheritence, inheriting the stuff that the base Wizard class has
    local self = NewWizard(x,y)
    self.name = "playerwizard"

    -- store the inherited update so that we can call it in our new update function
    self.parentUpdate = self.update
    self.update = function (self, dt)
        self:parentUpdate(dt)

        local walkSpeed = 0.8
        local moveVector = {0,0}

        -- walk according to keyboard input
        if love.keyboard.isDown("w") then
            moveVector[2] = -1
        end
        if love.keyboard.isDown("s") then
            moveVector[2] = 1
        end
        if love.keyboard.isDown("a") then
            moveVector[1] = -1
        end
        if love.keyboard.isDown("d") then
            moveVector[1] = 1
        end

        -- do some trigonometry here so that moving in diagonals doesn't make you go faster
        if moveVector[1] ~= 0 or moveVector[2] ~= 0 then
            local moveAngle = GetAngle(0,0, moveVector[1],moveVector[2])
            self.xSpeed = self.xSpeed + math.cos(moveAngle)*walkSpeed
            self.ySpeed = self.ySpeed + math.sin(moveAngle)*walkSpeed
        end

        -- apply some friction to be able to stop walking
        local friction = 0.8
        self.xSpeed = self.xSpeed * friction
        self.ySpeed = self.ySpeed * friction

        -- collide with walls and the edges of the arena
        if not IsTileWalkable(WorldToTileCoords(self.x + self.xSpeed, self.y)) then
            self.xSpeed = 0
        end
        if not IsTileWalkable(WorldToTileCoords(self.x, self.y + self.ySpeed)) then
            self.ySpeed = 0
        end
        if not IsTileWalkable(WorldToTileCoords(self.x + self.xSpeed, self.y + self.ySpeed)) then
            self.xSpeed = 0
            self.ySpeed = 0
        end

        -- integrate velocity into position
        self.x = self.x + self.xSpeed
        self.y = self.y + self.ySpeed

        -- always point towards the mouse
        local mousex,mousey = love.mouse.getX()*Camera.zoom + Camera.x, love.mouse.getY()*Camera.zoom + Camera.y
        self.direction = math.pi + math.atan2((self.y-14) - mousey, self.x - mousex)

        -- center the camera on me
        -- but bias it in the direction of the mouse
        Camera.x = (self.x*6 + mousex)/7 - (love.graphics.getWidth()/2)*Camera.zoom
        Camera.y = (self.y*6 + mousey)/7 - (love.graphics.getHeight()/2)*Camera.zoom

        -- only stay alive while i have health remaining
        return self.health > 0
    end

    self.mousepressed = function (self, x,y, button)
        if button == 1 and self.mana > 35 then
            self.mana = self.mana - 35
            AddToThingList(NewFireball(self.x,self.y+14, self.direction))
        end

        if button == 2 and self.mana > 15 then
            self.mana = self.mana - 15
            --AddToThingList(NewZap(self.x,self.y, self.direction, self))
            --AddToThingList(NewZap(self.x,self.y, self.direction + math.pi/10, self))
            --AddToThingList(NewZap(self.x,self.y, self.direction - math.pi/10, self))
            AddToThingList(NewHealAreaOfEffect(self.x, self.y))
        end
    end

    return self
end

function NewHealAreaOfEffect(x,y)
    local self = {}
    self.timer = 0
    self.x = x
    self.realy = y
    self.y = -10000 -- just so it doesnt layer on top of anything
    self.radius = 64

    -- love.audio.stop(Sounds.boom)
    -- love.audio.play(Sounds.boom)

    self.update = function (self, dt)
        -- die after 10 seconds
        self.timer = self.timer + dt

        -- damage anything in my radius
        for i,v in pairs(ThingList) do
            if v.living and Distance(v.x,v.y, self.x,self.realy) <= self.radius then
                if v.health < 100 then
                    v.health = v.health + 0.5
                end
            end
        end

        return self.timer < 10
    end

    self.draw = function (self)
        -- set a stencil so the circle can't bleed outside of the area of the arena
        love.graphics.setStencilTest("greater", 0)
        love.graphics.setColor(0.15,0.5,0, Conversion(0.5,0, 9,10, self.timer))
        love.graphics.circle("fill", self.x,self.realy, self.radius)
        love.graphics.setColor(0.2,0.8,0, Conversion(1,0, 9,10, self.timer))
        love.graphics.circle("line", self.x,self.realy, self.radius)
        love.graphics.setStencilTest()
    end

    return self
end

function NewFireball(x,y, direction)
    local self = {}
    self.x = x
    self.y = y
    self.height = -20
    self.direction = direction
    self.airSpeed = -3
    self.name = "fireball"

    love.audio.stop(Sounds.fireball)
    love.audio.play(Sounds.fireball)

    self.update = function (self, dt)
        self.airSpeed = self.airSpeed + dt*3

        local speed = 3
        self.height = self.height + self.airSpeed
        self.x = self.x + math.cos(self.direction)*speed
        self.y = self.y + math.sin(self.direction)*speed

        if self.height > 0 and IsInsideArena(self.x,self.y) then
            -- landed inside arena, explode
            AddToThingList(NewFireballAreaOfEffect(self.x,self.y))
            return false
        end
        if not IsInsideArena(self.x,self.y) then
            -- landed outside arena, don't explode
            return false
        end

        return true
    end

    self.draw = function (self)
        love.graphics.setColor(0.8,0.2,0)
        local radius = 16
        love.graphics.circle("fill", self.x,self.y + self.height - radius/2, radius)

        -- only draw shadow if inside arena
        if IsInsideArena(self.x,self.y) then
            love.graphics.setColor(0.2,0.2,0.2, 0.75)
            DrawOval(self.x,self.y, radius, 0.4)
        end
    end

    return self
end

function NewFireballAreaOfEffect(x,y)
    local self = {}
    self.timer = 0
    self.x = x
    self.realy = y
    self.y = -10000 -- just so it doesnt layer on top of anything
    self.radius = 128

    love.audio.stop(Sounds.boom)
    love.audio.play(Sounds.boom)

    self.update = function (self, dt)
        -- die after 10 seconds
        self.timer = self.timer + dt

        -- damage anything in my radius
        for i,v in pairs(ThingList) do
            if v.living and Distance(v.x,v.y, self.x,self.realy) <= self.radius then
                v.health = v.health - 0.5
            end
        end

        return self.timer < 10
    end

    self.draw = function (self)
        -- set a stencil so the circle can't bleed outside of the area of the arena
        love.graphics.setStencilTest("greater", 0)
        love.graphics.setColor(0.5,0.15,0, Conversion(0.5,0, 9,10, self.timer))
        love.graphics.circle("fill", self.x,self.realy, self.radius)
        love.graphics.setColor(0.8,0.2,0, Conversion(1,0, 9,10, self.timer))
        love.graphics.circle("line", self.x,self.realy, self.radius)
        love.graphics.setStencilTest()
    end

    return self
end

function NewZap(x,y, direction, owner)
    local self = {}
    self.x = x
    self.y = y
    self.trail = {}
    self.direction = direction
    self.timer = 0
    self.owner = owner

    love.audio.stop(Sounds.zap)
    love.audio.play(Sounds.zap)

    self.update = function (self, dt)
        self.timer = self.timer + dt

        local randomness = 16
        table.insert(self.trail, {self.x + love.math.random()*randomness - randomness/2, self.y + love.math.random()*randomness - randomness/2})

        local speed = 8
        self.x = self.x + math.cos(self.direction)*speed
        self.y = self.y + math.sin(self.direction)*speed

        -- damage anything in my radius
        for i,v in pairs(ThingList) do
            if v.living and Distance(v.x,v.y, self.x,self.y) <= 30 and v ~= self.owner then
                v.health = v.health - 20
                return false
            end
        end

        return self.timer < 0.75
    end

    self.draw = function (self)
        local pastWidth = love.graphics.getLineWidth()
        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(2)
        --love.graphics.circle("fill", self.x,self.y, 16)
        for i=math.max(1, #self.trail-10), #self.trail-1 do
            local this = self.trail[i]
            local next = self.trail[i+1]

            love.graphics.line(this[1], this[2], next[1], next[2])
        end
        love.graphics.setLineWidth(pastWidth)
    end

    return self
end

function NewWall(x,y)
    local self = {}
    self.x = x
    self.y = y+64 -- have y be my bottom left corner so i'm layered nicely with other objects

    self.update = function (self, dt)
        return true
    end

    self.draw = function (self)
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.rectangle("fill", self.x,self.y-128, 64,64)
        love.graphics.setColor(0.2,0.2,0.2)
        love.graphics.rectangle("line", self.x,self.y-128, 64,64)
        love.graphics.rectangle("fill", self.x,self.y-64, 64,64)
        love.graphics.setColor(0.1,0.1,0.1)
        love.graphics.rectangle("line", self.x,self.y-64, 64,64)
    end

    return self
end
