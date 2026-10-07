-- Roblox BaBFT Chess
print('=============CHESS_START=============')

-- Parameters
local chessDataFile = 'chess_setup.json'
local filename = "data.txt"
local tile_size = 10
local startPos = Vector3.new((tile_size * 4)-(tile_size / 2), 6, (-tile_size * 4)+(tile_size / 2))
local offset = Vector3.new(startPos.X, startPos.Y, startPos.Z)
local debugMax = 0
local winPiece = 'King'
local boardRows = 8
local boardCols = 8

-- Services
local HttpService = game:GetService("HttpService")
-- Player
local player = game:GetService("Players").LocalPlayer.Name
local playerClass = game:GetService("Players")[player]
-- Tools
local BuildTool = playerClass.Character:FindFirstChild("BuildingTool") or playerClass.Backpack:FindFirstChild("BuildingTool")
local PaintTool = playerClass.Character:FindFirstChild("PaintingTool") or playerClass.Backpack:FindFirstChild("PaintingTool")
local ScaleTool = playerClass.Character:FindFirstChild("ScalingTool") or playerClass.Backpack:FindFirstChild("ScalingTool")
local DeleteTool = playerClass.Character:FindFirstChild("DeleteTool") or playerClass.Backpack:FindFirstChild("DeleteTool")
local TrowelTool = playerClass.Character:FindFirstChild("TrowelTool") or playerClass.Backpack:FindFirstChild("TrowelTool")
-- Team
local zones = {
    black = "BlackZone",
    blue = "Really blueZone",
    green = "CamoZone",
    red = "Really redZone",
    white = "WhiteZone",
    yellow = "New YellerZone",
    magenta = "MagentaZone"
}
local teamName = playerClass.Team.Name
local team = workspace:FindFirstChild(zones[teamName])
local teamCF = team.CFrame
-- Board data
local ChessBoard = {}
local setup = HttpService:JSONDecode(readfile(chessDataFile))
-- Piece data
local pieceClasses = {
    PawnW = nil, PawnB = nil,
    RookW = nil, RookB = nil,
    KnightW = nil, KnightB = nil,
    BishopW = nil, BishopB = nil,
    QueenW = nil, QuuenB = nil,
    KingW = nil, KingB = nil
}
local pieceFunctions = {
    PawnW = nil, PawnB = nil,
    RookW = nil, RookB = nil,
    KnightW = nil, KnightB = nil,
    BishopW = nil, BishopB = nil,
    QueenW = nil, QueenB = nil,
    KingW = nil, KingB = nil
}
local transformFunctions = {
    PawnW = nil, PawnB = nil,
    RookW = nil, RookB = nil,
    KnightW = nil, KnightB = nil,
    BishopW = nil, BishopB = nil,
    QueenW = nil, QueenB = nil,
    KingW = nil, KingB = nil
}
-- Tile Colors
local  tileColors = {
    Red = Color3.new(0.5, 0, 0),
    Green = Color3.new(0.17, 0.39, 0.17),
    Purple = Color3.new(0.42, 0.19, 0.48)
}
-- Map
local currPieces = {}
local activeTiles = {}
local currTransformPieces = {}
-- Other
local args = {[1] = {
    [1] = {[1]=nil}
}}
-- End
local endgame = false


print("=============Functions=============")

local function deepCopy(original)
    if type(original) ~= "table" then
        return original -- Возвращаем нетекстовые значения как есть
    end

    local copy = {}
    for key, value in pairs(original) do
        copy[deepCopy(key)] = deepCopy(value) -- Рекурсия для ключей и значений
    end
    return copy
end

