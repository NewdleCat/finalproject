-- a function that acts like a class
-- it returns an instance of its class when it's called
function NewWizard(x,y, colorScheme)
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
    self.moveVector = {0,0}
    self.hurtTimer = 0
    self.healTimer = 0
    self.snipeChargeupTimer = 0
    self.snipeChargeupTimerMax = 1.25

    self.colorScheme = colorScheme

    -- create my legs (just for looks)
    self.legs = {}
    self.legs[1] = NewWizardLeg(math.pi/-4, 7, self)
    self.legs[2] = NewWizardLeg(math.pi/4, 7, self)

    self.stepSounds = {
        Sounds.step1,
        Sounds.step2,
        Sounds.step3,
        Sounds.step4,
    }

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

        if tile == HEAL_TILE and self.health < 100 then
            self.health = self.health + 0.2
        end

        -- check if i was damaged, play a hurt sound
        self.hurtTimer = math.max(self.hurtTimer - dt, 0)
        if self.health > 0 and self.lastHealth > self.health then
            if not Sounds.oof:isPlaying() then
                love.audio.play(Sounds.oof)
                self.hurtTimer = 1
            end
        end
        self.lastHealth = self.health

        -- walk
        -- do some trigonometry here so that moving in diagonals doesn't make you go faster
        local walkSpeed = 0.8
        if self.moveVector[1] ~= 0 or self.moveVector[2] ~= 0 then
            local moveAngle = GetAngle(0,0, self.moveVector[1],self.moveVector[2])
            self.xSpeed = self.xSpeed + math.cos(moveAngle)*walkSpeed
            self.ySpeed = self.ySpeed + math.sin(moveAngle)*walkSpeed
        end

        -- heal spell buff timer
        if self.healTimer > 0 then
            self.health = math.min(self.health + 0.2, 100)

            if love.math.random() < 0.2 then
                AddToThingList(NewHealParticle(self.x + love.math.random()*10 -5,self.y + love.math.random()*10 -5))
            end
        end
        self.healTimer = math.max(self.healTimer - dt, 0)

        -- charge up and release sniper shot
        local lastSnipeChargeupTimer = self.snipeChargeupTimer
        self.snipeChargeupTimer = math.max(self.snipeChargeupTimer - dt, 0)
        if lastSnipeChargeupTimer > 0 and self.snipeChargeupTimer <= 0 then
            AddToThingList(NewSniperShot(self.x + math.cos(self.direction)*64,self.y + math.sin(self.direction)*64, self.direction, self))
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

        -- die if out of health
        return self.health > 0 or MatchOver
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

        if self.snipeChargeupTimer > 0 then
            love.graphics.setColor(1,0,0.5)
            love.graphics.circle("line", chestx + math.cos(self.direction)*radius, chesty + math.sin(self.direction)*radius, Conversion(6,24, self.snipeChargeupTimerMax,0, self.snipeChargeupTimer))
        end
    end

    self.draw = function (self)
        love.graphics.setLineWidth(5)
        local centerx, centery = self.x, self.y - 28

        -- draw legs
        love.graphics.setColor(unpack(self.colorScheme[1]))
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
        love.graphics.setColor(unpack(self.colorScheme[2]))
        for i=1, 8 do
            DrawOval(centerx,centery+Conversion(30,12, 1,8, i), Conversion(18,12, 1,8, i), 0.4)
        end

        -- draw hat
        love.graphics.setColor(unpack(self.colorScheme[3]))
        love.graphics.circle("fill", centerx,centery, 12)
        love.graphics.setColor(unpack(self.colorScheme[2]))
        DrawOval(centerx,centery-10, 28, 0.4)
        local hatwidth = 11
        local hatheight = 40
        love.graphics.setColor(unpack(self.colorScheme[1]))
        love.graphics.polygon("fill", centerx-hatwidth,centery-10, centerx+hatwidth,centery-10, centerx,centery-hatheight)
        DrawOval(centerx,centery-10, hatwidth, 0.4)

        if not drawnArm then
            -- i guess my arm wasn't behind me, draw it on top of evething else
            self:drawArm()
        end
    end

    self.drawGui = function (self)
        -- don't draw the health bar if the match is over
        if MatchOver then return end

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

    self.fireballAttack = function (self)
        if self.mana >= 35 then
            self.mana = self.mana - 35
            AddToThingList(NewFireball(self.x,self.y+14, self.direction))
        end
    end

    self.zapAttack = function (self)
        if self.mana >= 15 then
            self.mana = self.mana - 15
            AddToThingList(NewZap(self.x,self.y, self.direction, 0, self))
            AddToThingList(NewZap(self.x,self.y, self.direction, math.pi/10, self))
            AddToThingList(NewZap(self.x,self.y, self.direction, -1*math.pi/10, self))
        end
    end

    self.sniperAttack = function (self)
        if self.mana >= 75 and self.snipeChargeupTimer <= 0 then
            self.mana = self.mana - 75
            self.snipeChargeupTimer = self.snipeChargeupTimerMax
        end
    end

    self.healSpell = function (self)
        if self.mana >= 50 and self.healTimer <= 0 then
            self.mana = self.mana - 50
            love.audio.stop(Sounds.heal)
            love.audio.play(Sounds.heal)
            self.healTimer = 4
        end
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

