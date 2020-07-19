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
            love.audio.stop(Sounds.boom)
            love.audio.play(Sounds.boom)

            local tx,ty = WorldToTileCoords(self.x,self.y)
            for x=-1, 1 do
                for y=-1, 1 do
                    if IsTileWalkable(x+tx, y+ty) then
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

function NewZap(x,y, direction, owner)
    local self = {}
    self.x = x
    self.y = y
    self.trail = {}
    self.direction = direction
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
        end
        self.trailIndex = self.trailIndex + 1

        local speed = 8
        self.x = self.x + math.cos(self.direction)*speed
        self.y = self.y + math.sin(self.direction)*speed

        if not IsTileWalkable(WorldToTileCoords(self.x,self.y)) then
            self.dieing = true
        end

        -- damage anything in my radius
        if not self.dieing then
            for i,v in pairs(ThingList) do
                if v.living and Distance(v.x,v.y, self.x,self.y) <= 30 and v ~= self.owner then
                    v.health = v.health - 20
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
        --love.graphics.circle("fill", self.x,self.y, 16)
        for i=math.max(1, self.trailIndex), #self.trail-1 do
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

    self.update = function (self, dt)
        self.timer = self.timer + dt

        if self.timer > 10 then
            SetTile(self.x,self.y, FLOOR_TILE)
            return false
        end

        return true
    end

    self.draw = function (self)
        love.graphics.setColor(0.8,0.2,0, Conversion(1,0, 9,10, self.timer))
        love.graphics.rectangle("fill", self.x*64,self.y*64, 64,64)
    end

    return self
end