local function getLast()
    last = workspace.Blocks[player]:GetChildren()
    last = last[#last]
    return last
end

local function getBlockByIndex(i)
    local blocks = workspace.Blocks[player]:GetChildren()
    return blocks[i]
end

local function getCFrame(block, addPos, setPos)
    if setPos then
        position = Vector3.new(
            offset.X + setPos.X,
            offset.Y + setPos.Y,
            offset.Z + setPos.Z
        )
    else
        if addPos then
            position = Vector3.new(
                block.Position.X + addPos.X,
                block.Position.Y + addPos.Y,
                block.Position.Z + addPos.Z
            )
        else
            position = Vector3.new(
                block.Position.X + offset.X,
                block.Position.Y + offset.Y,
                block.Position.Z + offset.Z
            )
        end
    end
    local right = Vector3.new(
        block.Orientation.Right.X,
        block.Orientation.Right.Y,
        block.Orientation.Right.Z
    )
    local up = Vector3.new(
        block.Orientation.Up.X,
        block.Orientation.Up.Y,
        block.Orientation.Up.Z
    )
    local look = Vector3.new(
        block.Orientation.Look.X,
        block.Orientation.Look.Y,
        block.Orientation.Look.Z
    )

    return CFrame.fromMatrix(position, right, up, look)
end

local function createTile(tile, row, col, startLen, num)
    local amount = playerClass.Data[tile.Material].Value
    rc_pos = Vector3.new(-((col-1) * tile_size), 0, (row-1) * tile_size)
    local cframe = getCFrame(tile, nil, nil)

    BuildTool.RF:InvokeServer(tile.Material, amount, team, cframe, true)
    local last = getBlockByIndex(startLen + num)
    local size = Vector3.new(tile.Size.X, tile.Size.Y, tile.Size.Z)
    local paintData = {{
        [1] = last,
        [2] = Color3.new(tile.Color.R, tile.Color.G, tile.Color.B)
    }}

    ScaleTool.RF:InvokeServer(last, size, last.PPart.CFrame)
    PaintTool.RF:InvokeServer(paintData)

    pos = Vector3.new(
        last.PPart.CFrame.Position.X - teamCF.Position.X,
        last.PPart.CFrame.Position.Y - teamCF.Position.Y,
        last.PPart.CFrame.Position.Z - teamCF.Position.Z
    )

    return {
        Row = row,
        Col = col,
        Block = last,
        Position = pos,
        Piece = nil,
        Color = Color3.new(tile.Color.R, tile.Color.G, tile.Color.B),
        Lever = nil
    }
end


local function buildBoard(data)
    local paintData = {}
    local startLen = #workspace.Blocks[player]:GetChildren()
    local waitLen = #data

    for i, bl in pairs(data) do
        task.spawn(function()
            local amount = playerClass.Data[bl.Material].Value
            local cframe = getCFrame(bl)
            
            BuildTool.RF:InvokeServer(bl.Material, amount, team, cframe, true)
    
            local last = getBlockByIndex(i + startLen)
            local size = Vector3.new(bl.Size.X, bl.Size.Y, bl.Size.Z)
    
            ScaleTool.RF:InvokeServer(last, size, last.PPart.CFrame)
    
            table.insert(paintData, {
                last, Color3.new(bl.Color.R, bl.Color.G, bl.Color.B)
            })
            waitLen -= 1
        end)
    end
    
    while waitLen ~= 0 do 
        task.wait(0.1)
    end

    PaintTool.RF:InvokeServer(paintData)
end


local function buildTiles(data)
    local startLen = #workspace.Blocks[player]:GetChildren()
    local waitLen = boardRows * boardCols
    table.sort(data, function(a, b)
		return a.Position.Z < b.Position.Z or (a.Position.Z == b.Position.Z and a.Position.X > b.Position.X)
    end)

    for r = 1, boardRows do
        for c = 1, boardCols do
            task.spawn(function()
                local num = ((r-1) * boardCols) + c
                local tile = createTile(data[num], r, c, startLen, num)
                
                ChessBoard[r][c] = tile
                waitLen -= 1
            end)
        end
    end

    while waitLen ~= 0 do
        task.wait(0.1)
    end
end

local function createPieceClasses(data)
    for name, blocks in pairs(data) do
        local piece = {
            Build = blocks,
            Blocks = deepCopy({}),
            Name = name,
            Tile = nil,
            Lever = nil,
            Status = false,
            Func = pieceFunctions[name],
            TransformFunc = transformFunctions[name],
            FirstMove = true,
            Side = string.sub(name, -1)
        }
        pieceClasses[name] = deepCopy(piece)
    end
end

local function createLever(data)
    local lever = {
        Build = data,
        Block = nil,
        Piece = nil,
        Status = false
    }
    return deepCopy(lever)
end

local function setupChessBoard(data)
    for n, name in pairs(data) do
        local piece = deepCopy(pieceClasses[name])
        local num = tonumber(n)
        local row = (num-1) // 8 + 1
        local col = (num-1) % 8 + 1

        local tile = ChessBoard[row][col]
        local lever = createLever(setup.Lever)
        tile.Piece = piece
        lever.Piece = piece
        piece.Tile = tile
        piece.Lever = lever

        table.insert(currPieces, piece)
    end
end

local function buildLever(piece, startLen, i)
    startLen = startLen or #workspace.Blocks[player]:GetChildren()
    i = i or 1
    local amount = playerClass.Data['Switch'].Value
    local cframe = getCFrame(piece.Lever.Build, piece.Tile.Position)
    local paintData = {}
    BuildTool.RF:InvokeServer('Switch', amount, team, cframe, true)

    local last = getBlockByIndex(startLen + i)
    table.insert(paintData, {
        [1] = last,
        [2] = Color3.new(piece.Lever.Build.Color.R, piece.Lever.Build.Color.G, piece.Lever.Build.Color.B)
    })
    PaintTool.RF:InvokeServer(paintData)

    piece.Lever.Block = last
end

local function buildPiece(piece)
    local paintData = {}
    local startLen = #workspace.Blocks[player]:GetChildren()
    local waitLen = #piece.Build

    for i, bl in pairs(piece.Build) do
        task.spawn(function()
            local amount = playerClass.Data[bl.Material].Value
            local cframe = getCFrame(bl, piece.Tile.Position) + teamCF.Position
            local randCF = CFrame.new(math.random(-69, 69), math.random(-2000000, -1000000), math.random(-69, 69))
            
            BuildTool.RF:InvokeServer(bl.Material, amount, team, randCF, true)
            
            local last = getBlockByIndex(startLen + i)
            local size = Vector3.new(bl.Size.X, bl.Size.Y, bl.Size.Z)
            ScaleTool.RF:InvokeServer(last, size, cframe)

            table.insert(paintData, {
                [1] = last,
                [2] = Color3.new(bl.Color.R, bl.Color.G, bl.Color.B)
            })
            table.insert(piece.Blocks, last)
            waitLen -= 1
        end)
    end

    while waitLen ~= 0 do
        task.wait(0.1)
    end

    PaintTool.RF:InvokeServer(paintData)

    return piece
end

local function buildAllPieces()
    for i, piece in ipairs(currPieces) do
        piece = buildPiece(piece)
    end
end

local function deactivateAll()
    args = {[1] = {[1] = nil}}
    for i, tile in ipairs(activateTile) do
        del = {tile.Lever.Block}
        DeleteTool.RF:InvokeServer(unpack(args))
        args[1][i] = {
            [1] = tile.Block,
            [2] = tile.Color
        }
        tile.Lever = nil
    end
    PaintTool.Rf:InvokeServer(unpack(args))
    table.clear(activeTiles)
    args = {[1] = {[1] = nil}}
end

local function activateTile(tile, piece, eat, move, build)
    if build == nil then build = true end
    if eat == nil then eat = true end
    if move == nil then move = true end
    local red = false
    local paintData = {{[1]=tile.Block, [2]=tile.Color}}
    if tile.Piece and tile.Piece == piece then
        paintData[1][2] = tileColors['Purple']
    elseif tile.Piece and tile.Piece.Side == piece.Side then
        return true
    elseif tile.Piece and eat then
        paintData[1][2] = tileColors['Red']
        red = true
    elseif not tile.Piece and move then
        paintData[1][2] = tileColors['Green']
    else
        return true
    end
    PaintTool.RF:InvokeServer(paintData)
    
    if build == true then
        local lever = createLever(setup.Lever)
        tile.Lever = lever
        local cframe = getCFrame(piece.Lever.Build, tile.Position)
        local amount = playerClass.Data['Switch'].Value
        BuildTool.RF:InvokeServer('Switch', amount, team, cframe, true)
        -- lever.Block = getBlockByIndex(num)
    end
    
    table.insert(activeTiles, tile)
    
    return red
end

local function endActivate(startLen)
    local blocks = workspace.Blocks[player]:GetChildren()
    for i, tile in ipairs(activeTiles) do
        tile.Lever.Block = blocks[startLen+i]
    end
end

local function checkTile(tile, piece)
    if not tile.Piece then
        return nil
    end
    if tile.Piece.Side == piece.Side then
        return false
    end
    return true
end

local function pawnWMove(piece)
    local startLen = #workspace.Blocks[player]:GetChildren()
    local tasks = 1
    local row = piece.Tile.Row
    local col = piece.Tile.Col
    task.spawn(function()
        activateTile(piece.Tile, piece)
        tasks -= 1
    end)

    if row < 8 and col > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+1][col-1]
            activateTile(tile, piece, true, false)
            tasks -= 1
        end)
    end
    if row < 8 and col < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+1][col+1]
            activateTile(tile, piece, true, false)
            tasks -= 1
        end)
    end
    if row < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+1][col]
            activateTile(tile, piece, false, true)
            tasks -= 1
        end)
    end
    if row < 7 and piece.FirstMove and not red then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+2][col]
            activateTile(tile, piece, false, true)
            tasks -= 1
        end)
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    endActivate(startLen)

    piece.Status = true
