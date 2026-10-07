-- Roblox BaBFT Rubik's Cube (bad)
print('=============START=============')

-- Player
local player = game:GetService("Players").LocalPlayer.Name
local playerClass = game:GetService("Players")[player]
-- Share Mode
if playerClass.Settings.ShareBlocks.Value then
    player = game:GetService("Teams")[playerClass.Team.Name].TeamLeader.Value
    playerClass = game:GetService("Players")[player]
end
-- Tools
local BuildTool = playerClass.Character:FindFirstChild("BuildingTool") or playerClass.Backpack:FindFirstChild("BuildingTool")
local PaintTool = playerClass.Character:FindFirstChild("PaintingTool") or playerClass.Backpack:FindFirstChild("PaintingTool")
local ScaleTool = playerClass.Character:FindFirstChild("ScalingTool") or playerClass.Backpack:FindFirstChild("ScalingTool")
-- Team
local teams = {
    white='WhiteZone', red='Really redZone', black='BlackZone', 
    blue='Really blueZone', green='CamoZone', magenta='MagentaZone', 
    yellow='New YellerZone'
}
local team = workspace:WaitForChild(teams[playerClass.Team.Name])
-- Blocks
local name = 'PlasticBlock'
local blocks = workspace:WaitForChild("Blocks")[player]:GetChildren()
local amount = playerClass:WaitForChild("Data"):WaitForChild(name).Value
-- offset
local xo = 0
local yo = 10
local zo = 0
-- Positions
local w = {
    {1.900009, 0.0, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 0.0, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 0.0, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.0, 0.0, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.0, 0.0, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.0, 0.0, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 0.0, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 0.0, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 0.0, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0}
}
local y = {
    {-1.900009, 5.8, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 5.8, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 5.8, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.0, 5.8, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.0, 5.8, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.0, 5.8, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 5.8, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 5.8, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 5.8, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0}
}
local b = {
    {-1.900009, 4.8, 2.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.0, 4.8, 2.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 4.8, 2.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 2.9000001, 2.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.00003, 2.9000001, 2.899993, 0, 0, 1, 0, 1, -0, -1, 0, 0},
    {1.900009, 2.9000001, 2.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 1.0, 2.899993, 0, 0, -1, 0, -1, -0, -1, 0, -0},
    {0.0, 1.0, 2.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 1.0, 2.899993, 0, 0, -1, 0, -1, 0, -1, 0, 0}
}
local g = {
    {1.900009, 4.8, -2.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.0, 4.8, -2.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 4.8, -2.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 2.9000001, -2.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {0.00003, 2.9000001, -2.899994, 0, 0, 1, 0, 1, 0, -1, 0, 0},
    {-1.900009, 2.9000001, -2.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {1.900009, 1.0, -2.899994, 0, 0, -1, 0, -1, -0, -1, 0, -0},
    {0.0, 1.0, -2.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-1.900009, 1.0, -2.899994, 0, 0, -1, 0, -1, -0, -1, 0, -0}
}
local r = {
    {2.900009, 4.8, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {2.900009, 4.8, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {2.900009, 4.8, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {2.900009, 2.9000001, 1.899993, 0, 0, -1, 0, -1, 0, -1, 0, 0},
    {2.900009, 2.9000001, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {2.900009, 2.9000001, -1.899994, 0, 0, -1, 0, -1, -0, -1, 0, -0},
    {2.900009, 1.0, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {2.900009, 1.0, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {2.900009, 1.0, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0}
}
local o = {
    {-2.900009, 4.8, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-2.900009, 4.8, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-2.900009, 4.8, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-2.900009, 2.9000001, -1.899994, 0, 0, -1, 0, -1, -0, -1, 0, -0},
    {-2.900009, 2.9000001, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-2.900009, 2.9000001, 1.899993, 0, 0, -1, 0, -1, -0, -1, 0, -0},
    {-2.900009, 1.0, -1.899994, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-2.900009, 1.0, 0.0, 0, 0, -1, 0, 1, 0, 1, 0, 0},
    {-2.900009, 1.0, 1.899993, 0, 0, -1, 0, 1, 0, 1, 0, 0}
}
-- Side
local white_side = {[1]=nil}
local yellow_side = {[1]=nil}
local blue_side = {[1]=nil}
local green_side = {[1]=nil}
local red_side = {[1]=nil}
local orange_side = {[1]=nil}

for i = 1, 9 do
    white_side[i] = CFrame.new(w[i][1]+xo, w[i][2]+yo, w[i][3]+zo, w[i][4], w[i][5], w[i][6], w[i][7], w[i][8], w[i][9], w[i][10], w[i][11], w[i][12])
    yellow_side[i] = CFrame.new(y[i][1]+xo, y[i][2]+yo, y[i][3]+zo, y[i][4], y[i][5], y[i][6], y[i][7], y[i][8], y[i][9], y[i][10], y[i][11], y[i][12])
    blue_side[i] = CFrame.new(b[i][1]+xo, b[i][2]+yo, b[i][3]+zo, b[i][4], b[i][5], b[i][6], b[i][7], b[i][8], b[i][9], b[i][10], b[i][11], b[i][12])
    green_side[i] = CFrame.new(g[i][1]+xo, g[i][2]+yo, g[i][3]+zo, g[i][4], g[i][5], g[i][6], g[i][7], g[i][8], g[i][9], g[i][10], g[i][11], g[i][12])
    red_side[i] = CFrame.new(r[i][1]+xo, r[i][2]+yo, r[i][3]+zo, r[i][4], r[i][5], r[i][6], r[i][7], r[i][8], r[i][9], r[i][10], r[i][11], r[i][12])
    orange_side[i] = CFrame.new(o[i][1]+xo, o[i][2]+yo, o[i][3]+zo, o[i][4], o[i][5], o[i][6], o[i][7], o[i][8], o[i][9], o[i][10], o[i][11], o[i][12])
end
-- Buttons
local white_btn = CFrame.new(0+xo, 0.0+yo, 0+zo, 0, 1, 0, 1, 0, 0, 0, 0, -1)
local yellow_btn = CFrame.new(0+xo, 5.8+yo, 0+zo, 0, 0, -1, -1, 0, 0, 0, 1, 0)
local blue_btn = CFrame.new(0.00003+xo, 2.9+yo, 2.899993+zo, 0, 0, -1, 0, -1, -0, -1, 0, -0)
local green_btn = CFrame.new(0.00006+xo, 2.9000001+yo, -2.899994+zo, 0, -1, 0, 0, 0, -1, 1, 0, 0)
local red_btn = CFrame.new(2.900009+xo, 2.9000001+yo, 0+zo, -1, 0, 0, 0, -1, 0, 0, 0, 1)
local orange_btn = CFrame.new(-2.900009+xo, 2.9000001+yo, 0+zo, 1, 0, 0, 0, 0, -1, 0, 1, 0)
-- Something
local last = nil
local clickDetector = nil


-- Functions
-- White
function moveWhite()
    local move = {
        [1] = {
            [1] = {
                [1] = white_side[1],
                [2] = white_side[7].PPart.Color
            },
            [2] = {
                [1] = white_side[2],
                [2] = white_side[4].PPart.Color
            },
            [3] = {
                [1] = white_side[3],
                [2] = white_side[1].PPart.Color
            },
            [4] = {
                [1] = white_side[4],
                [2] = white_side[8].PPart.Color
            },
            [5] = {
                [1] = white_side[6],
                [2] = white_side[2].PPart.Color
            },
            [6] = {
                [1] = white_side[7],
                [2] = white_side[9].PPart.Color
            },
            [7] = {
                [1] = white_side[8],
                [2] = white_side[6].PPart.Color
            },
            [8] = {
                [1] = white_side[9],
                [2] = white_side[3].PPart.Color
            },
            [9] = {
                [1] = green_side[7],
                [2] = red_side[7].PPart.Color
            },
            [10] = {
                [1] = green_side[8],
                [2] = red_side[8].PPart.Color
            },
            [11] = {
                [1] = green_side[9],
                [2] = red_side[9].PPart.Color
            },
            [12] = {
                [1] = red_side[7],
                [2] = blue_side[7].PPart.Color
            },
            [13] = {
                [1] = red_side[8],
                [2] = blue_side[8].PPart.Color
            },
            [14] = {
                [1] = red_side[9],
                [2] = blue_side[9].PPart.Color
            },
            [15] = {
                [1] = blue_side[7],
                [2] = orange_side[7].PPart.Color
            },
            [16] = {
                [1] = blue_side[8],
                [2] = orange_side[8].PPart.Color
            },
            [17] = {
                [1] = blue_side[9],
                [2] = orange_side[9].PPart.Color
            },
            [18] = {
                [1] = orange_side[7],
                [2] = green_side[7].PPart.Color
            },
            [19] = {
                [1] = orange_side[8],
                [2] = green_side[8].PPart.Color
            },
            [20] = {
                [1] = orange_side[9],
                [2] = green_side[9].PPart.Color
            }
        }
    }
    PaintTool.RF:InvokeServer(unpack(move))
end
-- Yellow
function moveYellow()
    local move = {
        [1] = {
            [1] = {
                [1] = yellow_side[1],
                [2] = yellow_side[7].PPart.Color
            },
            [2] = {
                [1] = yellow_side[2],
                [2] = yellow_side[4].PPart.Color
            },
            [3] = {
                [1] = yellow_side[3],
                [2] = yellow_side[1].PPart.Color
            },
            [4] = {
                [1] = yellow_side[4],
                [2] = yellow_side[8].PPart.Color
            },
            [5] = {
                [1] = yellow_side[6],
                [2] = yellow_side[2].PPart.Color
            },
            [6] = {
                [1] = yellow_side[7],
                [2] = yellow_side[9].PPart.Color
            },
            [7] = {
                [1] = yellow_side[8],
                [2] = yellow_side[6].PPart.Color
            },
            [8] = {
                [1] = yellow_side[9],
                [2] = yellow_side[3].PPart.Color
            },
            [9] = {
                [1] = green_side[1],
                [2] = orange_side[1].PPart.Color
            },
            [10] = {
                [1] = green_side[2],
                [2] = orange_side[2].PPart.Color
            },
            [11] = {
                [1] = green_side[3],
                [2] = orange_side[3].PPart.Color
            },
            [12] = {
                [1] = red_side[1],
                [2] = green_side[1].PPart.Color
            },
            [13] = {
                [1] = red_side[2],
                [2] = green_side[2].PPart.Color
            },
            [14] = {
                [1] = red_side[3],
                [2] = green_side[3].PPart.Color
            },
            [15] = {
                [1] = blue_side[1],
                [2] = red_side[1].PPart.Color
            },
            [16] = {
                [1] = blue_side[2],
                [2] = red_side[2].PPart.Color
            },
            [17] = {
                [1] = blue_side[3],
                [2] = red_side[3].PPart.Color
            },
            [18] = {
                [1] = orange_side[1],
                [2] = blue_side[1].PPart.Color
            },
            [19] = {
                [1] = orange_side[2],
                [2] = blue_side[2].PPart.Color
            },
            [20] = {
                [1] = orange_side[3],
                [2] = blue_side[3].PPart.Color
            }
        }
    }
    PaintTool.RF:InvokeServer(unpack(move))
end
-- Blue
function moveBlue()
    local move = {
        [1] = {
            [1] = {
                [1] = blue_side[1],
                [2] = blue_side[7].PPart.Color
            },
            [2] = {
                [1] = blue_side[2],
                [2] = blue_side[4].PPart.Color
            },
            [3] = {
                [1] = blue_side[3],
                [2] = blue_side[1].PPart.Color
            },
            [4] = {
                [1] = blue_side[4],
                [2] = blue_side[8].PPart.Color
            },
            [5] = {
                [1] = blue_side[6],
                [2] = blue_side[2].PPart.Color
            },
            [6] = {
                [1] = blue_side[7],
                [2] = blue_side[9].PPart.Color
            },
            [7] = {
                [1] = blue_side[8],
                [2] = blue_side[6].PPart.Color
            },
            [8] = {
                [1] = blue_side[9],
                [2] = blue_side[3].PPart.Color
            },
            [9] = {
                [1] = white_side[1],
                [2] = red_side[1].PPart.Color
            },
            [10] = {
                [1] = white_side[4],
                [2] = red_side[4].PPart.Color
            },
            [11] = {
                [1] = white_side[7],
                [2] = red_side[7].PPart.Color
            },
            [12] = {
                [1] = orange_side[9],
                [2] = white_side[1].PPart.Color
            },
            [13] = {
                [1] = orange_side[6],
                [2] = white_side[4].PPart.Color
            },
            [14] = {
                [1] = orange_side[3],
                [2] = white_side[7].PPart.Color
            },
            [15] = {
                [1] = yellow_side[1],
                [2] = orange_side[9].PPart.Color
            },
            [16] = {
                [1] = yellow_side[4],
                [2] = orange_side[6].PPart.Color
            },
            [17] = {
                [1] = yellow_side[7],
                [2] = orange_side[3].PPart.Color
            },
            [18] = {
                [1] = red_side[1],
                [2] = yellow_side[1].PPart.Color
            },
            [19] = {
                [1] = red_side[4],
                [2] = yellow_side[4].PPart.Color
            },
            [20] = {
                [1] = red_side[7],
                [2] = yellow_side[7].PPart.Color
            }
        }
    }
    PaintTool.RF:InvokeServer(unpack(move))
end
-- Green
function moveGreen()
    local move = {
        [1] = {
            [1] = {
                [1] = green_side[1],
                [2] = green_side[7].PPart.Color
            },
            [2] = {
                [1] = green_side[2],
                [2] = green_side[4].PPart.Color
            },
            [3] = {
                [1] = green_side[3],
                [2] = green_side[1].PPart.Color
            },
            [4] = {
                [1] = green_side[4],
                [2] = green_side[8].PPart.Color
            },
            [5] = {
                [1] = green_side[6],
                [2] = green_side[2].PPart.Color
            },
            [6] = {
                [1] = green_side[7],
                [2] = green_side[9].PPart.Color
            },
            [7] = {
                [1] = green_side[8],
                [2] = green_side[6].PPart.Color
            },
            [8] = {
                [1] = green_side[9],
                [2] = green_side[3].PPart.Color
            },
            [9] = {
                [1] = yellow_side[3],
                [2] = red_side[3].PPart.Color
            },
            [10] = {
                [1] = yellow_side[6],
                [2] = red_side[6].PPart.Color
            },
            [11] = {
                [1] = yellow_side[9],
                [2] = red_side[9].PPart.Color
            },
            [12] = {
                [1] = orange_side[7],
                [2] = yellow_side[3].PPart.Color
            },
            [13] = {
                [1] = orange_side[4],
                [2] = yellow_side[6].PPart.Color
            },
            [14] = {
                [1] = orange_side[1],
                [2] = yellow_side[9].PPart.Color
            },
            [15] = {
                [1] = white_side[3],
                [2] = orange_side[7].PPart.Color
            },
            [16] = {
                [1] = white_side[6],
                [2] = orange_side[4].PPart.Color
            },
            [17] = {
                [1] = white_side[9],
                [2] = orange_side[1].PPart.Color
            },
            [18] = {
                [1] = red_side[3],
                [2] = white_side[3].PPart.Color
            },
            [19] = {
                [1] = red_side[6],
                [2] = white_side[6].PPart.Color
            },
            [20] = {
                [1] = red_side[9],
                [2] = white_side[9].PPart.Color
            }
        }
    }
    PaintTool.RF:InvokeServer(unpack(move))
end
-- Red
function moveRed()
    local move = {
        [1] = {
            [1] = {
                [1] = red_side[1],
                [2] = red_side[7].PPart.Color
            },
            [2] = {
                [1] = red_side[2],
                [2] = red_side[4].PPart.Color
            },
            [3] = {
                [1] = red_side[3],
                [2] = red_side[1].PPart.Color
            },
            [4] = {
                [1] = red_side[4],
                [2] = red_side[8].PPart.Color
            },
            [5] = {
                [1] = red_side[6],
                [2] = red_side[2].PPart.Color
            },
            [6] = {
                [1] = red_side[7],
                [2] = red_side[9].PPart.Color
            },
            [7] = {
                [1] = red_side[8],
                [2] = red_side[6].PPart.Color
            },
            [8] = {
                [1] = red_side[9],
                [2] = red_side[3].PPart.Color
            },
            [9] = {
                [1] = yellow_side[7],
                [2] = blue_side[9].PPart.Color
            },
            [10] = {
                [1] = yellow_side[8],
                [2] = blue_side[6].PPart.Color
            },
            [11] = {
                [1] = yellow_side[9],
                [2] = blue_side[3].PPart.Color
            },
            [12] = {
                [1] = green_side[1],
                [2] = yellow_side[7].PPart.Color
            },
            [13] = {
                [1] = green_side[4],
                [2] = yellow_side[8].PPart.Color
            },
            [14] = {
                [1] = green_side[7],
                [2] = yellow_side[9].PPart.Color
            },
            [15] = {
                [1] = white_side[1],
                [2] = green_side[7].PPart.Color
            },
            [16] = {
                [1] = white_side[2],
                [2] = green_side[4].PPart.Color
            },
            [17] = {
                [1] = white_side[3],
                [2] = green_side[1].PPart.Color
            },
            [18] = {
                [1] = blue_side[3],
                [2] = white_side[1].PPart.Color
            },
            [19] = {
                [1] = blue_side[6],
                [2] = white_side[2].PPart.Color
            },
            [20] = {
                [1] = blue_side[9],
                [2] = white_side[3].PPart.Color
            }
        }
    }
    PaintTool.RF:InvokeServer(unpack(move))
end
-- Orange
function moveOrange()
    local move = {
        [1] = {
            [1] = {
                [1] = orange_side[1],
                [2] = orange_side[7].PPart.Color
            },
            [2] = {
                [1] = orange_side[2],
                [2] = orange_side[4].PPart.Color
            },
            [3] = {
                [1] = orange_side[3],
                [2] = orange_side[1].PPart.Color
            },
            [4] = {
                [1] = orange_side[4],
                [2] = orange_side[8].PPart.Color
            },
            [5] = {
                [1] = orange_side[6],
                [2] = orange_side[2].PPart.Color
            },
            [6] = {
                [1] = orange_side[7],
                [2] = orange_side[9].PPart.Color
            },
            [7] = {
                [1] = orange_side[8],
                [2] = orange_side[6].PPart.Color
            },
            [8] = {
                [1] = orange_side[9],
                [2] = orange_side[3].PPart.Color
            },
            [9] = {
                [1] = yellow_side[1],
                [2] = green_side[3].PPart.Color
            },
            [10] = {
                [1] = yellow_side[2],
                [2] = green_side[6].PPart.Color
            },
            [11] = {
                [1] = yellow_side[3],
                [2] = green_side[9].PPart.Color
            },
            [12] = {
                [1] = blue_side[7],
                [2] = yellow_side[1].PPart.Color
            },
            [13] = {
                [1] = blue_side[4],
                [2] = yellow_side[2].PPart.Color
            },
            [14] = {
                [1] = blue_side[1],
                [2] = yellow_side[3].PPart.Color
            },
            [15] = {
                [1] = white_side[7],
                [2] = blue_side[1].PPart.Color
            },
            [16] = {
                [1] = white_side[8],
                [2] = blue_side[4].PPart.Color
            },
            [17] = {
                [1] = white_side[9],
                [2] = blue_side[7].PPart.Color
            },
            [18] = {
                [1] = green_side[3],
                [2] = white_side[9].PPart.Color
            },
            [19] = {
                [1] = green_side[6],
                [2] = white_side[8].PPart.Color
            },
            [20] = {
                [1] = green_side[9],
                [2] = white_side[7].PPart.Color
            }
        }
    }
    PaintTool.RF:InvokeServer(unpack(move))
end




BuildTool.RF:InvokeServer(name, amount, team, CFrame.new(0.000205+xo, 2.89998427+yo, -0.000031+zo, 0, 0, -1, 0, 1, 0, 1, 0, 0), true)
last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
last = last[#last]

local args = {
    [1] = {
        [1] = {
			[1] = last,
			[2] = Color3.new(0, 0, 0)
		}
    }
}

PaintTool.RF:InvokeServer(unpack(args))
ScaleTool.RF:InvokeServer(last, Vector3.new(5.6, 5.6, 5.6), last.PPart.CFrame)

for i, ch in pairs(white_side) do
    BuildTool.RF:InvokeServer(name, amount, team, ch, true)
    last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
    last = last[#last]
    args[1][1] = {
        [1] = last,
        [2] = Color3.new(1, 1, 1)
    }
    PaintTool.RF:InvokeServer(unpack(args))
    ScaleTool.RF:InvokeServer(last, Vector3.new(1.8, 0.2, 1.8), last.PPart.CFrame)
    white_side[i] = last
end
for i, ch in pairs(yellow_side) do
    BuildTool.RF:InvokeServer(name, amount, team, ch, true)
    last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
    last = last[#last]
    args[1][1] = {
        [1] = last,
        [2] = Color3.new(1, 1, 0)
    }
    PaintTool.RF:InvokeServer(unpack(args))
    ScaleTool.RF:InvokeServer(last, Vector3.new(1.8, 0.2, 1.8), last.PPart.CFrame)
    yellow_side[i] = last
end
for i, ch in pairs(blue_side) do
    BuildTool.RF:InvokeServer(name, amount, team, ch, true)
    last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
    last = last[#last]
    args[1][1] = {
        [1] = last,
        [2] = Color3.new(0, 0, 1)
    }
    PaintTool.RF:InvokeServer(unpack(args))
    ScaleTool.RF:InvokeServer(last, Vector3.new(0.2, 1.8, 1.8), last.PPart.CFrame)
    blue_side[i] = last
end
for i, ch in pairs(green_side) do
    BuildTool.RF:InvokeServer(name, amount, team, ch, true)
    last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
    last = last[#last]
    args[1][1] = {
        [1] = last,
        [2] = Color3.new(0, 1, 0)
    }
    PaintTool.RF:InvokeServer(unpack(args))
    ScaleTool.RF:InvokeServer(last, Vector3.new(0.2, 1.8, 1.8), last.PPart.CFrame)
    green_side[i] = last
end
for i, ch in pairs(red_side) do
    BuildTool.RF:InvokeServer(name, amount, team, ch, true)
    last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
    last = last[#last]
    args[1][1] = {
        [1] = last,
        [2] = Color3.new(1, 0, 0)
    }
    PaintTool.RF:InvokeServer(unpack(args))
    ScaleTool.RF:InvokeServer(last, Vector3.new(1.8, 1.8, 0.2), last.PPart.CFrame)
    red_side[i] = last
end
for i, ch in pairs(orange_side) do
    BuildTool.RF:InvokeServer(name, amount, team, ch, true)
    last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
    last = last[#last]
    args[1][1] = {
        [1] = last,
        [2] = Color3.new(1, 0.5, 0)
    }
    PaintTool.RF:InvokeServer(unpack(args))
    ScaleTool.RF:InvokeServer(last, Vector3.new(1.8, 1.8, 0.2), last.PPart.CFrame)
    orange_side[i] = last
end

local btn_amount = playerClass:WaitForChild("Data"):WaitForChild('Button').Value

BuildTool.RF:InvokeServer('Button', btn_amount, team, white_btn, true)
last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
last = last[#last]
local args = {[1] = {[1] = {[1] = last,[2] = Color3.new(1, 1, 1)}}}
PaintTool.RF:InvokeServer(unpack(args))
white_btn = last:WaitForChild('ClickDetector')
white_btn.MouseClick:Connect(moveWhite)

BuildTool.RF:InvokeServer('Button', btn_amount, team, yellow_btn, true)
last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
last = last[#last]
local args = {[1] = {[1] = {[1] = last,[2] = Color3.new(1, 1, 0)}}}
PaintTool.RF:InvokeServer(unpack(args))
yellow_btn = last:WaitForChild('ClickDetector')
yellow_btn.MouseClick:Connect(moveYellow)

BuildTool.RF:InvokeServer('Button', btn_amount, team, blue_btn, true)
last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
last = last[#last]
local args = {[1] = {[1] = {[1] = last,[2] = Color3.new(0, 0, 1)}}}
PaintTool.RF:InvokeServer(unpack(args))
blue_btn = last:WaitForChild('ClickDetector')
blue_btn.MouseClick:Connect(moveBlue)

BuildTool.RF:InvokeServer('Button', btn_amount, team, green_btn, true)
last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
last = last[#last]
local args = {[1] = {[1] = {[1] = last,[2] = Color3.new(0, 1, 0)}}}
PaintTool.RF:InvokeServer(unpack(args))
green_btn = last:WaitForChild('ClickDetector')
green_btn.MouseClick:Connect(moveGreen)

BuildTool.RF:InvokeServer('Button', btn_amount, team, red_btn, true)
last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
last = last[#last]
local args = {[1] = {[1] = {[1] = last,[2] = Color3.new(1, 0, 0)}}}
PaintTool.RF:InvokeServer(unpack(args))
red_btn = last:WaitForChild('ClickDetector')
red_btn.MouseClick:Connect(moveRed)

BuildTool.RF:InvokeServer('Button', btn_amount, team, orange_btn, true)
last = workspace:WaitForChild('Blocks'):WaitForChild(player):GetChildren()
last = last[#last]
local args = {[1] = {[1] = {[1] = last,[2] = Color3.new(1, 0.5, 0)}}}
PaintTool.RF:InvokeServer(unpack(args))
orange_btn = last:WaitForChild('ClickDetector')
orange_btn.MouseClick:Connect(moveOrange)