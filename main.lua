debug = true

love.window.minimize( )

local inspect = require "inspect"

local pointsObj = {}
local pointsList = {}
local dEdgesObj = {}
local dEdgesList = {}

function love.load(arg)

    local start_time = love.timer.getTime()
    
    -- generate points field
    pointsObj = pointsSetGenerator (1000,0.4)
    -- print(inspect(pointsObj))
    pointsList = flattenPointsObj(pointsObj)
    print(string.format("%.3f ms to Generate Points field", 1000 * (love.timer.getTime() - start_time)))    
    
    -- generate debbinoi edges
    local temp_time = love.timer.getTime()
    dEdgesObj = debbinoiEdgesGenerator ( pointsObj)
    -- print_r(dEdgesObj)
    -- dEdgesList = flattenDEdgesObj (dEdgesObj)
    -- print (inspect(dEdgesList))

    print(string.format("%.3f ms to Generate Debbinoi Edges", 1000 * (love.timer.getTime() - temp_time)))
    
    print ("----------------------------")
    print(string.format("%.3f ms Total Time Taken", 1000 * (love.timer.getTime() - start_time)))
    
end

function love.draw(dt)
    
    love.graphics.setPointSize( 5 )
    love.graphics.setColor(255,0,0)
    -- love.graphics.points(pointsList)
    
    -- using a for loop right now for debugging purposes
    for k, point in pairs(pointsObj) do
        love.graphics.setColor(255,0,0)
        love.graphics.points(point.x, point.y)
        
        -- love.graphics.setColor(50,50,50)
        -- love.graphics.print(point.u .. ", " .. point.v .. ":: " .. point.x .. ", " .. point.y, point.x-20, point.y+10)
    end
     
    love.graphics.setColor(30,30,30)
    for k, point in pairs(dEdgesObj) do
        love.graphics.line(point.p1.x, point.p1.y, point.p2.x, point.p2.y) 
    end

    love.graphics.setColor(255,255,255)
    -- show cursor position. mainly for debugging
    local mouseX, mouseY = love.mouse.getPosition() -- get the position of the mouse
    love.graphics.print("X: ".. mouseX .. ", Y: " .. mouseY, mouseX-30, mouseY-15) -- draw the custom mouse image
end

function love.update(dt)
    require("lovebird").update()
    
end


function pointsSetGenerator (n,s)

    local pointsObj = {}
    
    -- n = number of points, d = max deviance allowed. between 0 and 0.5
    local scrWr = love.graphics.getWidth()
    local scrHr = love.graphics.getHeight()
    
    -- n * d^2 = scrW * scrH. Rough value of d. used to calculate the smaller screen size.
    local dr = roundToInt(math.sqrt(scrWr * scrHr / n))
    -- print(d)
    
    -- set random seed for maths lib
    math.randomseed( os.time() )
    
    -- Now we redo the screen size and distance calculations for the reduced value
    -- n = number of points, d = max deviance allowed. between 0 and 0.5
    local scrW = love.graphics.getWidth() - dr/2
    local scrH = love.graphics.getHeight() - dr/2
    
    -- n * d^2 = scrW * scrH. Rough value of d. used to calculate the smaller screen size.
    local d = roundToInt(math.sqrt(scrWr * scrHr / n))
    
    -- Generate points set 
    
    local count = 0
    -- local de = d/2            -- max distance form the edge
    
    -- n = number of points, d = max deviance allowed. between 0 and 0.5
    local scrW = love.graphics.getWidth() - d -- consider a reduced screensize so that the points dont touch the edge
    local scrH = love.graphics.getHeight() - d
    
    local cntU = 0                -- counters for each loop
    for y = 1.5*d, scrH, d do
    
        cntU = cntU + 1
        local cntV = 0            -- counters for each loop
        for x = 1.5*d, scrW, d do
            cntV = cntV + 1
            -- apply deviance to get randomness
            local dx = x + (d * math.random(0, s*100)/100 * ((math.random(1,2)*2)-3))
            local dy = y + (d * math.random(0, s*100)/100 * ((math.random(1,2)*2)-3))
            
            dx = roundToInt(dx)
            dy = roundToInt(dy)
            
            
            table.insert(pointsObj, {x = dx, y = dy, u = cntU, v = cntV})

            count = count + 1
            -- print (count, cntU, cntV, dx, dy)
            
        end
    end
    -- print (inspect(pointsObj))
    print ("Generated points = " .. count .. " / " .. n)
    -- return pointsList
    return pointsObj
end

