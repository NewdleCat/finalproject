function NewSequenceNode(name)
    local self = {}
    self.children = {}
    self.name = name or "sequence"

    self.query = function (self, owner, enemy)
        -- go through children in order, querying them
        -- if any return false, then quit and return false
        for i,child in ipairs(self.children) do
            if not child:query(owner, enemy) then
                return false
            end
        end

        -- if it all goes smoothly, return true
        return true
    end

    return self
end

function NewSelectorNode(name)
    local self = {}
    self.children = {}
    self.name = name or "selector"

    self.query = function (self, owner, enemy)
        -- go through children in order, querying them
        -- if any return true, then quit and return true
        for i,child in ipairs(self.children) do
            if child:query(owner, enemy) then
                return true
            end
        end

        -- if nothing returned true, return false
        return false
    end

    return self
end

-- lol
function NewInterrogateChildrenNode()
    local self = {}
    self.children = {}
    self.name = "interrogate"

    self.query = function (self, owner, enemy)
        -- go through children in order, querying them
        -- if any return true, then quit and return true
        for i,child in ipairs(self.children) do
            child:query(owner, enemy)
        end

        -- if nothing returned true, return false
        return true
    end

    return self
end

function NewLineOfSightNode()
    local self = {}
    self.name = "check line of sight"

    self.query = function (self, owner, enemy)
        return CheckLineOfSight(owner.x,owner.y, enemy.x,enemy.y)
    end

    return self
end

function NewIsTakingDamageRightNowNode()
    local self = {}
    self.name = "is taking damage"

    self.query = function (self, owner, enemy)
        return owner.hurtTimer > 0
    end

    return self
end

function NewWalkTowardsEnemyNode()
    local self = {}
    self.name = "walk towards enemy"

    self.query = function (self, owner, enemy)
        local ox,oy = WorldToTileCoords(owner.x,owner.y)
        local gx,gy = WorldToTileCoords(enemy.x,enemy.y)
        local nx,ny = PathfindAndGiveDirections(ox,oy, gx,gy)
        local angle = GetAngle(owner.x,owner.y, nx,ny)
        owner.moveVector[1], owner.moveVector[2] = math.cos(angle), math.sin(angle)
        return true
    end

    return self
end

function NewStrafeNode()
    local self = {}
    self.name = "strafe around enemy"

    self.query = function (self, owner, enemy)
        owner.moveVector[1] = math.cos(owner.direction + math.pi/2)
        owner.moveVector[2] = math.sin(owner.direction + math.pi/2)
        return true
    end

    return self
end

function NewIsEnemySnipingNode()
    local self = {}
    self.name = "avoid snipe"

    self.query = function (self, owner, enemy)
        return enemy.snipeChargeupTimer > 0
    end

    return self
end

function NewIsEnemyApproachingNode()
    local self = {}
    self.name = "is enemy approaching"

    self.query = function (self, owner, enemy)
        return owner.enemyApproaching > 0
    end

    return self
end

function NewTakeCoverNode(showDebug)
    local self = {}
    self.name = "take cover"

    self.query = function (self, owner, enemy)
        local ox,oy = WorldToTileCoords(owner.x, owner.y)
        local gx,gy = WorldToTileCoords(enemy.x, enemy.y)

        -- check all tiles in the map and find ones that aren't visible to the enemy
        local goalCost = nil
        local sight = {}
        for i=0, 15 do
            sight[i] = {}
        end
        local pick = {}
        for y=0, 15 do
            for x=0, 15 do
                if not CheckLineOfSight(x*64 + 32,y*64 + 32, enemy.x,enemy.y) and GetTile(x,y) == FLOOR_TILE then
                    sight[x][y] = true

                    -- find the best tile that compromises between being close to you and far from the enemy
                    local thisCost = Distance(x,y, ox,oy) - Distance(x,y, gx,gy)

                    if not goalCost or thisCost < goalCost then
                        goalCost = thisCost
                        pick = {x,y}
                    end
                end
            end
        end

        if showDebug then
            print("")
            PrintMap(sight)
            print("go to " .. pick[1] .. ", " .. pick[2])
        end

        -- now that a goal has been found, pathfind towards it
        if #pick > 0 and (pick[1] ~= ox or pick[2] ~= oy) then
            local nx,ny = PathfindAndGiveDirections(ox,oy, pick[1],pick[2])
            local angle = GetAngle(owner.x,owner.y, nx,ny)
            owner.moveVector[1], owner.moveVector[2] = math.cos(angle), math.sin(angle)
            return true
        end

        return false
    end

    return self
