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

function CreateBrainList()
    local list = {}

    for i=1, CONTESTANT_COUNT do
        if i == 1 and DevPlayerEnabled then
            -- the player is denoted as the wizard without a brain
            list[i] = nil
        else
            list[i] = NewBrain(nil)
            local brain = list[i]
            local node = Choose {
                NewSelectorNode,
                NewSequenceNode,
                NewInterrogateChildrenNode,
            }
            brain.root = node()

            -- this will be how many modes this bot has
            local modeCount = RandomInt(1,4)

            for i=1, modeCount do
                local this = NewSequenceNode()
                brain.root.children[i] = this

                local childrenCount = RandomInt(2,3)

                for c=1, childrenCount do
                    local node = Choose {
                        NewWalkTowardsEnemyNode,
                        --NewWalkTowardsEnemyNodeAStar,
                        --NewWalkAwayFromEnemyNode,
                        NewSnipeEnemyNode,
                        NewZapEnemyNode,
                        NewFireballEnemyNode,
                        NewHealNode,
                    }

                    -- these test if conditions are met
                    if c == 1 then
                        local node = Choose {
                            NewIsTakingDamageRightNowNode,
                            NewLineOfSightNode,
                        }
                    end

                    this.children[c] = node()
                end
            end
        end
    end

    return list
end


--[[
--
-- sniper bot
--
local goAway = NewSequenceNode("goAway")
local goTowards = NewSequenceNode("goTowards")
local runAwayFromDamage = NewSequenceNode("runAwyFrmDmg")
goAway.children = {
    NewLineOfSightNode(),
    NewPointTowardsEnemyNode(),
    NewWalkAwayFromEnemyNode(),
    NewSnipeEnemyNode(),
}
goTowards.children = {
    NewPointTowardsEnemyNode(),
    NewWalkTowardsEnemyNode(),
}
runAwayFromDamage.children = {
    NewIsTakingDamageRightNowNode(),
    NewWalkAwayFromEnemyNode(),
}

brain.root.children = {
    runAwayFromDamage,
    goAway,
    goTowards,
}
]]

