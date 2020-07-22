function NewSequenceNode(name)
    local self = {}
    self.children = {}
    self.name = name .. " sequence" or "sequence"

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

function NewSelectorNode()
    local self = {}
    self.children = {}
    self.name = "selector"

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
        local ox,oy = WorldToTileCoords(owner.x,owner.y)
        local gx,gy = WorldToTileCoords(enemy.x,enemy.y)
        return CheckLineOfSight(ox,oy, gx,gy)
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
        owner.moveVector[1], owner.moveVector[2] = PathfindAndGiveDirections(ox,oy, gx,gy)
        return true
    end

    return self
end

function NewTakeCoverNode()
    local self = {}
    self.name = "take cover"

    self.query = function (self, owner, enemy)
        local ox,oy = WorldToTileCoords(owner.x, owner.y)
        local gx,gy = WorldToTileCoords(enemy.x, enemy.y)

        -- check all tiles in the map and find ones that aren't visible to the enemy
        local goalCost = nil
        local pick = {}
        for y=0, 15 do
            for x=0, 15 do
                if not CheckLineOfSight(x,y, gx,gy) and IsTileWalkable(x,y) then
                    local thisCost = Distance(x,y, ox,oy) - Distance(x,y, gx,gy)
                    if not goalCost or thisCost < goalCost then
                        goalCost = thisCost
                        pick = {x,y}
                    end
                end
            end
        end

        if Distance(pick[1],pick[2], ox,oy) > 1 and #pick > 0 then
            --print("---------------------------------------")
            print("going to {" .. pick[1] .. ", " .. pick[2] .. "}")
            --local check = {}
            --for i=0, 17 do
                --check[i] = {}
            --end
            --check[pick[1]][pick[2]] = true
            --PrintMap(check)
            --print("---------------------------------------")
            owner.moveVector[1], owner.moveVector[2] = PathfindAndGiveDirections(ox,oy, pick[1],pick[2])
        end
        return true
    end

    return self
end

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