end
pieceFunctions.PawnW = pawnWMove

local function pawnBMove(piece)
    local startLen = #workspace.Blocks[player]:GetChildren()
    local tasks = 1
    local row = piece.Tile.Row
    local col = piece.Tile.Col
    task.spawn(function()
        activateTile(piece.Tile, piece)
        tasks -= 1
    end)

    if row > 1 and col > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-1][col-1]
            activateTile(tile, piece, true, false)
            tasks -= 1
        end)
    end
    if row > 1 and col < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-1][col+1]
            activateTile(tile, piece, true, false)
            tasks -= 1
        end)
    end
    if row > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-1][col]
            red = activateTile(tile, piece, false, true)
            tasks -= 1
        end)
    end
    if row > 2 and piece.FirstMove and not red then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-2][col]
            activateTile(tile, piece, false, true)
            tasks -= 1
        end)
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    endActivate(startLen)

    piece.Status = true
end
pieceFunctions.PawnB = pawnBMove


local function rookWMove(piece)
    local startLen = #workspace.Blocks[player]:GetChildren()
    local tasks = 1
    local row = piece.Tile.Row
    local col = piece.Tile.Col
    task.spawn(function()
        activateTile(piece.Tile, piece)
        tasks -= 1
    end)
    
    for i=1, 8-row do
        tile = ChessBoard[row+i][col]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 

    end
    for i=1, row-1 do
        tile = ChessBoard[row-i][col]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, 8-col do
        tile = ChessBoard[row][col+i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, col-1 do
        tile = ChessBoard[row][col-i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    endActivate(startLen)

    piece.Status = true
end
local rookBMove = rookWMove
pieceFunctions.RookW = rookWMove
pieceFunctions.RookB = rookBMove

local function knightWMove(piece)
    local startLen = #workspace.Blocks[player]:GetChildren()
    local tasks = 1
    local row = piece.Tile.Row
    local col = piece.Tile.Col
    task.spawn(function()
        activateTile(piece.Tile, piece)
        tasks -= 1
    end)
    
    if row < 7 and col > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+2][col-1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row < 7 and col < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+2][col+1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end

    if row > 2 and col > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-2][col-1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row > 2 and col < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-2][col+1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end

    if row > 1 and col > 2 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-1][col-2]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row > 1 and col < 7 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-1][col+2]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end

    if row < 8 and col > 2 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+1][col-2]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row < 8 and col < 7 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+1][col+2]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    endActivate(startLen)

    piece.Status = true