function DrawBT(rootNode)
    local rootX, rootY = 1000, 1300
    love.graphics.setColor(1, 1, 1)
    -- love.graphics.print(rootNode.name, rootX, rootY, 0, 3)

    count = 0
    for i, n in pairs(rootNode.children) do
        for j,k in pairs(n.children) do
            count = count + 1
        end
    end

    love.graphics.print(count, 100, 100 ,0, 3)

    -- numChildren = #rootNode.children
    OddEven = count % 2
    num = -math.floor(count/2)
    tmep = 1
    prevLen = 1
    lenDiff = 1

    pxList = {}
    pnList = {}
    plistIndex = 1

    for i, n in pairs(rootNode.children) do

        xList = {}
        nList = {}
        listIndex = 1

        for ci, cn in pairs(n.children) do
            if num < 0 then
                temp = -1
            else
                temp = 1
            end

            if prevLen ~= 1 and prevLen ~= #cn.name then
                lenDiff = math.abs(prevLen - #cn.name) + 1
            end

            love.graphics.print(cn.name, rootX + (400 * num) + (lenDiff) * 40 * temp, rootY + 1000, 0, 3)
            prevLen = #cn.name

            xList[listIndex] = rootX + (400 * num) + (lenDiff) * 40 * temp
            nList[listIndex] = cn.name

            listIndex = listIndex + 1
            num = num + 1
        end

        parentX = math.floor((xList[1] + xList[#xList]) / 2)
        love.graphics.print(n.name, parentX, rootY + 500, 0, 3)

        for x = 1, #xList do
            love.graphics.line(parentX + #n.name * 12, rootY + 550, xList[x] + #nList[x] * 12, rootY + 1000)
        end

        pxList[plistIndex] = parentX
        pnList[plistIndex] = n.name
        plistIndex = plistIndex + 1
    end

    rootXPrint = math.floor((pxList[1] + pxList[#pxList]) / 2)
    love.graphics.print(rootNode.name, rootXPrint, rootY, 0, 3)
    for x = 1, #pxList do
        love.graphics.line(rootXPrint + #rootNode.name * 10, rootY + 50, pxList[x] + #pnList[x] * 12, rootY + 500)
    end
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

-- You are now entering Joey's subtree nodes, tread carefully to avoid bug bites --

-- If you see an enemy, snipe them --
function NewSnipeOnSightNode()
    local self = NewSequenceNode()
    self.name = "SnipeOnSight"
    self.children[0] = NewLineOfSightNode()
    self.children[1] = NewSnipeEnemyNode()

-- If you see an enemy and can snipe to kill, snipe them --
function NewSnipeOnSightNode()
    local self = NewSequenceNode()
    self.name = "SnipeOnSight"
    self.children[0] = NewLineOfSightNode()
    self.children[1] = Inverter(NewCheckEnemyHealthNode(75))
    self.children[1] = NewSnipeEnemyNode()

-- If you're not in line of sight, heal --
function NewHealIfSafeNode()
    local self = NewSequenceNode()
    self.name = "HealIfSafe"
    self.children[0] = Inverter(NewLineOfSightNode())
    self.children[1] = Inverter(NewCheckOwnerHealthNode(50))
    self.children[2] = NewHealNode()

-- If you're super close, zap --
    local self = NewSequenceNode()
    self.name = "ZapIfClose"
    self.children[0] = NewWithinRangeNode(5)
    self.children[1] = NewZapEnemyNode()

-- You are now leaving Joey's code, safe travels --

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
    self.name = "pointTwrdsEn"

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
    self.name = "isTkingDmg"

    self.query = function (self, owner, enemy)
        return owner.hurtTimer > 0
    end

    return self
end

function NewWalkTowardsEnemyNode()
    local self = {}
    self.name = "wlkTwrdsEn"

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
        while nextNode and nextNode.parent and nextNode.parent.parent do
            nextNode = nextNode.parent
        end

        -- get move to next node in the queue
        if nextNode then
            local angle = GetAngle(ox,oy, nextNode[1],nextNode[2])
            owner.moveVector[1] = math.cos(angle)
            owner.moveVector[2] = math.sin(angle)
        end

        return true
    end

    return self
end

function NewWalkTowardsEnemyNodeAStar()
    local self = {}

    self.query = function (self, owner, enemy)
        local frontier = {}
        local checked = {}
        local costSoFar = {}

        for i=0, 17 do
            checked[i] = {}
            costSoFar[i] = {}
        end
        local ox,oy = WorldToTileCoords(owner.x, owner.y)
        local gx,gy = WorldToTileCoords(enemy.x, enemy.y)
        local nextNode = nil
        table.insert(frontier, {ox,oy, cost=Distance(ox,oy, gx,gy), parent=nil})
        costSoFar[ox][oy] = 0

        -- astar implementation
        while true do
            -- pop off queue
            local this = table.remove(frontier, 1)

            -- if this is the goal, end loop
            if this[1] == gx and this[2] == gy then
                nextNode = this
                break
            end

            -- add neighbors
            if IsTileWalkable(this[1]-1, this[2]) and (not checked[this[1]-1][this[2]] or (Distance(this[1]-1, this[2], gx,gy) + costSoFar[this[1]][this[2]]) < costSoFar[this[1]-1][this[2]])then
                checked[this[1]-1][this[2]] = true
                local newCost = Distance(this[1]-1, this[2], gx,gy) + costSoFar[this[1]][this[2]]
                costSoFar[this[1]-1][this[2]] = newCost
                table.insert(frontier, {this[1]-1, this[2], cost=newCost, parent=this})
            end
            if IsTileWalkable(this[1]+1, this[2]) and (not checked[this[1]+1][this[2]] or (Distance(this[1]+1, this[2], gx,gy) + costSoFar[this[1]][this[2]]) < costSoFar[this[1]+1][this[2]])then
                checked[this[1]+1][this[2]] = true
                local newCost = Distance(this[1]+1, this[2], gx,gy) + costSoFar[this[1]][this[2]]
                costSoFar[this[1]+1][this[2]] = newCost
                table.insert(frontier, {this[1]+1, this[2], cost=newCost, parent=this})
            end
            if IsTileWalkable(this[1], this[2]-1) and (not checked[this[1]][this[2]-1] or (Distance(this[1], this[2]-1, gx,gy) + costSoFar[this[1]][this[2]]) < costSoFar[this[1]][this[2]-1]) then
                checked[this[1]][this[2]-1] = true
                local newCost = Distance(this[1], this[2]-1, gx,gy) + costSoFar[this[1]][this[2]]
                costSoFar[this[1]][this[2]-1] = newCost
                table.insert(frontier, {this[1], this[2]-1, cost=newCost, parent=this})
            end
            if IsTileWalkable(this[1], this[2]+1) and (not checked[this[1]][this[2]+1] or (Distance(this[1], this[2]+1, gx,gy) + costSoFar[this[1]][this[2]]) < costSoFar[this[1]][this[2]+1]) then
                checked[this[1]][this[2]+1] = true
                local newCost = Distance(this[1], this[2]+1, gx,gy) + costSoFar[this[1]][this[2]]
                costSoFar[this[1]][this[2]+1] = newCost
                table.insert(frontier, {this[1], this[2]+1, cost=newCost, parent=this})
            end

            -- sort queue by distance to goal
            table.sort(frontier, function (a,b)
                return a.cost < b.cost
            end)
        end

        -- go back until at 2nd node
        while nextNode.parent do
            while nextNode.parent.parent do
                nextNode = nextNode.parent
            end
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
    self.name = "wlkAwyFrmEn"

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
    self.name = "snipe"

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
    self.name = "zap"

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
    self.name = "fireball"

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
    self.name = "heal"

    self.query = function (self, owner, enemy)
        if owner.mana < 50 then
            return false
        end
        owner:healSpell()
        return true
    end

    return self
end

-- function NewCheckOwnerManaNode(mana)
--     local self = {}
--     self.name = "CheckOwnerMana"

--     self.query = function (self, owner, enemy)
--         if owner.mana >= mana then
--             return true
--         else
--             return false
--         end
--     end

--     return self
-- end

-- function NewCheckEnemyManaNode(mana)
--     local self = {}
--     self.name = "CheckEnemyMana"

--     self.query = function (self, owner, enemy)
--         if enemy.mana >= mana then
--             return true
--         else
--             return false
--         end
--     end

--     return self
-- end

function NewCheckOwnerHealthNode(health)
    local self = {}
    self.name = "CheckOwnerHealth"

    self.query = function (self, owner, enemy)
        if owner.health >= health then
            return true
        else
            return false
        end
    end

    return self
end

function NewCheckEnemyHealthNode(health)
    local self = {}
    self.name = "CheckEnemyHealth"

    self.query = function (self, owner, enemy)
        if enemy.health >= health then
            return true
        else
            return false
        end
    end

    return self
end

function Inverter(node)
    local self = {}
    self.name = "inverter"
    
    if node then
        return false
    else
        return true
    end
end

function NewWithinRangeNode(range)
    local self = {}
    self.name = "WithinRange"

    self.query = function (self, owner, enemy)
        local x,y = owner.x,owner.y
        local angle = GetAngle(owner.x,owner.y, enemy.x,enemy.y)

        while IsTileWalkable(WorldToTileCoords(x,y)) do
            x,y = x + math.cos(angle)*0.5, y + math.sin(angle)*0.5

            if Distance(x,y, enemy.x,enemy.y) < range then
                return true
            end
        end

        return false
    end
end