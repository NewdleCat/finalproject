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
    Subtrees = {}
    local function createSubtree(name, nodes)
        Subtrees[name] = NewSequenceNode()
        for i,v in ipairs(nodes) do
            table.insert(Subtrees[name].children, v)
        end
    end

    -- define some subtrees to generate behavior trees out of
    createSubtree("snipeOnSight", {
        NewLineOfSightNode(),
        NewSnipeEnemyNode(),
    })

    createSubtree("retreat", {
        InverterNode(NewCheckOwnerHealthNode(50)),
        NewTakeCoverNode(),
    })

    createSubtree("healInCover", {
        InverterNode(NewCheckOwnerHealthNode(50)),
        InverterNode(NewLineOfSightNode()),
        AlwaysTrueNode(NewHealNode()),
    })

    createSubtree("runAway", {
        NewTakeCoverNode(),
    })

    createSubtree("advance", {
        --NewCheckOwnerDistanceNode(2),
        NewWalkTowardsEnemyNode(),
    })

    createSubtree("runAwayFromDamage", {
        NewIsTakingDamageRightNowNode(),
        NewWalkAwayFromEnemyNode(),
    })

    local botTemplates = {
        sneakySniper = {
            Subtrees.runAwayFromDamage,
            Subtrees.healInCover,
            Subtrees.retreat,
            Subtrees.snipeOnSight,
            Subtrees.advance,
        },

        coward = {
            Subtrees.runAwayFromDamage,
            Subtrees.runAway,
        },
    }

    local list = {}
    for i=1, CONTESTANT_COUNT do
        if i == 1 and DevPlayerEnabled then
            -- the player is denoted as the wizard without a brain
            list[i] = nil
        else
            list[i] = NewBrain(nil)
            local brain = list[i]

            -- root node is always a selector
            -- selectors always stop and return when one of their children returns true
            brain.root = NewSelectorNode()

            -- choose a random template from the list of botTemplates
            local iteratableTemplates = {}
            for _,temp in pairs(botTemplates) do
                table.insert(iteratableTemplates, temp)
            end
            local template = Choose(iteratableTemplates)

            -- add all of the subtrees in the template in order to the behavior tree
            for _,subtree in ipairs(template) do
                table.insert(brain.root.children, subtree)
            end

            -- print the resulting behavior tree to the console so we can see what's happening
            print("")
            print("brain " .. i)
            print("")
            PrintBrainToConsole(brain.root)
        end
    end

    print("")

    return list
end

function PrintBrainToConsole(root, indent)
    if not indent then indent = "" end

    print(indent .. root.name)

    if root.children then
        for i,v in pairs(root.children) do
            PrintBrainToConsole(v, indent .. "|  ")
        end
    end
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