end
local knightBMove = knightWMove
pieceFunctions.KnightW = knightWMove
pieceFunctions.KnightB = knightBMove

local function bishopWMove(piece)
    local startLen = #workspace.Blocks[player]:GetChildren()
    local tasks = 1
    local row = piece.Tile.Row
    local col = piece.Tile.Col
    task.spawn(function()
        activateTile(piece.Tile, piece)
        tasks -= 1
    end)
    
    for i=1, math.min(8-row, 8-col) do
        tile = ChessBoard[row+i][col+i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, math.min(8-row, col-1) do
        tile = ChessBoard[row+i][col-i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, math.min(row-1, 8-col) do
        tile = ChessBoard[row-i][col+i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, math.min(row-1, col-1) do
        tile = ChessBoard[row-i][col-i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    endActivate(startLen)

    piece.Status = true
end
local bishopBMove = bishopWMove
pieceFunctions.BishopW = bishopWMove
pieceFunctions.BishopB = bishopBMove

local function queenWMove(piece)
    local startLen = #workspace.Blocks[player]:GetChildren()
    local tasks = 1
    local row = piece.Tile.Row
    local col = piece.Tile.Col
    task.spawn(function()
        activateTile(piece.Tile, piece)
        tasks -= 1
    end)
    
    for i=1, math.min(8-row, 8-col) do
        tile = ChessBoard[row+i][col+i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, math.min(8-row, col-1) do
        tile = ChessBoard[row+i][col-i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, math.min(row-1, 8-col) do
        tile = ChessBoard[row-i][col+i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, math.min(row-1, col-1) do
        tile = ChessBoard[row-i][col-i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end

    for i=1, 8-row do
        tile = ChessBoard[row+i][col]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, row-1 do
        tile = ChessBoard[row-i][col]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, 8-col do
        tile = ChessBoard[row][col+i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end
    for i=1, col-1 do
        tile = ChessBoard[row][col-i]
        local action = checkTile(tile, piece)
        if action == false then break end 

        tasks += 1
        task.spawn(function()
            activateTile(tile, piece)
            tasks -= 1
        end)

        if action == true then break end 
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    endActivate(startLen)

    piece.Status = true
end
local queenBMove = queenWMove
pieceFunctions.QueenW = queenWMove
pieceFunctions.QueenB = queenBMove

local function kingWMove(piece)
    local startLen = #workspace.Blocks[player]:GetChildren()
    local tasks = 1
    local row = piece.Tile.Row
    local col = piece.Tile.Col
    task.spawn(function()
        activateTile(piece.Tile, piece)
        tasks -= 1
    end)
    
    if row < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+1][col]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row < 8 and col < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+1][col+1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if col < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row][col+1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row > 1 and col < 8 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-1][col+1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-1][col]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row > 1 and col > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row-1][col-1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if col > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row][col-1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end
    if row < 8 and col > 1 then
        tasks += 1
        task.spawn(function()
            tile = ChessBoard[row+1][col-1]
            activateTile(tile, piece)
            tasks -= 1
        end)
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    endActivate(startLen)

    piece.Status = true
end
local kingBMove = kingWMove
pieceFunctions.KingW = kingWMove
pieceFunctions.KingB = kingBMove

local function buildPieceLevers()
    local waitLen = #currPieces
    local startLen = #workspace.Blocks[player]:GetChildren()
    for i, piece in pairs(currPieces) do
        task.spawn(function()
            buildLever(piece, startLen, i)
            waitLen -= 1
        end)
    end

    while waitLen ~= 0 do
        task.wait(0.1)
    end
end

local function clearPieceLevers()
    local waitLen = #currPieces
    for i, piece in pairs(currPieces) do
        task.spawn(function()
            DeleteTool.RF:InvokeServer(piece.Lever.Block)
            piece.Lever.Block = nil
            waitLen -= 1
        end)
    end

    while waitLen ~= 0 do
        task.wait(0.1)
    end
end

local function clearActiveTiles()
    local tasks = #activeTiles
    local paintData = {}
    for i, tile in pairs(activeTiles) do
        task.spawn(function()
            table.insert(paintData, {
                [1] = tile.Block,
                [2] = tile.Color
            })
    
            DeleteTool.RF:InvokeServer(tile.Lever.Block)
            tile.Lever.Block = nil
            tasks -= 1
        end)
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    PaintTool.RF:InvokeServer(paintData)
    table.clear(activeTiles)
end

local function deletePiece(piece, forDel) 
    local tasks = #piece.Blocks
    for i, block in pairs(piece.Blocks) do
        task.spawn(function()
            DeleteTool.RF:InvokeServer(block)
            tasks -= 1
        end)
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    piece.Blocks = {}

    if forDel then
        for i, curr in ipairs(currPieces) do
            if curr == piece then
                table.remove(currPieces, i)
                break
            end
        end
        if piece.Name == winPiece..'W' or piece.Name == winPiece..'B' then
            endgame = true
        end
    end
    
end

local function buildTransformTile(block, pos)
    local amount = playerClass.Data[block.Material].Value
    local cframe = CFrame.fromMatrix(
        pos,
        Vector3.new(block.Orientation.Right.X, block.Orientation.Right.Y, block.Orientation.Right.Z),
        Vector3.new(block.Orientation.Up.X, block.Orientation.Up.Y, block.Orientation.Up.Z),
        Vector3.new(block.Orientation.Look.X, block.Orientation.Look.Y, block.Orientation.Look.Z)
    )
    BuildTool.RF:InvokeServer(block.Material, amount, team, cframe, true)

    local last = getLast()
    local args = {[1]={[1] = {
        [1] = last,
        [2] = Color3.new(block.Color.R, block.Color.G, block.Color.B)
    }}}
    local size = Vector3.new(block.Size.X, block.Size.Y, block.Size.Z)
    local scaleFrame = CFrame.fromMatrix(
        last.PPart.CFrame.Position, cframe.RightVector, cframe.UpVector, cframe.LookVector
    )
    ScaleTool.RF:InvokeServer(last, size, scaleFrame)
    PaintTool.RF:InvokeServer(unpack(args))

    return {
        Block = last,
        Position = pos,
        Piece = nil
    }
end

local function waitForTransform()
    while true do wait(0.01)
        for i, piece in pairs(currTransformPieces) do
            if piece.Lever.Status == piece.Lever.Block.On.Value then continue end
            return piece
        end
    end
end

local function clearTransformation()
    local tasks = #currTransformPieces
    for i, piece in pairs(currTransformPieces) do
        task.spawn(function()
            DeleteTool.RF:InvokeServer(piece.Lever.Block)
            DeleteTool.RF:InvokeServer(piece.Tile.Block)
            for _, block in pairs(piece.Blocks) do
                task.spawn(function()
                    DeleteTool.RF:InvokeServer(block)
                end)
            end
            tasks -= 1
        end)
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end

    currTransformPieces = {}
end

local function transformPiece(piece, to_piece)
    piece.Func = to_piece.Func
    piece.TransformFunc = to_piece.TransformFunc
    piece.Name = to_piece.Name
    piece.Build = to_piece.Build
    deletePiece(piece)
    buildPiece(piece)

    return piece
end

local function transformation(piece, names)
    -- local startLen = #workspace.Blocks[player]:GetChildren()
    activateTile(piece.Tile, piece, nil, nil, false)
    local tile_pos = piece.Tile.Block.PPart.CFrame.Position - teamCF.Position
    local start_coord = tile_pos.X + (tile_size * ((#names-1) * 0.5)) + tile_size

    for i, name in pairs(names) do
        local pos = Vector3.new(
            start_coord - (tile_size * i),
            tile_pos.Y + 15,
            tile_pos.Z
        )
        local last_tile = buildTransformTile(setup.TransformTile, pos)
        local last_piece = deepCopy(pieceClasses[name])
        local last_lever = createLever(setup.Lever)
        last_tile.Piece = last_piece
        last_piece.Tile = last_tile
        last_piece.Lever = last_lever
        last_piece = buildPiece(last_piece)
        buildLever(last_piece)
        table.insert(currTransformPieces, last_piece)
    end

    selected_piece = waitForTransform()
    print(piece.Name..' Is Now '..selected_piece.Name)
    clearTransformation()
    transformPiece(piece, selected_piece)
    clearActiveTiles()

    return piece
end

local function pawnWTransform(piece)
    local names = {'BishopW', 'RookW', 'KnightW', 'QueenW'}
    if piece.Tile.Row == 8 then
        transformation(piece, names)
    end
end
transformFunctions.PawnW = pawnWTransform

local function pawnBTransform(piece)
    local names = {'BishopB', 'RookB', 'KnightB', 'QueenB'}
    if piece.Tile.Row == 1 then
        transformation(piece, names)
    end
end
transformFunctions.PawnB = pawnBTransform

local function scaleMove(piece)
    local tasks = #piece.Blocks
    for i, block in pairs(piece.Blocks) do
        task.spawn(function()
            local tilepos = piece.Tile.Block.PPart.CFrame.Position
            local piecepos = block.PPart.CFrame.Position
            
            local movex = tilepos.X + piece.Build[i].Position.X
            local movez = tilepos.Z + piece.Build[i].Position.Z
    
            local cframe = CFrame.fromMatrix(
                Vector3.new(movex, piecepos.Y, movez),
                block.PPart.CFrame.RightVector,
                block.PPart.CFrame.UpVector,
                block.PPart.CFrame.LookVector
            )
    
            ScaleTool.RF:InvokeServer(block, block.PPart.Size, cframe)
            tasks -= 1
        end)
    end

    while tasks ~= 0 do
        task.wait(0.1)
    end
end

local function movePiece(piece, tile)
    piece.Tile.Piece = nil
    piece.Tile = tile
    if tile.Piece then
        deletePiece(tile.Piece, true)
    end
    tile.Piece = piece
    scaleMove(piece)
    piece.FirstMove = false

    if piece.TransformFunc and not endgame then
        piece.TransformFunc(piece)
    end
end

local function walkPiece(piece, tile)
    piece.Status = false
    clearActiveTiles()
    if piece.Tile ~= tile then
        movePiece(piece, tile)
    end
    buildPieceLevers()
end

local function selectPiece(piece)
    clearPieceLevers()
    piece.Func(piece)
    local whileEnd = false
    while true do wait(0.01)
        for i, tile in ipairs(activeTiles) do
            if tile.Lever.Status == tile.Lever.Block.On.Value then continue end
            print('||| '..string.sub('ABCDEFGH', piece.Tile.Row, piece.Tile.Row)..piece.Tile.Col..' - '..string.sub('ABCDEFGH', tile.Row, tile.Row)..tile.Col..' |||')

            tile.Lever.Status = tile.Lever.Block.On.Value
            walkPiece(piece, tile)
            whileEnd = true

            break
        end
        if whileEnd == true then break end
    end
    debugMax = debugMax - 1
    if debugMax == 0 then
        return true
    else
        return false
    end
end

local function Main()
    while true do wait(0.01)
        local debug = false
        for i, piece in pairs(currPieces) do
            if piece.Lever.Status == piece.Lever.Block.On.Value then continue end
            debug = selectPiece(piece)
            break
        end

        if debug or endgame then break end
    end
    clearPieceLevers()
end


print("=============ChessBoard_Building=============")

for row = 1, 8 do
    table.insert(ChessBoard, {})
    for col = 1, 8 do
        table.insert(ChessBoard[row], {})
    end
end

print('Board Building...')
buildBoard(setup.Board)

print('Tiles Building...')
buildTiles(setup.Tiles)

print('Create Piece Classes...')
createPieceClasses(setup.Pieces)

print('Setup ChessBoard...')
setupChessBoard(setup.Setups.Base)

print('Building Pieces...')
buildAllPieces()

print('Building Levers...')
buildPieceLevers()

print("=============Have_A_Fun=============")
Main()

print("=============THE_END=============")