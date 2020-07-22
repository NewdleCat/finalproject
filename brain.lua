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
        Subtrees[name] = NewSequenceNode(name)
        for i,v in ipairs(nodes) do
            table.insert(Subtrees[name].children, v)
        end
    end

    -- define some subtrees to generate behavior trees out of

    -- Only pick one snipe
    createSubtree("snipeOnSight", {
        NewLineOfSightNode(),
        NewSnipeEnemyNode(),
    })

    createSubtree("snipeToKill", {
        NewLineOfSightNode(),
        InverterNode(NewCheckEnemyHealthNode(75)),
        NewSnipeEnemyNode(),
    })

    createSubtree("snipeOnScratch", {
        NewLineOfSightNode(),
        InverterNode(NewCheckOwnerHealthNode(75)),
        NewSnipeEnemyNode(),
    })

    createSubtree("snipeOnWound", {
        NewLineOfSightNode(),
        InverterNode(NewCheckOwnerHealthNode(50)),
        NewSnipeEnemyNode(),
    })

    createSubtree("snipeOnGash", {
        NewLineOfSightNode(),
        InverterNode(NewCheckOwnerHealthNode(25)),
        NewSnipeEnemyNode(),
    })
    -- end of sniper trees

    -- Only pick one zap
    createSubtree("zapInRange", {
        NewLineOfSightNode(),
        NewWithinRangeNode(5),
        NewZapEnemyNode(),
    })

    createSubtree("zapToKill", {
        NewLineOfSightNode(),
        NewWithinRangeNode(5),
        InverterNode(NewCheckEnemyHealthNode(20)),
        NewZapEnemyNode(),
    })

    createSubtree("zapWithMana", {
        NewLineOfSightNode(),
        NewWithinRangeNode(5),
        NewCheckOwnerManaNode(75),
        NewZapEnemyNode(),
    })

    createSubtree("zapOnScratch", {
        NewLineOfSightNode(),
        NewWithinRangeNode(5),
        InverterNode(NewCheckOwnerHealthNode(75)),
        NewZapEnemyNode(),
    })

    createSubtree("zapOnWound", {
        NewLineOfSightNode(),
        NewWithinRangeNode(5),
        InverterNode(NewCheckOwnerHealthNode(50)),
        NewZapEnemyNode(),
    })

    createSubtree("zapOnGash", {
        NewLineOfSightNode(),
        NewWithinRangeNode(5),
        InverterNode(NewCheckOwnerHealthNode(25)),
        NewZapEnemyNode(),
    })
    -- end of zap trees

    -- Only pick one fireball
    createSubtree("fireballInRange", {
        NewWithinRangeNode(7),
        InverterNode(NewWithinRangeNode(4)),
        NewFireballEnemyNode(),
    })

    createSubtree("fireballOnScratch", {
        NewWithinRangeNode(7),
        InverterNode(NewWithinRangeNode(4)),
        InverterNode(NewCheckOwnerHealthNode(75)),
        NewFireballEnemyNode(),
    })

    createSubtree("fireballOnWound", {
        NewWithinRangeNode(7),
        InverterNode(NewWithinRangeNode(4)),
        InverterNode(NewCheckOwnerHealthNode(50)),
        NewFireballEnemyNode(),
    })

    createSubtree("fireballOnGash", {
        NewWithinRangeNode(7),
        InverterNode(NewWithinRangeNode(4)),
        InverterNode(NewCheckOwnerHealthNode(25)),
        NewFireballEnemyNode(),
    })

    -- Only pick one retreat
    createSubtree("strongRetreat", {
        InverterNode(NewCheckOwnerHealthNode(75)),
        NewTakeCoverNode(),
    })

    createSubtree("69Retreat", {
        InverterNode(NewCheckOwnerHealthNode(69)),
        NewTakeCoverNode(),
    })

    createSubtree("retreat", {
        InverterNode(NewCheckOwnerHealthNode(50)),
        NewTakeCoverNode(),
    })

    createSubtree("weakRetreat", {
        InverterNode(NewCheckOwnerHealthNode(25)),
        NewTakeCoverNode(),
    })
    -- end of retreat trees

    -- Only pick one heal
    createSubtree("weakHealInCover", {
        InverterNode(NewCheckOwnerHealthNode(25)),
        InverterNode(NewLineOfSightNode()),
        AlwaysTrueNode(NewHealNode()),
    })

    createSubtree("healInCover", {
        InverterNode(NewCheckOwnerHealthNode(50)),
        InverterNode(NewLineOfSightNode()),
        AlwaysTrueNode(NewHealNode()),
    })

    createSubtree("weakHealInPlace", {
        InverterNode(NewCheckOwnerHealthNode(25)),
        AlwaysTrueNode(NewHealNode()),
    })

    createSubtree("healInPlace", {
        InverterNode(NewCheckOwnerHealthNode(50)),
        AlwaysTrueNode(NewHealNode()),
    })
    -- end of heal trees

    -- Only pick one default movement
    createSubtree("runAway", {
        NewTakeCoverNode(),
    })

    createSubtree("advance", {
        NewWalkTowardsEnemyNode(),
    })
    -- end of default movement trees

    -- extra movement conditions
    createSubtree("runAwayWhenClose", {
        NewWithinRangeNode(6),
        NewTakeCoverNode(),
    })

    createSubtree("advanceWhenFar", {
        InverterNode(NewWithinRangeNode(7)),
        NewWalkTowardsEnemyNode(),
    })

    createSubtree("peekAroundCorner", {
        InverterNode(NewLineOfSightNode()),
        NewWalkTowardsEnemyNode(),
    })

    createSubtree("runAwayFromDamage", {
        NewIsTakingDamageRightNowNode(),
        NewWalkAwayFromEnemyNode(),
    })

    local botTemplates = {
        test = {
            Subtrees.peekAroundCorner,
            Subtrees.runAway,
        },

        test2 = {
            Subtrees.advance,
        },
    }

    --[[
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

        zapAndSnipe = {
            Subtrees.runAwayFromDamage,
            Subtrees.zapWithMana,
            Subtrees.snipeToKill,
            Subtrees.advance,
            Subtrees.weakHealInCover,
            Subtrees.weakRetreat,
        },

        fireMage = {
            Subtrees.runAwayFromDamage,
            Subtrees.fireballInRange,
            Subtrees.healInPlace,
            Subtrees.zapInRange,
            Subtrees.advanceWhenFar,
            Subtrees.runAwayWhenClose,
            Subtrees.retreat,
        },
    }
    ]]

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

    local rootX, rootY = 1500, 1300
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
                elseif string.find(nodeName, "walky away from enemy") then
                    xOffset = xOffset + 200
                end

            end


            nList[listIndex] = cn.name
            xList[listIndex] = rootX + (400 * num) + xOffset -- update it with the offset
            addCoords(cn.name, 1, xList[listIndex], coordsIndex) -- addit to the nodeCoords table

            love.graphics.print(cn.name, xList[listIndex], rootY + 1000, 0, 1.1)


            listIndex = listIndex + 1
            num = num + 1
            coordsIndex = coordsIndex + 1
        end

        parentX = math.floor((xList[1] + xList[#xList]) / 2)
        love.graphics.print(n.name, parentX, rootY + 500, 0, 1)

        for x = 1, #xList do
            love.graphics.line(parentX + #n.name * 12, rootY + 550, xList[x] + #nList[x] * 12, rootY + 1000)
        end

        pxList[plistIndex] = parentX
        pnList[plistIndex] = n.name
        plistIndex = plistIndex + 1
    end

    rootXPrint = math.floor((pxList[1] + pxList[#pxList]) / 2)
    love.graphics.print(rootNode.name, rootXPrint, rootY, 0, 1)
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

function CheckLineOfSight(ox,oy, gx,gy)
    local angle = GetAngle(ox,oy, gx,gy)
    local x,y = ox + 0.5,oy + 0.5

    while IsTileWalkable(math.floor(x),math.floor(y)) do
        if math.floor(x) == gx and math.floor(y) == gy then
            return true
        end

        x,y = x + math.cos(angle)*0.1, y + math.sin(angle)*0.1
    end

    return false
end

function PrintMap(checked)
    for y=0, 15 do
        local str = ""
        for x=0, 15 do
            if checked[x][y] then
                str = str .. "O"
            else
                if IsTileWalkable(x,y) then
                    str = str .. " "
                else
                    str = str .. "█"
                end
            end
        end
        print(str)
    end
end

-- this isn't a node, this is just a basic pathfinding function
-- this is used by some nodes to do pathfinding
function PathfindAndGiveDirections(ox,oy, gx,gy, debugPrint)
    local frontier = {}
    local checked = {}
    for i=0, 17 do
        checked[i] = {}
    end
    local nextNode = nil
    table.insert(frontier, {ox,oy, cost=Distance(ox,oy, gx,gy), parent=nil})

    -- greedy best first
    while true do
        -- pop off queue
        local this = table.remove(frontier, 1)

        if debugPrint then
            print("------")
            PrintMap(checked)
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
        return math.cos(angle), math.sin(angle)
    end

    return 0,0
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