end

--[[
--
-- take cover is better in every way, use that instead
--
function NewWalkAwayFromEnemyNode()
    local self = {}
    self.name = "walk away from enemy"

    self.query = function (self, owner, enemy)
        local angle = GetAngle(owner.x,owner.y, enemy.x,enemy.y)
        owner.moveVector[1] = math.cos(angle)*-1
        owner.moveVector[2] = math.sin(angle)*-1
        return true
    end

    return self
end
]]

function NewSnipeEnemyNode()
    local self = {}
    self.name = "cast snipe"

    self.query = function (self, owner, enemy)
        if owner.mana < 75 then
            return false
        end
        owner:sniperAttack()
        return true
    end

    return self
end

function NewZapEnemyNode()
    local self = {}
    self.name = "cast zap"

    self.query = function (self, owner, enemy)
        if owner.mana < 15 then
            return false
        end
        owner:zapAttack()
        return true
    end

    return self
end

function NewFireballEnemyNode()
    local self = {}
    self.name = "cast fireball"

    self.query = function (self, owner, enemy)
        if owner.mana < 35 then
            return false
        end
        owner:fireballAttack()
        return true
    end

    return self
end

function NewHealNode()
    local self = {}
    self.name = "cast heal"

    self.query = function (self, owner, enemy)
        if owner.mana < 50 then
            return false
        end
        owner:healSpell()
        return true
    end

    return self
end

function NewCheckOwnerManaNode(mana)
    local self = {}
    self.name = "is my mana greater than " .. mana

    self.query = function (self, owner, enemy)
        if owner.mana >= mana then
            return true
        else
            return false
        end
    end

    return self
end

function NewCheckEnemyManaNode(mana)
    local self = {}
    self.name = "is enemy mana greater than " .. mana

    self.query = function (self, owner, enemy)
        if enemy.mana >= mana then
            return true
        else
            return false
        end
    end

    return self
end

function NewCheckOwnerHealthNode(health)
    local self = {}
    self.health = health
    self.name = "is my health greater than " .. health

    self.query = function (self, owner, enemy)
        if owner.health >= self.health then
            return true
        else
            return false
        end
    end

    return self
end

function NewCheckEnemyHealthNode(health)
    local self = {}
    self.name = "is enemy health greater than " .. health
    self.health = health

    self.query = function (self, owner, enemy)
        if enemy.health >= self.health then
            return true
        else
            return false
        end
    end

    return self
end

function InverterNode(node)
    local self = {}
    self.name = "not (" .. node.name .. ")"
    self.child = node

    self.query = function (self, owner, enemy)
        return not self.child:query(owner, enemy)
    end

    return self
end

function AlwaysTrueNode(node)
    local self = {}
    self.name = "always true (" .. node.name .. ")"
    self.child = node

    self.query = function (self, owner, enemy)
        self.child:query(owner, enemy)
        return true
    end

    return self
end

function AlwaysFalseNode(node)
    local self = {}
    self.name = "always true (" .. node.name .. ")"
    self.child = node

    self.query = function (self, owner, enemy)
        self.child:query(owner, enemy)
        return false
    end

    return self
end

function NewWithinRangeNode(range)
    local self = {}
    self.name = "within " .. range .. " tiles"
    self.range = range*64

    self.query = function (self, owner, enemy)
        return Distance(owner.x, owner.y, enemy.x,enemy.y) <= self.range
    end

    return self
end
