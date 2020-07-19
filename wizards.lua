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
    self.lastHealth = 100
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

        local tile = GetTile(WorldToTileCoords(self.x,self.y))

        if tile == FIRE_TILE then
            self.health = self.health - 0.5
        end

        -- check if i was damaged, play a hurt sound
        if self.health > 0 and self.lastHealth > self.health then
            if not Sounds.oof:isPlaying() then
                love.audio.play(Sounds.oof)
            end
        end
        self.lastHealth = self.health

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
            AddToThingList(NewZap(self.x,self.y, self.direction, 0, self))
            AddToThingList(NewZap(self.x,self.y, self.direction, math.pi/10, self))
            AddToThingList(NewZap(self.x,self.y, self.direction, -1*math.pi/10, self))
            --AddToThingList(NewHealAreaOfEffect(self.x, self.y))
        end
    end

    return self
end
