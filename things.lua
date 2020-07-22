function NewFireball(x,y, direction)
    local self = {}
    self.x = x
    self.y = y
    self.height = -20
    self.direction = direction
    self.airSpeed = -3
    self.name = "fireball"

    self.startX, self.startY = WorldToTileCoords(x,y)

    love.audio.stop(Sounds.fireball)
    love.audio.play(Sounds.fireball)

    self.update = function (self, dt)
        self.airSpeed = self.airSpeed + dt*3

        local speed = 3
        self.height = self.height + self.airSpeed
        self.x = self.x + math.cos(self.direction)*speed
        self.y = self.y + math.sin(self.direction)*speed

        local tx,ty = WorldToTileCoords(self.x,self.y)
        if IsTileWalkable(tx,ty) and GetTile(tx,ty) ~= FIRE_TILE and (tx ~= self.startX or ty ~= self.startY) then
            SetTile(tx,ty, FIRE_TILE)
        end

        if self.height > 0 and IsInsideArena(self.x,self.y) then
            -- landed inside arena, explode
            love.audio.stop(Sounds.boom)
            love.audio.play(Sounds.boom)

            local tx,ty = WorldToTileCoords(self.x,self.y)
            for x=-1, 1 do
                for y=-1, 1 do
                    if IsTileWalkable(x+tx, y+ty) and GetTile(x+tx,y+ty) ~= FIRE_TILE then
                        SetTile(x+tx, y+ty, FIRE_TILE)
                    end
                end
            end
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

function NewZap(x,y, direction, offset, owner)
    local self = {}
    self.x = x + math.cos(direction)*48
    self.y = y + math.sin(direction)*48
    self.trail = {}
    self.direction = direction + offset
    self.timer = 0
    self.owner = owner
    self.dieing = false
    self.trailIndex = -10

    love.audio.stop(Sounds.zap)
    love.audio.play(Sounds.zap)

    self.update = function (self, dt)
        self.timer = self.timer + dt

        local randomness = 16
        if not self.dieing then
            table.insert(self.trail, {self.x + love.math.random()*randomness - randomness/2, self.y + love.math.random()*randomness - randomness/2})

            local speed = 8
            self.x = self.x + math.cos(self.direction)*speed
            self.y = self.y + math.sin(self.direction)*speed
        end
        self.trailIndex = self.trailIndex + 1

        if not IsTileWalkable(WorldToTileCoords(self.x,self.y)) then
            self.dieing = true
        end

        -- damage anything in my radius
        if not self.dieing then
            for i,v in pairs(ThingList) do
                if v.living and Distance(v.x,v.y, self.x,self.y) <= 30 and v ~= self.owner then
                    v.health = v.health - 5
                    return false
                end
            end
        end

        if self.timer > 0.75 then
            self.dieing = true
        end

        return self.trailIndex < #self.trail
    end

    self.draw = function (self)
        local pastWidth = love.graphics.getLineWidth()
        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(2)
        local height = 14
        for i=math.max(1, self.trailIndex), #self.trail-1 do
            local this = self.trail[i]
            local next = self.trail[i+1]

            love.graphics.line(this[1], this[2] - height, next[1], next[2] - height)
        end
        love.graphics.setLineWidth(pastWidth)
    end

    return self
end

function NewWall(x,y)
    local self = {}
    self.x = x*64
    self.y = y*64 +64 -- have y be my bottom left corner so i'm layered nicely with other objects

    self.update = function (self, dt)
        return true
    end

    self.draw = function (self)
        love.graphics.setColor(0.4,0.4,0.4)
        love.graphics.rectangle("fill", self.x,self.y-128, 64,64)
        love.graphics.setColor(0.3,0.3,0.3)
        love.graphics.rectangle("line", self.x,self.y-128, 64,64)

        love.graphics.rectangle("fill", self.x,self.y-64, 64,32)
        love.graphics.rectangle("fill", self.x,self.y-32, 64,32)
        love.graphics.setColor(0.2,0.2,0.2)
        love.graphics.rectangle("line", self.x,self.y-64, 64,32)
        love.graphics.rectangle("line", self.x,self.y-32, 64,32)
    end

    return self
end