function NewBot(x,y, colorScheme)
    local self = NewWizard(x,y, colorScheme)
    self.brain = NewBrain(self)

    self.parentUpdate = self.update
    self.update = function (self, dt)
        -- default to not moving
        self.moveVector[1] = 0
        self.moveVector[2] = 0

        -- if the mouse is over me, visualize my brain
        local mx,my = GetMousePosition()
        if Distance(mx,my, self.x,self.y) < 64 then
            VisualizedTree = self.brain.root
        end

        -- if the enemy isn't dead, do my behavior
        if not self.enemy.dead then
            -- always face the enemy
            self.direction = GetAngle(self.x,self.y, self.enemy.x,self.enemy.y)

            -- query my behavior tree
            self.brain:query()
        end

        -- return if i should still be alive, and call the parent class update function
        return self:parentUpdate(dt)
    end

    return self
end

function NewPlayer(x,y, colorScheme)
    -- this acts as inheritence, inheriting the stuff that the base Wizard class has
    local self = NewWizard(x,y, colorScheme)
    self.name = "playerwizard"
    self.cameraTimer = 0

    -- store the inherited update so that we can call it in our new update function
    self.parentUpdate = self.update
    self.update = function (self, dt)
        -- walk according to keyboard input
        self.moveVector[1] = 0
        self.moveVector[2] = 0
        if love.keyboard.isDown("w") then
            self.moveVector[2] = self.moveVector[2] - 1
        end
        if love.keyboard.isDown("s") then
            self.moveVector[2] = self.moveVector[2] + 1
        end
        if love.keyboard.isDown("a") then
            self.moveVector[1] = self.moveVector[1] - 1
        end
        if love.keyboard.isDown("d") then
            self.moveVector[1] = self.moveVector[1] + 1
        end

        -- call the base wizard class's update function
        local stillAlive = self:parentUpdate(dt)

        -- always point towards the mouse
        local mousex, mousey = GetMousePosition()
        self.direction = math.pi + math.atan2((self.y-14) - mousey, self.x - mousex)

        -- center the camera on me
        -- but bias it in the direction of the mouse
        local cx,cy = (self.x*6 + mousex)/7 - (love.graphics.getWidth()/2)*Camera.zoom, (self.y*6 + mousey)/7 - (love.graphics.getHeight()/2)*Camera.zoom
        self.cameraTimer = self.cameraTimer + dt
        if self.cameraTimer < 1 then
            Camera.x = Lerp(Camera.x, cx, 0.2)
            Camera.y = Lerp(Camera.y, cy, 0.2)
        else
            Camera.x = cx
            Camera.y = cy
        end

        -- only stay alive while i have health remaining
        return stillAlive
    end

    self.keypressed = function (self, key)
        if key == "e" then
            self:sniperAttack()
        end

        if key == "q" then
            self:healSpell()
        end
    end

    self.mousepressed = function (self, x,y, button)
        if button == 1 then
            self:fireballAttack()
        end

        if button == 2 then
            self:zapAttack()
        end
    end

    return self
end
