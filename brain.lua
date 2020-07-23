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
        InverterNode(NewWithinRangeNode(6)),
        NewSnipeEnemyNode(),
    })

    createSubtree("snipeToKill", {
        NewLineOfSightNode(),
        InverterNode(NewCheckEnemyHealthNode(50)),
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
        --InverterNode(NewWithinRangeNode(4)),
        NewFireballEnemyNode(),
    })

    createSubtree("fireball", {
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

    createSubtree("retreatWhenBelowHalf", {
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

    createSubtree("heal", {
        NewHealNode(),
    })
    -- end of heal trees

    -- Only pick one default movement
    createSubtree("runAway", {
        NewTakeCoverNode(),
    })

    createSubtree("advance", {
        NewWalkTowardsEnemyNode(),
    })

    createSubtree("preparedAdvance", {
        NewCheckOwnerHealthNode(75),
        NewCheckOwnerManaNode(50),
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

    createSubtree("advanceUntilNear", {
        InverterNode(NewWithinRangeNode(3)),
        NewWalkTowardsEnemyNode(),
    })

    createSubtree("seekAndFleePattern", {
        NewWalkTowardsEnemyNode(),
        NewFleeFromEnemyNode(),
    })

    createSubtree("peekAroundCorner", {
        InverterNode(NewLineOfSightNode()),
        NewWalkTowardsEnemyNode(),
    })

    createSubtree("runAwayFromDamage", {
        NewIsTakingDamageRightNowNode(),
        NewTakeCoverNode(),
    })

    createSubtree("runAwayFromSnipe", {
        NewIsEnemySnipingNode(),
        NewTakeCoverNode(),
    })

    createSubtree("strafe", {
        NewStrafeNode(),
    })

    createSubtree("approachCamper", {
        InverterNode(NewIsEnemyApproachingNode()),
        InverterNode(NewWithinRangeNode(3)),
        NewWalkTowardsEnemyNode(),
    })

    createSubtree("avoidFireDamage", {
        NewIsFireballAttackFreshNode(),
        NewTakeCoverNode(),
    })

    -- a recipe that works well for building AIs
    --   damage control
    --   attack pattern
    --   movement

    -- movement strats that work well
    --   advanceUntilNear + strafe
    --   peekAroundCorner
    --   advanceWhenFar + runAwayWhenClose (for fireball specialists)
    local damageControl = {
        {
            Subtrees.runAwayFromSnipe,
            Subtrees.runAwayFromDamage,
            --Subtrees.avoidFireDamage,
        },

        {
            Subtrees.runAwayFromSnipe,
            Subtrees.retreatWhenBelowHalf,
            Subtrees.healInCover,
        },

        {
            Subtrees.healInCover,
        },

        {
            Subtrees.runAwayFromSnipe,
            Subtrees.runAwayFromDamage,
        },

        -- the option for no damage control
        {},
    }

    local attackPattern = {
        {
            Subtrees.fireballInRange,
            Subtrees.zapInRange,
        },

        {
            Subtrees.snipeOnSight,
            Subtrees.fireballInRange,
            Subtrees.zapInRange,
        },

        {
            Subtrees.snipeOnSight,
            Subtrees.zapWithMana,
        },

        {
            Subtrees.fireballInRange,
            Subtrees.healInPlace,
            Subtrees.zapInRange,
        },

        {
            Subtrees.snipeToKill,
            Subtrees.zapWithMana,
        },

        -- it may be good to add more attack patterns here
    }

    local movement = {
        {
            Subtrees.advanceUntilNear,
            Subtrees.strafe,
        },

        {
            -- need some way to avoid stalemates here
            Subtrees.peekAroundCorner,
            Subtrees.approachCamper,
            --Subtrees.seekAndFleePattern,
        },

        --{
            --Subtrees.approachCamper,
            --Subtrees.runAway,
        --},

        {
            Subtrees.advanceWhenFar,
            Subtrees.runAwayWhenClose,
        },

        --[[
        {
            --Subtrees.seekAndFleePattern,
            Subtrees.strafe,
        }
        ]]

        -- research if there are any other good movement patterns
    }

    local botTemplates = {
        poggers = {
            -- damage control
            Subtrees.runAwayFromSnipe,
            Subtrees.runAwayFromDamage,

            -- attack pattern
            Subtrees.fireballInRange,
            Subtrees.zapInRange,

            -- movement
            Subtrees.advanceUntilNear,
            Subtrees.strafe,
        },

        patient = {
            -- damage control
            Subtrees.runAwayFromSnipe,
            Subtrees.retreatWhenBelowHalf,
            Subtrees.healInCover,

            -- attack pattern
            Subtrees.snipeOnSight,
            Subtrees.fireballInRange,
            Subtrees.zapInRange,

            -- movement
            Subtrees.peekAroundCorner,
        },

        camper = {
            -- damage control
            Subtrees.healInCover,

            -- attack pattern
            Subtrees.snipeOnSight,
            Subtrees.zapWithMana,

            -- movement
            Subtrees.runAway,
        },

        flamethrower = {
            -- damage control
            Subtrees.runAwayFromSnipe,
            Subtrees.runAwayFromDamage,

            -- attack pattern
            Subtrees.fireballInRange,
            Subtrees.healInPlace,
            Subtrees.zapInRange,

            -- movement
            Subtrees.advanceWhenFar,
            Subtrees.runAwayWhenClose,
            --Subtrees.retreatWhenBelowHalf,
        },

        rambo = {
            -- rambo doesn't have damage control

            -- attack pattern
            Subtrees.snipeToKill,
            Subtrees.zapWithMana,

            -- movement
            Subtrees.advanceUntilNear,
            Subtrees.strafe,
        },

        --[[
        zapAndSnipe = {
            Subtrees.runAwayFromDamage,
            Subtrees.zapWithMana,
            Subtrees.snipeToKill,
            Subtrees.advance,
            Subtrees.weakHealInCover,
            Subtrees.weakRetreat,
        },
        ]]
    }

        --[[
        fireballCamper = {
            Subtrees.healInCover,
            Subtrees.fireball,
            Subtrees.peekAroundCorner,
            Subtrees.runAway,
        },

        sneakySniper = {
            Subtrees.runAwayFromDamage,
            Subtrees.healInCover,
            Subtrees.retreatWhenBelowHalf,
            Subtrees.snipeOnSight,
            Subtrees.advance,
        },

        coward = {
            Subtrees.zapWithMana,
            Subtrees.runAwayFromDamage,
            Subtrees.runAway,
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

            local template = {}
            handcraftedTemplates = false
            if handcraftedTemplates then
                -- choose a random template from the predefined list of botTemplates

                local templateNames = {}
                for name,temp in pairs(botTemplates) do
                    table.insert(templateNames, name)
                end
                local templateName = Choose(templateNames)
                template = botTemplates[templateName]
                brain.root = NewSelectorNode(templateName)
            else
                -- generate one on the fly from parts!

                for i,v in pairs(Choose(damageControl)) do
                    table.insert(template, v)
                end

                for i,v in pairs(Choose(attackPattern)) do
                    table.insert(template, v)
                end

                for i,v in pairs(Choose(movement)) do
                    table.insert(template, v)
                end

                brain.root = NewSelectorNode("generatedBot")
            end

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
    local x,y = ox,oy

    while IsTileWalkable(WorldToTileCoords(x,y)) do
        if Distance(x,y, gx,gy) <= 32 then
            return true
        end

        x,y = x + math.cos(angle), y + math.sin(angle)
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

-- this has now been converted to an A* pathfinder that is biased against going through fire tiles
function PathfindAndGiveDirections(ox,oy, gx,gy, debugPrint)
    local frontier = {}
    local checked = {}
    for i=0, 17 do
        checked[i] = {}
    end
    local nextNode = nil
    table.insert(frontier, {ox,oy, cost=Distance(ox,oy, gx,gy), parent=nil})

    -- A*
    while true do
        -- pop off queue
        local this = table.remove(frontier, 1)

        -- if i have run out of things to do, end loop
        if not this then break end

        -- if this is the goal, end loop
        if this[1] == gx and this[2] == gy then
            nextNode = this
            break
        end

        -- define a local function for adding neighbors
        -- TODO this is very inefficient, might want to abstract this out later if we want to increase performance
        local function addNeighbor(x,y)
            local cost = this.cost + 1

            local pathClear = IsTileWalkable(x,y)
            local dx = x - this[1]
            local dy = y - this[2]
            if dx ~= 0 and dy ~= 0 then
                pathClear = pathClear and (IsTileWalkable(this[1] + dx, this[2]) or IsTileWalkable(this[1], this[2] + dy))
                cost = this.cost + 0.7071
            end

            -- make fire tiles cost more
            if GetTile(x,y) == FIRE_TILE then cost = cost + 40 end

            -- if this tile is walkable and either i havn't been here or this route is cheaper
            if pathClear and (not checked[x][y] or cost < checked[x][y].cost) then
                local next = {x,y, cost=cost, priority=cost+Distance(x,y, gx,gy), parent=this}
                table.insert(frontier, next)
                checked[x][y] = next
            end
        end

        -- add neighbors (cardinal directions)
        for xx=-1,1 do
            for yy=-1,1 do
                if not (xx == 0 and yy == 0) then
                    addNeighbor(this[1]+xx,this[2]+yy)
                end
            end
        end

        -- sort queue by distance to goal
        table.sort(frontier, function (a,b)
            return a.priority < b.priority
        end)
    end

    if debugPrint then
        print("------------------------")
        PrintMap(checked)
    end

    -- go back until at 2nd node
    while nextNode and nextNode.parent and nextNode.parent.parent do
        nextNode = nextNode.parent
    end

    -- get move to next node in the queue
    if nextNode then
        return nextNode[1]*64 + 32, nextNode[2]*64 + 32
    end

    -- if i didn't find a good route, just return no move
    return 0,0
end