function debbinoiEdgesGenerator (pointsObj)
    -- temp obj where we store pointsObj and the edge state for each point.
    local tempObj = pointsObj
    local tempEdgesObj = {}
    local countEdges = 0
    
    for k, point in pairs(tempObj) do
        
        -- for all points set the default state allEdgesDone=false
        -- point.allEdgesDone = false
        
        -- print (inspect(point))
        
        -- get neighbors
        
        -- if point.allEdgesDone == false then
            local neighbours = getSquareGridNeighbours(point.u, point.v, pointsObj)
            -- print (inspect(neighbours))
            -- print ("------------")
            -- print("point.allEdgesDone value before getNeighbours is: ", point.allEdgesDone)
            -- print("Neighbours of " .. point.u .. ", " .. point.v .. " are :")

            -- create edge
            -- For creating edges we take each point and create edges against each of its neighbors. After all edges for that point are set, set it allEdgesDone state to true. For any other point for which this point was a neighbour, it will not be considered for calculation is that state is true. This ensure that we get unique lines/edges.
            
            local tempEdge = {p1 = {u=0, v=0, x = 0, y = 0}, p2 = {u=0, v=0, x = 0, y = 0}}
            for _,neighbour in pairs (neighbours) do
  
                local p2x, p2y = getCenterFromIndex(neighbour.u, neighbour.v , pointsObj)
                -- print(inspect(neighbour))
                -- print("......")
                -- table.insert(tempEdgesObj, tempEdge)
                countEdges = countEdges + 1
                -- print(countEdges)
                -- print(inspect(tempEdge))

                -- tempEdgesObj[countEdges] = tempEdge
                tempEdgesObj[countEdges] = 
                {
                    p1 = {u = point.u, v = point.v, x = point.x, y = point.y},
                    p2 = {u = neighbour.u, v = neighbour.v, x = p2x, y = p2y}
                }

            end



            -- now that this point is used up, set point.allEdgesDone = true so we dont use it again in edge generation
            -- point.allEdgesDone = true
                        
            -- print ("------------")
            -- print("point.allEdgesDone value AFTER getNeighbours is: ", point.allEdgesDone)

    end
    
    print("Generated Edges = " .. countEdges)
    -- print(inspect(tempObj))
    -- print(inspect(tempEdgesObj))

    return tempEdgesObj
end

function getSquareGridNeighbours (pu, pv, pointsObj)
    local minu, minv = 1, 1 -- since our grid starts at 1,1
    local maxu, maxv
    -- minu, miny, maxu and maxv give the boundaries of u and v values. As its a square grid, we can just take the last point generated as max and starting as min.
    -- any neighbour generated which is greater than these max values will be discarded.

    for k, point in pairs(pointsObj) do
        maxu = point.u
        maxv = point.v
        -- print(minu, minv, maxu, maxv)
        -- keep iterating till the last value is asigned to the max variables
    end
    
    -- print(minu, minv, maxu, maxv)
    
    local u, v = 0, 0
    local neighbours = {}
    
    -- top left corner
    if pu == minu and pv == minv then
        table.insert(neighbours, {u = pu,       v =  pv + 1})
        table.insert(neighbours, {u = pu + 1,   v =  pv})

    -- top right corner
    elseif pu == minu and pv == maxv then
        table.insert(neighbours, {u = pu + 1,   v =  pv})
        table.insert(neighbours, {u = pu,       v =  pv - 1})
        
    -- bottom left corner
    elseif pu == maxu and pv == minv then
        table.insert(neighbours, {u = pu,       v =  pv + 1})
        table.insert(neighbours, {u = pu - 1,   v =  pv})
        
    -- bottom right corner
    elseif pu == maxu and pv == maxv then
        table.insert(neighbours, {u = pu,       v =  pv - 1})
        table.insert(neighbours, {u = pu - 1,   v =  pv})
        
    -- top border
    elseif pu == minu and (minv < pv) and (pv < maxv) then
        table.insert(neighbours, {u = pu,       v =  pv + 1})
        table.insert(neighbours, {u = pu + 1,   v =  pv})
        table.insert(neighbours, {u = pu,       v =  pv - 1})
        
    -- bottom border
    elseif pu == maxu and (minv < pv) and (pv < maxv) then
        table.insert(neighbours, {u = pu,       v =  pv + 1})
        table.insert(neighbours, {u = pu,       v =  pv - 1})
        table.insert(neighbours, {u = pu - 1,   v =  pv})
        
    -- left border
    elseif (minu < pu) and (pu < maxu) and pv == minv then
        table.insert(neighbours, {u = pu,       v =  pv + 1})
        table.insert(neighbours, {u = pu + 1,   v =  pv})
        table.insert(neighbours, {u = pu - 1,   v =  pv})
        
    -- right border
    elseif (minu < pu) and (pu < maxu) and pv == maxv then
        table.insert(neighbours, {u = pu + 1,   v =  pv})
        table.insert(neighbours, {u = pu,       v =  pv - 1})
        table.insert(neighbours, {u = pu - 1,   v =  pv})
        
    -- center content
    elseif (minu < pu) and (pu < maxu) and (minv < pv) and  (pv < maxv) then
        table.insert(neighbours, {u = pu,       v =  pv + 1})
        table.insert(neighbours, {u = pu + 1,   v =  pv})
        table.insert(neighbours, {u = pu,       v =  pv - 1})
        table.insert(neighbours, {u = pu - 1,   v =  pv})

    end

    return neighbours
end

function getHexGridNeighbours (u, v, w)
    -- return {  (u,v+1), (u+1,v), (u+1,v-1), (u,v-1), (u-1,v), (u-1,v+1)}
end

function roundToInt(n)
    return (math.floor(n+0.5))
end

-- flatten our points object to get a sequence of xy cords of the points for use in love.graphics.points
function flattenPointsObj (pointsObj)
    local pointsList ={}
    
    for k, point in pairs(pointsObj) do
        table.insert(pointsList, point.x)
        table.insert(pointsList, point.y)
    end
    -- print (inspect(pointsList))
    return pointsList
end

function flattenDEdgesObj (dEdgesObj)
    local dEdgesList = {}
    for _, edge in pairs(dEdgesObj) do
    
    -- print (edge.p1.x)
        table.insert(dEdgesList, edge.p1.x)
        table.insert(dEdgesList, edge.p1.y)
        table.insert(dEdgesList, edge.p2.x)
        table.insert(dEdgesList, edge.p2.y)
    end
    -- print (inspect(dEdgesList))
    return dEdgesList
end

function getCenterFromIndex (pu,pv, pointsObj)
    for _, point in pairs(pointsObj) do
        if (pu == point.u and pv == point.v) then
            return point.x, point.y
        end
    end

end

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end