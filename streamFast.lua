-- Roblox BaBFT Stream for Python code (need rework)
print("===============STREAM_START===============")
-- Переменные
local player = game:GetService("Players").LocalPlayer.Name
local playerClass = game:GetService("Players")[player]

local fps = 10
local file = 'done.txt'
local blocks = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
local pb = 'PlasticBlock'
local PaintingTool = playerClass.Character:FindFirstChild("PaintingTool") or playerClass.Backpack:FindFirstChild("PaintingTool")
local args = { [1] = {} }

local frame = 0
local max = 50

local size = 96*54
local sort_axis = 'v'

local success = false

local waiting = 1 / fps
local startTime = 0

-- Сортировка
function sorting(axis)
    if axis == 'v' then -- Вертикальня
        table.sort(blocks, function(a, b)
            return a.PPart.CFrame.Y > b.PPart.CFrame.Y or (a.PPart.CFrame.Y == b.PPart.CFrame.Y and a.PPart.CFrame.X < b.PPart.CFrame.X)
        end)
    elseif axis == 'h' then -- Горизонтальная
        table.sort(blocks, function(a, b)
            return a.PPart.CFrame.Z > b.PPart.CFrame.Z or (a.PPart.CFrame.Z == b.PPart.CFrame.Z and a.PPart.CFrame.X > b.PPart.CFrame.X)
        end)
    end
end
sorting(sort_axis)


-- Создание списка
bn = 1
for i, block in pairs(blocks) do
    if pb and block.Name ~= pb then
        continue
    end

    args[1][bn] = {
        [1] = block,
        [2] = Color3.new(0, 0, 0)
    }
    bn = bn + 1
end

-- Начальная покраска
filename = "start_"..file
while success == false do
    success, result = pcall(readfile, filename)
end
loadstring(result)()
success = false
for i, px in pairs(pixs) do
    args[1][px[1]][2] = Color3.new(px[2][1], px[2][2], px[2][3])
end
PaintingTool.RF:InvokeServer(unpack(args))

if #args[1] ~= size then
    error('WARNING: ' .. #args[1] .. '/' .. size .. ' BLOCKS!!!')
end

startTime = os.clock()
-- Главный цикл
while true do
    local st = os.clock()
    -- Имя файла
    local filename = file

    -- Чтение файла
    while success == false do
        success, result = pcall(readfile, filename)
        wait(0.01)
    end
    
    success = false
    task.spawn(function()
        -- local pixs = {}
        loadstring(result)()
        -- local paintData = table.clone(args)
        -- local paintData = {}
        -- for i, bl in pairs(blocks) do
        --     paintData[i] = {
        --         [1] = bl,
        --         [2] = Color3.new(pixs[i][2][1], pixs[i][2][2], pixs[i][2][3])
        --     }
        -- end
        -- PaintingTool.RF:InvokeServer(paintData)
		-- print(pixs, #pixs)

        for i, px in pairs(pixs) do
            args[1][px[1]][2] = Color3.new(px[2][1], px[2][2], px[2][3])
        end
        PaintingTool.RF:InvokeServer(unpack(args))
    
        -- Покраска блоков
        -- for i, px in pairs(pixs) do
        --     paintData[1][px[1]][2] = Color3.new(px[2][1], px[2][2], px[2][3])
        -- end
        -- PaintingTool.RF:InvokeServer(unpack(paintData))
    end)

    -- Ограничитель
    frame = frame + 1
    
    local et = os.clock()
    local duration = et - st
    if duration <= 0 then duration = 0 end

    
    print('frame_'..frame .. ' fps_' .. frame / (os.clock() - startTime))
    wait(waiting - duration)

    if frame >= max then
        break
    end
end

print('end')