nodeCoords = {}
function DrawBT(rootNode)

    local function addCoords(name, layer, x, index)
        local node = {}
        node.name = name
        node.layer = layer -- layer 1 is the bottom most layer
        node.x = x
        node.index = index -- number it was added in, similar to braket[]
        exists = false

        for _,n in pairs(nodeCoords) do
            if n.name == name and n.layer == layer and n.x == x and n.index == index then
                exists = true
            end
        end

        if exists == false then
            table.insert(nodeCoords, node)
        end
    end

    local function getNode(layer, index)
        for _,n in pairs(nodeCoords) do
            if n.layer == layer and n.index == index then
                return n.name, n.x
            end
        end
    end

    local function updateVal(layer, index, newVal)
        for _,n in pairs(nodeCoords) do
            if n.layer == layer and n.index == index then
                n.x = newVal
            end
        end
    end

    local rootX, rootY = 1000, 1300
    love.graphics.setColor(1, 1, 1)

    count = 0
    for i, n in pairs(rootNode.children) do
        for j,k in pairs(n.children) do
            count = count + 1
        end
    end


    num = -math.floor(count/2)

    pxList = {}
    pnList = {}
    plistIndex = 1
    coordsIndex = 1

    for i, n in pairs(rootNode.children) do

        xList = {}
        nList = {}
        listIndex = 1

        for ci, cn in pairs(n.children) do

            xList[listIndex] = rootX + (500 * num) -- initial add to the list

            xOffset = 0

            if coordsIndex > 1 then
                nodeName, nodeX = getNode(1, coordsIndex - 1) -- Gets Previous node

                xOffset = (#nodeName * 20 ) + 200
                if xList[listIndex] + xOffset - nodeX > 500 then
                    xOffset = xOffset - 400

                elseif xList[listIndex] + xOffset - nodeX < 500 then
                    xOffset = xOffset + 300
                end

                if string.find(nodeName, "takeCover") then -- for some reason words love to get up close
                    xOffset = xOffset + 150                -- and personal with "takeCover"
                end

            end


            nList[listIndex] = cn.name
            xList[listIndex] = rootX + (400 * num) + xOffset -- update it with the offset
            addCoords(cn.name, 1, xList[listIndex], coordsIndex) -- addit to the nodeCoords table

            love.graphics.print(cn.name, xList[listIndex], rootY + 1000, 0, 3)


            listIndex = listIndex + 1
            num = num + 1
            coordsIndex = coordsIndex + 1
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
-- heal

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

function NewTakeCoverNode()
    local self = {}
    self.name = "takeCover"

    self.query = function (self, owner, enemy)
        local frontier = {}
        local checked = {}
        for i=0, 17 do
            checked[i] = {}
        end
        local ox,oy = WorldToTileCoords(owner.x, owner.y)
        local gx,gy = WorldToTileCoords(owner.x, owner.y)
        local goalCost = nil
        for y=0, 15 do
            local str = ""
            for x=0, 15 do
                local angle = GetAngle(x,y, math.floor(enemy.x/64),math.floor(enemy.y/64))
                local xx,yy = x,y
                local visible = false
                while IsTileWalkable(math.floor(xx),math.floor(yy)) do
                    xx,yy = xx + math.cos(angle)*0.2, yy + math.sin(angle)*0.2

                    if Distance(xx,yy, math.floor(enemy.x/64),math.floor(enemy.y/64)) < 1 then
                        visible = true
                        break
                    end
                end

                local closenessToMe = Distance(math.floor(owner.x/64), math.floor(owner.y/64), x,y)
                local farnessFromEnemy = Distance(math.floor(owner.x/64), math.floor(owner.y/64), math.floor(enemy.x/64),math.floor(enemy.y/64))
                local thisCost = closenessToMe - farnessFromEnemy
                if visible then
                    str = str .. "X"
                else
                    str = str .. " "
                end
                if not visible and IsTileWalkable(x,y) and (goalCost == nil or thisCost < goalCost) then
                    gx,gy = x,y
                    goalCost = thisCost
                end
            end
            --print(str)
        end
        --print(gx,gy)

        if Distance(ox,oy, gx,gy) <= 1 then
            return true
        end

        local nextNode = nil
        table.insert(frontier, {ox,oy, cost=Distance(ox,oy, gx,gy), parent=nil})

        -- greedy best first
        while true do
            -- pop off queue
            local this = table.remove(frontier, 1)

            if this == nil then
                return true
            end

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

        --print("{"..owner.moveVector[1]..", "..owner.moveVector[2].."}")
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
    self.name = "walkAway\nFromEnemy"

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
    self.health = health

    self.query = function (self, owner, enemy)
        if owner.health >= self.health then
            return true
        else
            return false
        end
    end

    return self
end

function NewCheckOwnerDistanceNode(dist)
    local self = {}
    self.name = "checkOwnerDistance"
    self.dist = dist*64

    self.query = function (self, owner, enemy)
        return Distance(owner.x,owner.y, enemy.x,enemy.y) > dist
    end

    return self
end

function NewCheckEnemyHealthNode(health)
    local self = {}
    self.name = "CheckEnemyHealth"
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
    self.name = "inverted " .. node.name
    self.child = node

    self.query = function (self, owner, enemy)
        return not self.child:query(owner, enemy)
    end

    return self
end

function AlwaysTrueNode(node)
    local self = {}
    self.name = "always true " .. node.name
    self.child = node

    self.query = function (self, owner, enemy)
        self.child:query(owner, enemy)
        return true
    end

    return self
end

function AlwaysFalseNode(node)
    local self = {}
    self.name = "always true " .. node.name
    self.child = node

    self.query = function (self, owner, enemy)
        self.child:query(owner, enemy)
        return false
    end

    return self
end

function NewWithinRangeNode(range)
    local self = {}
    self.name = "WithinRange"
    self.range = range

    self.query = function (self, owner, enemy)
        return Distance(x,y, enemy.x,enemy.y) < self.range
    end
end
