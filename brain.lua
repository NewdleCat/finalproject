-- behavior tree
function NewBrain(owner)
    local self = {}
    self.owner = owner
    self.root = nil
    self.name = "root"

    self.query = function (self)
        return self.root:query(self.owner, self.owner.enemy)
    end

    return self
end

-- flow control nodes:
-- selector, sequence, invert
--
-- if statements:
-- line of sight to player
-- over half mana
-- is player in zap range
-- is player in fireball range
-- taking damage right now
--
-- action nodes:
-- look at player
-- run towards player using A*
-- run away from player, maybe doesn't need to use A*
-- fireball
-- sniper
-- zap

function NewSequenceNode(name)
    local self = {}
    self.children = {}
    self.name = name

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

function NewPointTowardsEnemyNode()
    local self = {}
    self.name = "pointTowardsEnemy"

    self.query = function (self, owner, enemy)
        owner.direction = GetAngle(owner.x,owner.y, enemy.x,enemy.y)
        return true
    end

    return self
end

function NewLineOfSightNode()
    local self = {}
    self.name = "lineOfSight"

    self.query = function (self, owner, enemy)
        local x,y = owner.x,owner.y
        local angle = GetAngle(owner.x,owner.y, enemy.x,enemy.y)

        while IsTileWalkable(WorldToTileCoords(x,y)) do
            x,y = x + math.cos(angle)*0.5, y + math.sin(angle)*0.5

            if Distance(x,y, enemy.x,enemy.y) < 30 then
                return true
            end
        end

        return false
    end

    return self
end

function NewIsTakingDamageRightNowNode()
    local self = {}
    self.name = "isTakingDamage"

    self.query = function (self, owner, enemy)
        return owner.hurtTimer > 0
    end

    return self
end

function NewWalkTowardsEnemyNode()
    local self = {}
    self.name = "walkTowardsEnemy"

    self.query = function (self, owner, enemy)
        local frontier = {}
        local checked = {}
        for i=0, 17 do
            checked[i] = {}
        end
        local ox,oy = WorldToTileCoords(owner.x, owner.y)
        local gx,gy = WorldToTileCoords(enemy.x, enemy.y)
        local nextNode = nil
        table.insert(frontier, {ox,oy, cost=Distance(ox,oy, gx,gy), parent=nil})

        -- greedy best first
        while true do
            -- pop off queue
            local this = table.remove(frontier, 1)

            -- if this is the goal, end loop
            if this[1] == gx and this[2] == gy then
                nextNode = this
                break
            end

            -- add neighbors
            if IsTileWalkable(this[1]-1, this[2]) and not checked[this[1]-1][this[2]] then
                checked[this[1]-1][this[2]] = true
                table.insert(frontier, {this[1]-1, this[2], cost=Distance(this[1]-1, this[2], gx,gy), parent=this})
            end
            if IsTileWalkable(this[1]+1, this[2]) and not checked[this[1]+1][this[2]] then
                checked[this[1]+1][this[2]] = true
                table.insert(frontier, {this[1]+1, this[2], cost=Distance(this[1]+1, this[2], gx,gy), parent=this})
            end
            if IsTileWalkable(this[1], this[2]-1) and not checked[this[1]][this[2]-1] then
                checked[this[1]][this[2]-1] = true
                table.insert(frontier, {this[1], this[2]-1, cost=Distance(this[1], this[2]-1, gx,gy), parent=this})
            end
            if IsTileWalkable(this[1], this[2]+1) and not checked[this[1]][this[2]+1] then
                checked[this[1]][this[2]+1] = true
                table.insert(frontier, {this[1], this[2]+1, cost=Distance(this[1], this[2]+1, gx,gy), parent=this})
            end

            -- sort queue by distance to goal
            table.sort(frontier, function (a,b)
                return a.cost < b.cost
            end)
        end

        -- go back until at 2nd node
        while nextNode.parent.parent do
            nextNode = nextNode.parent
        end

        -- get move to next node in the queue
        local angle = GetAngle(ox,oy, nextNode[1],nextNode[2])
        owner.moveVector[1] = math.cos(angle)
        owner.moveVector[2] = math.sin(angle)
        return true
    end

    return self
end

function NewWalkAwayFromEnemyNode()
    local self = {}
    self.name = "walkAwayFromEnemy"

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
    self.name = "snipeEnemy"

    self.query = function (self, owner, enemy)
        owner:sniperAttack()
        return true
    end

    return self
end