function NewFireTileVisual(x,y)
    local self = {}
    self.x = x
    self.y = y
    self.timer = 0
    self.points = {}

    -- add three circles in random places
    for i=1, 3 do
        table.insert(self.points, {love.math.random()*48 + 8, love.math.random()*48 + 8, radius = love.math.random()*16 + 8, color = love.math.random()*0.8 + 0.1})
    end

    self.update = function (self, dt)
        self.timer = self.timer + dt

        -- after 10 seconds despawn
        if self.timer > 10 then
            SetTile(self.x,self.y, FLOOR_TILE)
            return false
        end

        -- randomly create ember particles
        if love.math.random() < 0.05 then
            AddToThingList(NewEmberParticle(self.x*64 + love.math.random()*64,self.y*64 + love.math.random()*64))
        end

        return true
    end

    self.draw = function (self)
        love.graphics.setStencilTest("greater", 0)
        -- draw my three red circles
        for i,point in pairs(self.points) do
            love.graphics.setColor(0.8*point.color,0.05*point.color,0, Conversion(1,0, 9,10, self.timer))
            love.graphics.circle("fill", self.x*64 + point[1],self.y*64 + point[2], point.radius)
        end
        love.graphics.setStencilTest()
    end

    return self
end

function NewEmberParticle(x,y)
    local self = {}
    self.x = x
    self.y = y
    self.timer = 0
    self.timerMax = Conversion(0.5,1.25, 0,1, love.math.random())
    self.color = Conversion(0.5,1, 0,1, love.math.random())

    self.update = function (self, dt)
        self.timer = self.timer + dt
        self.y = self.y - 1
        self.x = self.x + math.sin(self.timer*3)*2

        return self.timer < self.timerMax
    end

    self.draw = function (self)
        love.graphics.setColor(0.8*self.color,0.05*self.color,0, Conversion(1,0, self.timerMax-0.15,self.timerMax, self.timer))
        love.graphics.circle("fill", self.x,self.y, 10,4)
    end

    return self
end

function NewSniperShot(x,y, direction, owner)
    local self = {}
    self.x = x
    self.y = y
    self.startx = self.x
    self.starty = self.y
    self.direction = direction
    self.timer = 0
    self.owner = owner

    love.audio.stop(Sounds.sniper)
    love.audio.play(Sounds.sniper)

    local hasHit = {}
    while IsTileWalkable(WorldToTileCoords(self.x,self.y)) do
        self.x = self.x + math.cos(direction)*0.1
        self.y = self.y + math.sin(direction)*0.1

        for i,v in pairs(ThingList) do
            if not hasHit[v] and v.living and Distance(v.x,v.y, self.x,self.y) <= 30 and v ~= self.owner then
                v.health = v.health - 75
                hasHit[v] = true
            end
        end
    end

    self.update = function (self, dt)
        self.timer = self.timer + dt
        return self.timer < 0.75
    end

    self.draw = function (self)
        love.graphics.setColor(1,0,0.5, Conversion(1,0, 0,0.75,self.timer))
        love.graphics.line(self.x,self.y -14, self.startx,self.starty -14)
    end

    return self
end

function NewHealTileVisual(x,y)
    local self = {}
    self.x = x
    self.y = y
    self.timer = 0
    self.points = {}

    love.audio.stop(Sounds.heal)
    love.audio.play(Sounds.heal)

    self.update = function (self, dt)
        self.timer = self.timer + dt

        -- after 10 seconds despawn
        if self.timer > 10 then
            SetTile(self.x,self.y, FLOOR_TILE)
            return false
        end

        -- randomly create ember particles
        if love.math.random() < 0.05 then
            AddToThingList(NewHealParticle(self.x*64 + love.math.random()*64,self.y*64 + love.math.random()*64))
        end

        return true
    end

    self.draw = function (self)
        love.graphics.setStencilTest("greater", 0)
        -- draw my three red circles
        for i=1, 3 do
            local rad = (i*13 + self.timer*10)%40
            love.graphics.setColor(0.2,0.5,0, Conversion(1,0, 25,35, rad)*Conversion(1,0, 9,10, self.timer))
            love.graphics.circle("line", self.x*64 + 32,self.y*64 + 32, rad)
        end
        love.graphics.setStencilTest()
    end

    return self
end

function NewHealParticle(x,y)
    local self = {}
    self.x = x
    self.y = y
    self.timer = 0
    self.timerMax = Conversion(0.5,1.25, 0,1, love.math.random())
    self.color = Conversion(0.5,1, 0,1, love.math.random())

    self.update = function (self, dt)
        self.timer = self.timer + dt
        self.y = self.y - 2
        self.x = self.x + math.sin(self.timer*3)*2

        return self.timer < self.timerMax
    end

    self.draw = function (self)
        love.graphics.setColor(0.2*self.color,0.8*self.color,0, Conversion(1,0, self.timerMax-0.15,self.timerMax, self.timer))
        love.graphics.circle("line", self.x,self.y, 10,8)
    end

    return self
end
