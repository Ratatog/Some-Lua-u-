-- Roblox LT2 wire art maker
print("===============================")
print("=============START=============")
print("===============================")

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

----- ART -----

--          "https://pstbn.io/raw/TdvJzWMa"
local url = "https://pstbn.io/raw/TdvJzWMa" -- url "return {{}, {}, ...}"
local filename = "" -- path "{{}, {}, ...}"

----- SETTINGS -----

-- Player --
local player = Players.LocalPlayer -- Player username "Players["..."]"

-- Wire --
local wire_type_name = "NeonWirePinky" -- Wire name

-- Scaling --
local enable_rescale = false -- Rescale
local art_scale_multiplier = 1.0 -- Size of art
local use_test_vectors = false -- Your art (in code)
local use_test_art = false -- Test art (not for user)

-- Position --
local default_position = nil -- Position of art "Vector3.new(..., ..., ...)"
local preview_anchor_position = "BottomCenterCenter" -- Instruction below
local default_art_width = nil -- Width of art
local default_art_height = nil -- Height of art

-- Circuit --
local circuit_settings = {
    enabled = false, -- Circuit mode
    wire_type_name = "Wire", -- Wire name

    show_old_wires = true, -- Show art
    build_old_wires = false, -- Build art

    endpoint_tolerance = 1e-5,
    endpoint_conductivity_distance = 0.0,
}

-- Preview --
local preview_first_wire = 1 -- First wire
local preview_last_wire = math.huge -- Last wire

-- Check mode --
local check_mode = false -- red & smaller wires

-- Incorrect wires --
local show_non_correct = true -- Show invalid wires
local build_non_correct = true -- Build invalid wires

----- CONFIGURATION -----

-- Speed --
local place_delay = 2.0 -- Building delay

-- Wire --
local wire_max_length = 20 -- Wire length
local neon_max_length = 16 -- Neon wire length
local max_lengths = {
    Wire = wire_max_length,
    WireWhite = wire_max_length,
    WireGreen = wire_max_length,
    WireRed = wire_max_length,
    WireYellow = wire_max_length,
    WireMagenta = wire_max_length,

    NeonWireWhite = neon_max_length,
    NeonWireOrange = neon_max_length,
    NeonWireBlue = neon_max_length,
    NeonWireCyan = neon_max_length,
    NeonWireGreen = neon_max_length,
    NeonWireRed = neon_max_length,
    NeonWireYellow = neon_max_length,
    NeonWireViolet = neon_max_length,
    NeonWirePinky = neon_max_length,
}

-- Check mode --
local check_reduce = 0.01 -- Reduce wire size
local check_color = Color3.fromRGB(255, 0, 0) -- Wire color

-- Incorrect wires --
local non_correct_color = Color3.fromRGB(255, 0, 0) -- Wire color

-- Scaling --
local min_scale = 1.0

-- Controls --
-- Only these two global keyboard/mouse controls remain intentionally.
-- R = rotate preview, LMB = confirm/delete preview.
local invert_horizontal_movement = true -- Invert X movement
local invert_vertical_movement = false -- Invert Y movement
local horizontal_movement_use_z = nil -- Swap X/Y movement

----- CONSTANTS -----

-- Wire --
local wire_second_name = "Box"
local wire_stats = {
    Wire = {
        line_width = 0.2,
        end_size = Vector3.new(0.16, 0.4, 0.4),
        point_size = Vector3.new(0.2, 0.2, 0.2),
        wire_color = Color3.fromRGB(27, 42, 53),
    },
    NeonWireWhite = {
        line_width = 0.35,
        end_size = Vector3.new(0.152, 0.38, 0.38),
        point_size = Vector3.new(0.35, 0.35, 0.35),
        wire_color = Color3.fromRGB(17, 17, 17),
    },
}
for _, name in ipairs({
    "NeonWireOrange",
    "NeonWireBlue",
    "NeonWireCyan",
    "NeonWireGreen",
    "NeonWireRed",
    "NeonWireYellow",
    "NeonWireViolet",
    "NeonWirePinky"
}) do
    wire_stats[name] = wire_stats.NeonWireWhite
end
for _, cwire in ipairs({
    {"WireWhite", Color3.fromRGB(91, 93, 105)},
    {"WireGreen", Color3.fromRGB(39, 70, 45)},
    {"WireRed", Color3.fromRGB(86, 36, 36)},
    {"WireYellow", Color3.fromRGB(126, 104, 63)},
    {"WireMagenta", Color3.fromRGB(89, 34, 89)}
}) do
    wire_stats[cwire[1]] = {
        line_width = wire_stats["Wire"]["line_width"],
        end_size = wire_stats["Wire"]["end_size"],
        point_size = wire_stats["Wire"]["point_size"]
    }
    wire_stats[cwire[1]]["wire_color"] = cwire[2]
end
if check_mode == true then
    for _, w in pairs(wire_stats) do
        w['line_width'] = math.max(check_reduce, w['line_width'] - check_reduce)
        w['end_size'] = Vector3.new(
            math.max(check_reduce, w['end_size'].X - check_reduce),
            math.max(check_reduce, w['end_size'].Y - check_reduce),
            math.max(check_reduce, w['end_size'].Z - check_reduce)
        )
        w['point_size'] = Vector3.new(
            math.max(check_reduce, w['point_size'].X - check_reduce),
            math.max(check_reduce, w['point_size'].Y - check_reduce),
            math.max(check_reduce, w['point_size'].Z - check_reduce)
        )
        w['wire_color'] = check_color
    end
end

-- Geometry --
local min_distance = 0.5
local turn_skip_distance = 0.1
local turn_soft_distance = 0.4
local scale_ignore_distance = 0.05 -- for rescaling (skip less values)
local eps = 1e-6
local length_eps = 1e-5
local wire_max_margin = 0

-- Build --
local ray_distance = 1000
local build_poll_interval = 0.05
local max_validation_errors = 10

-- Preview --
local preview_model_name = "WirePreview"
local player_models_name = "PlayerModels"
local preview_rotation_step = 90

-- Replicated objects --
local PlaceStructure = ReplicatedStorage:FindFirstChild("PlaceStructure")
local ClientItemInfo = ReplicatedStorage:FindFirstChild("ClientItemInfo")
local PlaceWireEvent = PlaceStructure and PlaceStructure:FindFirstChild("ClientPlacedWire")
local replicated_wires = {}

if ClientItemInfo then
    replicated_wires = {
        Wire = ClientItemInfo:FindFirstChild("Wire"),
        WireWhite = ClientItemInfo:FindFirstChild("WireWhite"),
        WireGreen = ClientItemInfo:FindFirstChild("WireGreen"),
        WireRed = ClientItemInfo:FindFirstChild("WireRed"),
        WireYellow = ClientItemInfo:FindFirstChild("WireYellow"),
        WireMagenta = ClientItemInfo:FindFirstChild("WireMagenta"),
        NeonWireWhite = ClientItemInfo:FindFirstChild("NeonWireWhite"),
        NeonWireOrange = ClientItemInfo:FindFirstChild("NeonWireOrange"),
        NeonWireBlue = ClientItemInfo:FindFirstChild("NeonWireBlue"),
        NeonWireCyan = ClientItemInfo:FindFirstChild("NeonWireCyan"),
        NeonWireGreen = ClientItemInfo:FindFirstChild("NeonWireGreen"),
        NeonWireRed = ClientItemInfo:FindFirstChild("NeonWireRed"),
        NeonWireYellow = ClientItemInfo:FindFirstChild("NeonWireYellow"),
        NeonWireViolet = ClientItemInfo:FindFirstChild("NeonWireViolet"),
        NeonWirePinky = ClientItemInfo:FindFirstChild("NeonWirePinky"),
    }
end

----- FEATURES -----

-- Instruction for preview_achor_position --
    -- Placement anchor inside the ART'S FULL VISUAL BOUNDS.
    -- X: Left / Center / Right
    -- Y: Bottom / Center / Top
    -- Z: Back / Center / Front
    --
    -- There are 3 * 3 * 3 = 27 possible positions:
    -- BottomLeftBack, BottomCenterBack, BottomRightBack
    -- BottomLeftCenter, BottomCenterCenter, BottomRightCenter
    -- BottomLeftFront, BottomCenterFront, BottomRightFront
    -- CenterLeftBack, CenterCenterBack, CenterRightBack
    -- CenterLeftCenter, CenterCenterCenter, CenterRightCenter
    -- CenterLeftFront, CenterCenterFront, CenterRightFront
    -- TopLeftBack, TopCenterBack, TopRightBack
    -- TopLeftCenter, TopCenterCenter, TopRightCenter
    -- TopLeftFront, TopCenterFront, TopRightFront
    --
    -- The current/default behavior (bottom + horizontal center) is:
    -- "BottomCenterCenter".

-- Your art --
local test_vectors = {
    {Vector3.new(-6, 1, 6),Vector3.new(-5, 1, 8),Vector3.new(-3, 1, 9),Vector3.new(-1, 1, 8),Vector3.new(0, 1, 6),Vector3.new(0, 1, 4),Vector3.new(-1, 1, 2),Vector3.new(-2, 1, 1),},{Vector3.new(-2, 1, -1),Vector3.new(-2, 1, -2),},
    {Vector3.new(3, 1, 9),Vector3.new(3, 1, 1),},{Vector3.new(3, 1, -1),Vector3.new(3, 1, -2),},
}

-- Custom art entered in the Settings tab when My art is enabled.
-- Expected format is the same Lua table returned by an art URL.
local my_art_text = ""
local original_test_vectors = test_vectors

-- Test art --
local test_art = {
    {{Vector3.new(-6, 1, 6),Vector3.new(-5, 1, 8),Vector3.new(-3, 1, 9),Vector3.new(-1, 1, 8),Vector3.new(0, 1, 6),Vector3.new(0, 1, 4),Vector3.new(-1, 1, 2),Vector3.new(-2, 1, 1),},{Vector3.new(-2, 1, -1),Vector3.new(-2, 1, -2),},},
    {{Vector3.new(3, 1, 9),Vector3.new(3, 1, 1),},{Vector3.new(3, 1, -1),Vector3.new(3, 1, -2),},},
}

-- Cleanup --
local shared_env = (type(getgenv) == "function" and getgenv()) or _G
local old_cleanup = shared_env.__WIRE_ART_CLEANUP

if type(old_cleanup) == "function" then
    pcall(old_cleanup)
end

shared_env.__WIRE_ART_CLEANUP = nil

local orphaned_preview = Workspace:FindFirstChild(preview_model_name)
if orphaned_preview then
    pcall(function()
        orphaned_preview:Destroy()
    end)
end

-- Derived config --
local player_name = player.Name
local wire_purchased_name = "Box Purchased by " .. player_name
local max_len = max_lengths[wire_type_name]

local native_warn = warn
local gui_ready = false
gui_report_log = nil
gui_report_early_log_lines = {}

-- Routes warnings to Roblox and the GUI report.
function report_warn(...)
    native_warn(...)

    local count = select("#", ...)
    local parts = {}
    for i = 1, count do
        parts[i] = tostring(select(i, ...))
    end
    local message = table.concat(parts, "\t")

    if gui_ready and type(gui_report_log) == "function" then
        local ok = pcall(gui_report_log, "[ERROR] " .. message)
        if ok then
            return
        end
    end

    table.insert(gui_report_early_log_lines, "[ERROR] " .. message)
end

if not max_len then
    report_warn("Unknown wire type: " .. tostring(wire_type_name))
    return
end

local safe_max_len = max_len - wire_max_margin
local split_safety_margin = math.max(0.0001, length_eps * 2)
local split_max_len = safe_max_len - split_safety_margin

if split_max_len < min_distance then
    report_warn("Maximum wire length is too close to minimum wire length.")
    return
end

local selected_wire_stats = wire_stats[wire_type_name] or wire_stats.Wire
local line_width = selected_wire_stats.line_width
local end_size = selected_wire_stats.end_size
local point_size = selected_wire_stats.point_size
local wire_color = selected_wire_stats.wire_color

local ReplicatedWire = replicated_wires[wire_type_name]

local active_wire_type_name = wire_type_name
local active_wire_purchased_name = "Box Purchased by " .. player_name

-- Sets the active player and updates player-dependent values.
function set_active_player(selected)
    if typeof(selected) ~= "Instance" or not selected:IsA("Player") then
        return false, "Invalid player"
    end
    if selected.Parent ~= Players then
        return false, "Selected player is no longer in Players"
    end

    player = selected
    player_name = player.Name
    wire_purchased_name = "Box Purchased by " .. player_name
    active_wire_purchased_name = "Box Purchased by " .. player_name

    return true
end

local vectors = {}
local generated_art = {}
local placement_reference_art = nil
local circuit_source_art = nil
local circuit_report = nil
local art = {}
local pipeline_report = nil
local preview_model = nil
local preview_position = Vector3.zero
local preview_rotation = 0
local preview_placing = false
local preview_connection = nil
local preview_anchor = Vector3.zero
local preview_mouse_offset = Vector3.zero
local preview_using_default_position = false
local preview_touch_input = nil
local preview_touch_position = nil
local build_running = false
local build_cancelled = false
local build_connection = nil
local main_inputs = nil
local generated_wire_entries = {}
local current_preview_report = nil
local preview_locked = false
local deletion_mode = false
local deleted_wire_numbers = {}
local deleted_wire_refs = {}
local wire_number_by_table = {}
local preview_wire_models = {}

-- Checks whether the mouse is currently over the GUI.
gui_mouse_over_ui = function() return false end

-- Sets the current GUI status message.
gui_set_status = function() end

-- Updates the GUI position and placement state.
gui_update_position = function() end

-- Resets the GUI build report and output.
gui_report_reset = function() end

-- Appends a message to the GUI build output.
gui_report_log = function() end

-- Updates the GUI report state text.
gui_report_set_state = function() end

-- Stores the current preview range as the report baseline.
gui_report_set_range_baseline = function() end

-- Starts the GUI build timer and report state.
gui_report_build_start = function() end

-- Stops the GUI build timer.
gui_report_build_finish = function() end

-- Destroys the GUI and disconnects its connections.
destroy_gui = function() end

local ArtPipeline = {}
local CircuitBuilder = {}

local art_local_x_axis = Vector3.xAxis
local art_local_x_axis_name = "world X"
local art_local_x_span = 0
local art_height_axis = Vector3.yAxis
local art_height_axis_name = "world Y"
local art_height_span = 0

local anchor_x_values = {Left = -1, Center = 0, Right = 1}
local anchor_y_values = {Bottom = -1, Center = 0, Top = 1}
local anchor_z_values = {Back = -1, Center = 0, Front = 1}

connect_main_inputs = nil
build_art = nil
shutdown = nil

-- Stops the script, cleans up runtime state, and destroys the GUI.
shutdown = function()
    cleanup_all(true, true)
    destroy_gui()
end

shared_env.__WIRE_ART_CLEANUP = shutdown

-- Finds the player's purchased wire boxes for a specific type.
function get_boxes_for_type(type_name)
    local boxes = {}
    local player_models = Workspace:FindFirstChild(player_models_name)
    if not player_models then
        return boxes
    end

    local value = tostring(type_name or "")
    for _, object in ipairs(player_models:GetChildren()) do
        local correct_name = (
            object.Name == value
            or object.Name == ("Box Purchased by " .. player_name)
            or object.Name == wire_second_name
        )
        if not correct_name then
            continue
        end

        local owner = object:FindFirstChild("Owner")
        local purchased = object:FindFirstChild("PurchasedBoxItemName")
        if owner and owner.Value and owner.Value.Name == player_name and purchased and purchased.Value == value then
            table.insert(boxes, object)
        end
    end

    return boxes
end

-- Activates a wire type and updates its limits, visuals, and replicated object.
function set_active_wire_type(type_name)
    local value = tostring(type_name or "")
    local selected_max = max_lengths[value]
    if not selected_max then
        return false, "Unknown wire type: " .. value
    end

    local selected_replicated = replicated_wires[value]
    if not selected_replicated then
        return false, "Replicated wire object not found for: " .. value
    end

    local selected_stats = wire_stats[value] or wire_stats.Wire

    active_wire_type_name = value
    active_wire_purchased_name = "Box Purchased by " .. player_name
    max_len = selected_max
    safe_max_len = max_len - wire_max_margin
    split_max_len = safe_max_len - split_safety_margin

    if split_max_len < min_distance then
        return false, "Maximum wire length for " .. value .. " is too close to minimum wire length."
    end

    selected_wire_stats = selected_stats
    line_width = selected_stats.line_width
    end_size = selected_stats.end_size
    point_size = selected_stats.point_size
    wire_color = selected_stats.wire_color
    ReplicatedWire = selected_replicated
    wire_purchased_name = "Box Purchased by " .. player_name

    return true
end

-- Safely disconnects an event connection if it exists.
function safe_disconnect(connection)
    if not connection then
        return
    end
    if type(connection) == "table" then
        for _, item in ipairs(connection) do
            safe_disconnect(item)
        end
        return
    end
    pcall(function()
        connection:Disconnect()
    end)
end

-- Resets build and preview state and optionally removes the preview.
function cleanup_all(destroy_preview, unregister)
    preview_placing = false
    safe_disconnect(preview_connection)
    preview_connection = nil
    safe_disconnect(build_connection)
    build_connection = nil
    safe_disconnect(main_inputs)
    main_inputs = nil
    build_running = false
    build_cancelled = false
    preview_locked = false
    deletion_mode = false
    deleted_wire_numbers = {}
    deleted_wire_refs = {}
    preview_wire_models = {}
    if destroy_preview then
        if preview_model then
            pcall(function()
                preview_model:Destroy()
            end)
            preview_model = nil
        end
        local old_preview = Workspace:FindFirstChild(preview_model_name)
        if old_preview then
            pcall(function()
                old_preview:Destroy()
            end)
        end
        preview_position = Vector3.zero
        preview_rotation = 0
        preview_anchor = Vector3.zero
        preview_using_default_position = false
        preview_mouse_offset = Vector3.zero
        preview_touch_input = nil
        preview_touch_position = nil
    end
    if unregister then
        if shared_env.__WIRE_ART_CLEANUP == shutdown then
            shared_env.__WIRE_ART_CLEANUP = nil
        end
    end
end

-- Parses custom art entered in the GUI.
function parse_my_art_source()
    local source = tostring(my_art_text or "")
    if source:match("^%s*$") then
        return test_vectors
    end

    source = source:gsub("^%s*return%s+", "", 1)

    local loader, compile_error = loadstring("return " .. source)
    if not loader then
        error("My art could not be compiled: " .. tostring(compile_error))
    end

    local value = loader()
    if type(value) ~= "table" then
        error("My art must evaluate to a table.")
    end

    return value
end

-- Loads vector art from the configured URL, file, or test source.
function load_vectors()
    local result
    if use_test_vectors then
        local ok, value = pcall(parse_my_art_source)
        if not ok then
            report_warn("Failed to load My art:")
            report_warn(value)
            return {}
        end
        result = value
    elseif #url > 0 then
        local ok, value = pcall(function()
            local source = game:HttpGet(url)
            local loader = loadstring(source)
            if not loader then
                error("loadstring returned nil.")
            end
            return loader()
        end)
        if not ok then
            report_warn("Failed to load art from URL:")
            report_warn(value)
            return {}
        end
        result = value
    elseif #filename > 0 then
        local ok, value = pcall(function()
            local content = readfile(filename)
            return HttpService:JSONDecode(content)
        end)
        if not ok then
            report_warn("Failed to load art from file:")
            report_warn(value)
            return {}
        end
        result = value
    else
        report_warn("Neither URL nor filename is configured.")
        return {}
    end
    if type(result) ~= "table" then
        report_warn("Loaded source is not a table.")
        return {}
    end
    return result
end

-- Clamps a value to a valid range and rejects invalid ranges.
function clamp_value(value, minimum, maximum)
    if minimum > maximum then
        return nil
    end
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

-- Cleans art data by removing malformed values and consecutive duplicates.
function ArtPipeline.filter(source_vectors)
    local result = {}
    if type(source_vectors) ~= "table" then
        return result
    end
    for list_index, list in ipairs(source_vectors) do
        if type(list) ~= "table" then
            report_warn("Skipping invalid vector list #" .. tostring(list_index))
            continue
        end
        local points = {}
        for _, point in ipairs(list) do
            if typeof(point) == "Vector3" then
                table.insert(points, point)
            end
        end
        if #points < 2 then
            continue
        end
        local cleaned = {points[1]}
        for i = 2, #points do
            local previous = cleaned[#cleaned]
            if (points[i] - previous).Magnitude > eps then
                table.insert(cleaned, points[i])
            end
        end
        if #cleaned >= 2 then
            table.insert(result, cleaned)
        end
    end
    return result
end

-- Calculates the total length of a polyline.
function ArtPipeline.get_total_length(points)
    if type(points) ~= "table" then
        return 0
    end
    local total = 0
    for i = 2, #points do
        total += (points[i] - points[i - 1]).Magnitude
    end
    return total
end

-- Removes consecutive duplicate points from a polyline.
function remove_duplicate_points(points)
    if #points <= 1 then
        return points
    end

    local result = {points[1]}
    for i = 2, #points do
        if (points[i] - result[#result]).Magnitude > eps then
            table.insert(result, points[i])
        end
    end
    return result
end

-- Solves the positional shift needed to repair a short turn.
function solve_shift(base, direction, target_distance, max_shift)
    local direction_length_squared = direction:Dot(direction)
    if direction_length_squared <= eps then
        return nil
    end

    local a = direction_length_squared
    local b = 2 * base:Dot(direction)
    local c = base:Dot(base) - target_distance * target_distance
    local discriminant = b * b - 4 * a * c

    if discriminant < -length_eps then
        return nil
    end

    discriminant = math.max(discriminant, 0)

    local root = math.sqrt(discriminant)
    local t1 = (-b - root) / (2 * a)
    local t2 = (-b + root) / (2 * a)
    local best = math.huge

    if t1 >= -length_eps then
        best = math.min(best, math.max(t1, 0))
    end
    if t2 >= -length_eps then
        best = math.min(best, math.max(t2, 0))
    end

    if best == math.huge or best > max_shift + length_eps then
        return nil
    end

    return best
end

-- Finds a better local shift for repairing a short segment.
function get_improved_shift(base, direction, max_shift, current_distance)
    if max_shift <= eps then
        return nil
    end

    local candidate = base + direction * max_shift
    local new_distance = candidate.Magnitude

    if new_distance > current_distance + length_eps and new_distance < min_distance - length_eps then
        return max_shift
    end

    return nil
end

-- Repairs a pair of short segments around a turn.
function fix_turn_pair_points(points, index, force_minimum)
    if index <= 1 or index + 2 > #points then
        return false
    end

    local p0, p1 = points[index - 1], points[index]
    local p2, p3 = points[index + 1], points[index + 2]
    local current_distance = (p2 - p1).Magnitude

    if current_distance >= min_distance - length_eps then
        return false
    end

    if not force_minimum and current_distance >= turn_soft_distance - length_eps then
        return false
    end

    if current_distance < turn_skip_distance - length_eps then
        table.remove(points, index)
        return true
    end

    local before, after = p1 - p0, p3 - p2
    if before.Magnitude <= eps or after.Magnitude <= eps then
        return false
    end

    local dir_before, dir_after = before.Unit, after.Unit
    local previous_slack = math.max(0, before.Magnitude - min_distance)
    local next_slack = math.max(0, after.Magnitude - min_distance)
    local base = p2 - p1

    local both_direction = dir_before + dir_after
    if both_direction.Magnitude > eps then
        local max_shift = math.min(previous_slack, next_slack)
        local exact_shift = solve_shift(base, both_direction, min_distance, max_shift)

        if exact_shift then
            points[index] = p1 - dir_before * exact_shift
            points[index + 1] = p2 + dir_after * exact_shift
            return true
        end

        local partial_shift = get_improved_shift(base, both_direction, max_shift, current_distance)
        if partial_shift then
            points[index] = p1 - dir_before * partial_shift
            points[index + 1] = p2 + dir_after * partial_shift
            return true
        end
    end

    if previous_slack > eps then
        local exact_shift = solve_shift(base, dir_before, min_distance, previous_slack)
        if exact_shift then
            points[index] = p1 - dir_before * exact_shift
            return true
        end

        local partial_shift = get_improved_shift(base, dir_before, previous_slack, current_distance)
        if partial_shift then
            points[index] = p1 - dir_before * partial_shift
            return true
        end
    end

    if next_slack > eps then
        local exact_shift = solve_shift(base, dir_after, min_distance, next_slack)
        if exact_shift then
            points[index + 1] = p2 + dir_after * exact_shift
            return true
        end

        local partial_shift = get_improved_shift(base, dir_after, next_slack, current_distance)
        if partial_shift then
            points[index + 1] = p2 + dir_after * partial_shift
            return true
        end
    end

    return false
end

-- Repairs all short interior turn segments in a polyline.
function fix_turns_points(points, force_minimum)
    local changed_any = false
    local i = 2

    while i < #points - 1 do
        local changed = fix_turn_pair_points(points, i, force_minimum)

        if changed then
            changed_any = true
            if i > 2 then
                i -= 1
            end
        else
            i += 1
        end
    end

    return changed_any
end

-- Repairs short segments at the start and end of a polyline.
function fix_end_distances_points(points)
    local changed_any = false

    while #points >= 2 do
        local distance = (points[2] - points[1]).Magnitude

        if distance < turn_skip_distance - length_eps then
            table.remove(points, 1)
            changed_any = true
        elseif distance < min_distance - length_eps then
            local direction = (points[1] - points[2]).Unit
            points[1] = points[2] + direction * min_distance
            changed_any = true
            break
        else
            break
        end
    end

    while #points >= 2 do
        local last = #points
        local distance = (points[last] - points[last - 1]).Magnitude

        if distance < turn_skip_distance - length_eps then
            table.remove(points, last)
            changed_any = true
        elseif distance < min_distance - length_eps then
            local direction = (points[last] - points[last - 1]).Unit
            points[last] = points[last - 1] + direction * min_distance
            changed_any = true
            break
        else
            break
        end
    end

    return changed_any
end

-- Normalizes one polyline while preserving its usable geometry.
function normalize_points(source_points)
    local points = {}

    for _, point in ipairs(source_points) do
        table.insert(points, point)
    end

    if #points < 2 then
        return {}
    end

    for _ = 1, 20 do
        if #points < 2 then
            break
        end

        local before_count = #points
        local changed_turns = fix_turns_points(points, false)

        if #points < 2 then
            break
        end

        local changed_ends = fix_end_distances_points(points)

        if #points < 2 then
            break
        end

        points = remove_duplicate_points(points)

        if not changed_turns and not changed_ends and #points == before_count then
            break
        end
    end

    for _ = 1, 20 do
        if #points < 2 then
            break
        end

        local changed_turns = fix_turns_points(points, true)
        local changed_ends = fix_end_distances_points(points)
        points = remove_duplicate_points(points)

        if not changed_turns and not changed_ends then
            break
        end
    end

    return points
end

-- Normalizes every polyline in the art.
function ArtPipeline.normalize(source_vectors)
    local result = {}

    if type(source_vectors) ~= "table" then
        return result
    end

    for _, list in ipairs(source_vectors) do
        if type(list) ~= "table" then
            continue
        end

        local points = normalize_points(list)
        if #points >= 2 then
            table.insert(result, points)
        end
    end

    return result
end

-- Calculates the scale-ignore threshold effective for the current art.
function get_effective_scale_ignore()
    local value = tonumber(scale_ignore_distance) or 0
    return math.min(math.max(value, 0), turn_skip_distance - length_eps)
end

-- Finds the minimum meaningful segment length in one-level vector data.
function ArtPipeline.get_min_distance(source_vectors)
    local min_found = math.huge
    local ignore = get_effective_scale_ignore()

    for _, list in ipairs(source_vectors or {}) do
        if type(list) == "table" then
            for i = 2, #list do
                if typeof(list[i]) == "Vector3" and typeof(list[i - 1]) == "Vector3" then
                    local distance = (list[i] - list[i - 1]).Magnitude
                    if distance >= ignore and distance < min_found then
                        min_found = distance
                    end
                end
            end
        end
    end

    return min_found
end

-- Finds the minimum meaningful segment length in two-level art data.
function ArtPipeline.get_art_min_distance(source_art)
    local min_found = math.huge
    local ignore = get_effective_scale_ignore()

    for _, mini_art in ipairs(source_art or {}) do
        if type(mini_art) == "table" then
            for _, wire in ipairs(mini_art) do
                if type(wire) == "table" then
                    for i = 2, #wire do
                        if typeof(wire[i]) == "Vector3" and typeof(wire[i - 1]) == "Vector3" then
                            local distance = (wire[i] - wire[i - 1]).Magnitude
                            if distance >= ignore and distance < min_found then
                                min_found = distance
                            end
                        end
                    end
                end
            end
        end
    end

    return min_found
end

-- Calculates the geometric center of the art.
function get_art_center(source_vectors)
    local min_x, min_y, min_z = math.huge, math.huge, math.huge
    local max_x, max_y, max_z = -math.huge, -math.huge, -math.huge
    local found = false

    for _, list in ipairs(source_vectors) do
        for _, point in ipairs(list) do
            found = true
            min_x, min_y, min_z = math.min(min_x, point.X), math.min(min_y, point.Y), math.min(min_z, point.Z)
            max_x, max_y, max_z = math.max(max_x, point.X), math.max(max_y, point.Y), math.max(max_z, point.Z)
        end
    end

    if not found then
        return Vector3.zero
    end

    return Vector3.new((min_x + max_x) / 2, (min_y + max_y) / 2, (min_z + max_z) / 2)
end

-- Calculates the minimum and maximum coordinates of the art points.
function get_art_point_bounds(source_art)
    local min_x, min_y, min_z = math.huge, math.huge, math.huge
    local max_x, max_y, max_z = -math.huge, -math.huge, -math.huge
    local total_dx, total_dy, total_dz = 0, 0, 0
    local found = false

    for _, mini_art in ipairs(source_art or {}) do
        if type(mini_art) == "table" then
            for _, wire in ipairs(mini_art) do
                if type(wire) == "table" then
                    local previous = nil

                    for _, point in ipairs(wire) do
                        if typeof(point) == "Vector3" then
                            found = true

                            min_x = math.min(min_x, point.X)
                            min_y = math.min(min_y, point.Y)
                            min_z = math.min(min_z, point.Z)
                            max_x = math.max(max_x, point.X)
                            max_y = math.max(max_y, point.Y)
                            max_z = math.max(max_z, point.Z)

                            if previous then
                                total_dx += math.abs(point.X - previous.X)
                                total_dy += math.abs(point.Y - previous.Y)
                                total_dz += math.abs(point.Z - previous.Z)
                            end

                            previous = point
                        end
                    end
                end
            end
        end
    end

    if not found then
        return nil
    end

    return {
        min = Vector3.new(min_x, min_y, min_z),
        max = Vector3.new(max_x, max_y, max_z),
        span = Vector3.new(max_x - min_x, max_y - min_y, max_z - min_z),
        travel = Vector3.new(total_dx, total_dy, total_dz),
    }
end

-- Detects the local axes used by the 2D art.
function detect_art_local_axes(source_art)
    local bounds = get_art_point_bounds(source_art)

    if not bounds then
        art_local_x_axis = Vector3.xAxis
        art_local_x_axis_name = "world X"
        art_local_x_span = 0
        art_height_axis = Vector3.yAxis
        art_height_axis_name = "world Y"
        art_height_span = 0
        return nil
    end

    local span_x = bounds.span.X
    local span_y = bounds.span.Y
    local span_z = bounds.span.Z
    local travel_x = bounds.travel.X
    local travel_z = bounds.travel.Z

    local force_use_z = nil
    if horizontal_movement_use_z ~= nil then
        force_use_z = horizontal_movement_use_z == true
    end

    local use_z
    if force_use_z ~= nil then
        use_z = force_use_z
    elseif span_x <= eps and span_z > eps then
        use_z = true
    elseif span_z <= eps and span_x > eps then
        use_z = false
    elseif travel_z > travel_x + length_eps then
        use_z = true
    elseif travel_x > travel_z + length_eps then
        use_z = false
    elseif span_z > span_x + length_eps then
        use_z = true
    else
        use_z = false
    end

    if use_z then
        art_local_x_axis = Vector3.zAxis
        art_local_x_axis_name = "world Z"
        art_local_x_span = span_z
    else
        art_local_x_axis = Vector3.xAxis
        art_local_x_axis_name = "world X"
        art_local_x_span = span_x
    end

    art_height_axis = Vector3.yAxis
    art_height_axis_name = "world Y"
    art_height_span = span_y

    return bounds
end

-- Calculates the art width and height along its detected axes.
function get_art_size(source_art)
    local bounds = detect_art_local_axes(source_art)
    if not bounds then
        return Vector3.zero
    end

    return Vector3.new(art_local_x_span, art_height_span, 0)
end

-- Calculates the scale factor needed to fit the art to the target size.
function ArtPipeline.get_scale_factor(source_vectors)
    local automatic_scale = min_scale

    if enable_rescale then
        local minimum = ArtPipeline.get_min_distance(source_vectors)

        if minimum ~= math.huge and minimum < min_distance - length_eps then
            automatic_scale = min_distance / minimum
        end
    end

    return math.max(min_scale, automatic_scale, art_scale_multiplier)
end

-- Scales one-level vector data by a factor around its center.
function ArtPipeline.scale_vectors(source_vectors, scale, center)
    if math.abs(scale - 1) <= eps then
        return source_vectors
    end

    center = center or get_art_center(source_vectors)

    local result = {}

    for _, list in ipairs(source_vectors) do
        local result_list = {}

        for _, point in ipairs(list) do
            table.insert(result_list, center + (point - center) * scale)
        end

        table.insert(result, result_list)
    end

    return result
end

-- Scales two-level art by a factor around its center.
function ArtPipeline.scale_art(source_art, scale, center)
    if math.abs(scale - 1) <= eps then
        return source_art
    end

    center = center or get_art_center(source_art)

    local result = {}

    for _, mini_art in ipairs(source_art) do
        local result_mini_art = {}

        for _, wire in ipairs(mini_art) do
            local result_wire = {}

            for _, point in ipairs(wire) do
                table.insert(result_wire, center + (point - center) * scale)
            end

            table.insert(result_mini_art, result_wire)
        end

        table.insert(result, result_mini_art)
    end

    return result
end

-- Rescales the art before normalization and splitting.
function ArtPipeline.rescale(source_vectors)
    local minimum = ArtPipeline.get_min_distance(source_vectors)
    local scale = ArtPipeline.get_scale_factor(source_vectors)
    local center = get_art_center(source_vectors)
    local report = {
        enabled = enable_rescale,
        applied = scale > min_scale + length_eps,
        minimum_before = minimum,
        scale = scale,
        center = center
    }

    ArtPipeline.rescale_report = report

    print("========== ART SCALE ==========")
    print("Enabled:", enable_rescale)

    if minimum == math.huge then
        print("Minimum distance: none")
    else
        print("Minimum distance:", minimum)
    end

    print("Scale:", scale)
    print(report.applied and "Global scaling applied." or "Global scaling not required.")
    print("================================")

    if scale <= min_scale + eps then
        return source_vectors, report
    end

    return ArtPipeline.scale_vectors(source_vectors, scale, center), report
end

-- Builds balanced legal chunk lengths for a total distance.
function make_balanced_chunk_lengths(total_length, count)
    if count < 1 then
        return {}
    end

    local result = {}
    local base_length = total_length / count

    for i = 1, count - 1 do
        table.insert(result, base_length)
    end

    table.insert(result, total_length - base_length * (count - 1))
    return result
end

-- Calculates the chunk lengths needed along a polyline.
function ArtPipeline.get_chunk_lengths(total_length, minimum_length, maximum_length)
    minimum_length = minimum_length or min_distance
    maximum_length = maximum_length or split_max_len

    if maximum_length < minimum_length - length_eps or total_length < minimum_length - length_eps then
        return {}
    end

    local count = math.max(1, math.ceil(total_length / maximum_length))

    while count > 1 and total_length / count < minimum_length - length_eps do
        count -= 1
    end

    return make_balanced_chunk_lengths(total_length, count)
end

-- Builds cumulative segment lengths for a polyline.
function get_cumulative_lengths(points)
    local cumulative = {[1] = 0}

    for i = 2, #points do
        cumulative[i] = cumulative[i - 1] + (points[i] - points[i - 1]).Magnitude
    end

    return cumulative
end

-- Returns the point located at a given distance along a polyline.
function get_point_at_distance(points, cumulative, distance)
    local total = cumulative[#cumulative]

    if distance <= 0 then
        return points[1]
    end

    if distance >= total then
        return points[#points]
    end

    local low, high = 2, #points

    while low <= high do
        local middle = math.floor((low + high) / 2)

        if cumulative[middle] < distance then
            low = middle + 1
        else
            high = middle - 1
        end
    end

    local index = clamp_value(low, 2, #points)
    if not index then
        return points[#points]
    end

    if math.abs(distance - cumulative[index]) <= length_eps then
        return points[index]
    end

    if math.abs(distance - cumulative[index - 1]) <= length_eps then
        return points[index - 1]
    end

    local start_distance = cumulative[index - 1]
    local end_distance = cumulative[index]
    local segment_length = end_distance - start_distance

    if segment_length <= eps then
        return points[index]
    end

    local alpha = clamp_value((distance - start_distance) / segment_length, 0, 1)
    return points[index - 1]:Lerp(points[index], alpha)
end

-- Finds the distances along a polyline where its turns occur.
function get_turn_positions(points, cumulative)
    local result = {}

    for i = 2, #points - 1 do
        table.insert(result, cumulative[i])
    end

    return result
end

-- Checks whether a proposed split position is safely placed.
function is_cut_position_valid(position, turn_positions)
    for _, turn_position in ipairs(turn_positions) do
        local distance = math.abs(position - turn_position)

        if distance > length_eps and distance < min_distance - length_eps then
            return false
        end
    end

    return true
end

-- Chooses the nearest valid split position to a desired boundary.
function choose_cut_position(nominal, minimum_position, maximum_position, turn_positions)
    if maximum_position < minimum_position - length_eps then
        return nil
    end

    if maximum_position < minimum_position then
        local fixed = (minimum_position + maximum_position) / 2
        minimum_position, maximum_position = fixed, fixed
    end

    local candidates = {}

    local function add_candidate(value)
        if value == nil then
            return
        end

        local position = clamp_value(value, minimum_position, maximum_position)
        if position ~= nil then
            table.insert(candidates, position)
        end
    end

    add_candidate(nominal)
    add_candidate(minimum_position)
    add_candidate(maximum_position)

    for _, turn_position in ipairs(turn_positions) do
        if turn_position >= minimum_position - length_eps and turn_position <= maximum_position + length_eps then
            add_candidate(turn_position)
        end

        if turn_position - min_distance >= minimum_position - length_eps and turn_position - min_distance <= maximum_position + length_eps then
            add_candidate(turn_position - min_distance)
        end

        if turn_position + min_distance >= minimum_position - length_eps and turn_position + min_distance <= maximum_position + length_eps then
            add_candidate(turn_position + min_distance)
        end
    end

    table.sort(candidates, function(a, b)
        return math.abs(a - nominal) < math.abs(b - nominal)
    end)

    local unique = {}

    for _, candidate in ipairs(candidates) do
        local duplicate = false

        for _, existing in ipairs(unique) do
            if math.abs(candidate - existing) <= length_eps then
                duplicate = true
                break
            end
        end

        if not duplicate then
            table.insert(unique, candidate)
        end
    end

    for _, candidate in ipairs(unique) do
        if is_cut_position_valid(candidate, turn_positions) then
            return candidate
        end
    end

    return nil
end

-- Builds a wire piece between two distances along a polyline.
function build_wire_between(points, cumulative, start_distance, end_distance)
    local wire = {get_point_at_distance(points, cumulative, start_distance)}

    for i = 2, #points - 1 do
        if cumulative[i] > start_distance + length_eps and cumulative[i] < end_distance - length_eps then
            table.insert(wire, points[i])
        end
    end

    local end_point = get_point_at_distance(points, cumulative, end_distance)

    if (end_point - wire[#wire]).Magnitude > eps then
        table.insert(wire, end_point)
    end

    return wire
end

-- Validates one generated wire piece before returning it.
function validate_split_piece(wire, minimum_piece, maximum_piece)
    if #wire < 2 then
        return false
    end

    local total = 0
    local minimum_segment = math.huge

    for i = 2, #wire do
        local distance = (wire[i] - wire[i - 1]).Magnitude
        total += distance
        minimum_segment = math.min(minimum_segment, distance)
    end

    return
        total >= minimum_piece - length_eps
        and total <= maximum_piece + length_eps
        and minimum_segment >= min_distance - length_eps
end

-- Splits one polyline into legal wire pieces.
function split_points(points, chunk_lengths, minimum_piece, maximum_piece)
    if #points < 2 or #chunk_lengths == 0 then
        return nil
    end

    local cumulative = get_cumulative_lengths(points)
    local total = cumulative[#cumulative]
    local turn_positions = get_turn_positions(points, cumulative)
    local boundaries = {0}
    local nominal = 0

    for chunk_index = 1, #chunk_lengths - 1 do
        nominal += chunk_lengths[chunk_index]

        local previous_boundary = boundaries[#boundaries]
        local remaining_chunks = #chunk_lengths - chunk_index

        local minimum_position = math.max(
            previous_boundary + minimum_piece,
            total - remaining_chunks * maximum_piece
        )

        local maximum_position = math.min(
            previous_boundary + maximum_piece,
            total - remaining_chunks * minimum_piece
        )

        local cut = choose_cut_position(
            nominal,
            minimum_position,
            maximum_position,
            turn_positions
        )

        if cut == nil then
            return nil
        end

        table.insert(boundaries, cut)
    end

    table.insert(boundaries, total)

    local result = {}

    for i = 1, #boundaries - 1 do
        local wire = build_wire_between(
            points,
            cumulative,
            boundaries[i],
            boundaries[i + 1]
        )

        if not validate_split_piece(wire, minimum_piece, maximum_piece) then
            return nil
        end

        table.insert(result, wire)
    end

    return result
end

-- Splits every polyline in the art into legal wires.
function ArtPipeline.split(source_vectors, minimum_piece, maximum_piece)
    minimum_piece = minimum_piece or min_distance
    maximum_piece = maximum_piece or split_max_len

    local result = {}
    local report = {
        source_lists = #source_vectors,
        too_short_lists = 0,
        split_failed_lists = 0,
        extra_piece_splits = 0
    }

    for list_index, points in ipairs(source_vectors) do
        if #points < 2 then
            report.too_short_lists += 1
            continue
        end

        local total_length = ArtPipeline.get_total_length(points)

        if total_length < minimum_piece - length_eps then
            report.too_short_lists += 1
            continue
        end

        local minimum_count = math.max(1, math.ceil(total_length / maximum_piece))
        local maximum_count = math.floor(total_length / minimum_piece + length_eps)
        local wires = nil
        local used_count = nil

        if maximum_count >= minimum_count then
            for count = minimum_count, maximum_count do
                local chunk_lengths = make_balanced_chunk_lengths(total_length, count)

                wires = split_points(
                    points,
                    chunk_lengths,
                    minimum_piece,
                    maximum_piece
                )

                if wires then
                    used_count = count
                    break
                end
            end
        end

        if not wires then
            report.split_failed_lists += 1
            report_warn("Mini-art #" .. tostring(list_index) .. ": split failed; source preserved.")
            table.insert(result, {points})
        else
            if used_count > minimum_count then
                report.extra_piece_splits += 1
            end

            table.insert(result, wires)
        end
    end

    return result, report
end

-- Counts all wires contained in the art.
function ArtPipeline.count_wires(source_art)
    local count = 0
    if type(source_art) ~= "table" then
        return 0
    end
    for _, mini_art in ipairs(source_art) do
        if type(mini_art) == "table" then
            count += #mini_art
        end
    end
    return count
end

-- Inspects one wire and reports its geometry validity and lengths.
function inspect_wire(wire)
    local info = {valid = true, malformed = false, too_short = false, too_long = false, total_length = 0, min_segment = math.huge}
    if type(wire) ~= "table" or #wire < 2 then
        info.valid = false
        info.malformed = true
        return info
    end
    for i = 2, #wire do
        local value = wire[i]
        local previous = wire[i - 1]
        if typeof(value) ~= "Vector3" or typeof(previous) ~= "Vector3" then
            info.valid = false
            info.malformed = true
            return info
        end
        local distance = (value - previous).Magnitude
        info.total_length += distance
        info.min_segment = math.min(info.min_segment, distance)
    end
    if info.total_length < min_distance - length_eps then
        info.valid = false
        info.too_short = true
    end
    if info.total_length > safe_max_len + length_eps then
        info.valid = false
        info.too_long = true
    end
    if info.min_segment < min_distance - length_eps then
        info.valid = false
        info.too_short = true
    end
    return info
end

-- Validates a wire using the limits of a specific wire type.
function inspect_wire_for_type(wire, type_name)
    local maximum = max_lengths[type_name]
    if not maximum then
        return {valid = false, malformed = true, too_short = false, too_long = false, total_length = 0, min_segment = math.huge}
    end

    local safe_maximum = maximum - wire_max_margin
    local info = {
        valid = true,
        malformed = false,
        too_short = false,
        too_long = false,
        total_length = 0,
        min_segment = math.huge,
    }

    if type(wire) ~= "table" or #wire < 2 then
        info.valid = false
        info.malformed = true
        return info
    end

    for i = 2, #wire do
        local value = wire[i]
        local previous = wire[i - 1]
        if typeof(value) ~= "Vector3" or typeof(previous) ~= "Vector3" then
            info.valid = false
            info.malformed = true
            return info
        end

        local distance = (value - previous).Magnitude
        info.total_length += distance
        info.min_segment = math.min(info.min_segment, distance)
    end

    if info.total_length < min_distance - length_eps then
        info.valid = false
        info.too_short = true
    end

    if info.total_length > safe_maximum + length_eps then
        info.valid = false
        info.too_long = true
    end

    if info.min_segment < min_distance - length_eps then
        info.valid = false
        info.too_short = true
    end

    return info
end

-- Validates generated art and collects all validation errors.
function ArtPipeline.validate(source_art)
    local report = {total = 0, valid = 0, invalid = 0, short = 0, too_long = 0, malformed = 0, errors = {}}
    for mini_index, mini_art in ipairs(source_art) do
        for wire_index, wire in ipairs(mini_art) do
            report.total += 1
            local info = inspect_wire(wire)
            if info.valid then
                report.valid += 1
            else
                report.invalid += 1
                if info.too_short then
                    report.short += 1
                end
                if info.too_long then
                    report.too_long += 1
                end
                if info.malformed then
                    report.malformed += 1
                end
                table.insert(report.errors,
                    "Mini-art " .. tostring(mini_index) .. ", wire " .. tostring(wire_index).. ", global " .. tostring(report.total)
                    .. ": total=" .. tostring(info.total_length) .. ", min_segment=" .. tostring(info.min_segment))
            end
        end
    end
    return report
end

-- Copies a Vector3 into a new Vector3 value.
function circuit_copy_vector3(value)
    return Vector3.new(value.X, value.Y, value.Z)
end

-- Creates the disjoint-set structure used to merge circuit components.
function circuit_make_union_find(count)
    local parent = {}
    local rank = {}
    for i = 1, count do
        parent[i] = i
        rank[i] = 0
    end

    local function find(value)
        local root = value
        while parent[root] ~= root do
            root = parent[root]
        end
        while parent[value] ~= value do
            local next_value = parent[value]
            parent[value] = root
            value = next_value
        end
        return root
    end

    local function union(a, b)
        local root_a = find(a)
        local root_b = find(b)
        if root_a == root_b then
            return false
        end
        if rank[root_a] < rank[root_b] then
            root_a, root_b = root_b, root_a
        end
        parent[root_b] = root_a
        if rank[root_a] == rank[root_b] then
            rank[root_a] += 1
        end
        return true
    end

    return find, union
end

-- Calculates the Euclidean distance between two points.
function circuit_distance(a, b)
    return (b - a).Magnitude
end

-- Calculates the distance between two axis-aligned bounding boxes.
function circuit_bbox_distance(a_min, a_max, b_min, b_max)
    local function axis_distance(a0, a1, b0, b1)
        if a1 < b0 then
            return b0 - a1
        elseif b1 < a0 then
            return a0 - b1
        end
        return 0
    end

    local dx = axis_distance(a_min.X, a_max.X, b_min.X, b_max.X)
    local dy = axis_distance(a_min.Y, a_max.Y, b_min.Y, b_max.Y)
    local dz = axis_distance(a_min.Z, a_max.Z, b_min.Z, b_max.Z)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Estimates how many legal wires are needed for a straight distance.
function circuit_estimated_wire_count(distance, maximum_length)
    if distance < min_distance - length_eps then
        return math.huge
    end
    return math.max(1, math.ceil(distance / maximum_length - length_eps))
end

-- Expands a circuit component bounding box to include a point.
function circuit_update_component_bounds(component, point)
    if not component.min then
        component.min = circuit_copy_vector3(point)
        component.max = circuit_copy_vector3(point)
        return
    end

    component.min = Vector3.new(
        math.min(component.min.X, point.X),
        math.min(component.min.Y, point.Y),
        math.min(component.min.Z, point.Z)
    )
    component.max = Vector3.new(
        math.max(component.max.X, point.X),
        math.max(component.max.Y, point.Y),
        math.max(component.max.Z, point.Z)
    )
end

-- Builds the finite cylinder geometry used for a wire endpoint.
function circuit_get_endpoint_geometry(wire, at_start)
    if type(wire) ~= "table" or #wire < 2 then
        return nil
    end

    local point_index = at_start and 1 or #wire
    local neighbour_index = at_start and 2 or (#wire - 1)
    local center = wire[point_index]
    local direction = center - wire[neighbour_index]

    if direction.Magnitude <= length_eps then
        return nil
    end

    local stats = wire_stats[wire_type_name] or wire_stats.Wire
    local size = stats.end_size
    local axis_half_length = size.X * 0.5
    local radius = math.max(size.Y, size.Z) * 0.5
    local unit = direction.Unit

    return {
        center = center,
        axis_start = center - unit * axis_half_length,
        axis_finish = center + unit * axis_half_length,
        radius = radius,
    }
end

-- Calculates the closest distance between two endpoint cylinder axes.
function circuit_endpoint_axis_distance(a0, a1, b0, b1)
    local u = a1 - a0
    local v = b1 - b0
    local w = a0 - b0

    local aa = u:Dot(u)
    local bb = u:Dot(v)
    local cc = v:Dot(v)
    local dd = u:Dot(w)
    local ee = v:Dot(w)
    local denominator = aa * cc - bb * bb

    local sc, tc

    if aa <= length_eps * length_eps and cc <= length_eps * length_eps then
        sc, tc = 0, 0
    elseif aa <= length_eps * length_eps then
        sc = 0
        tc = math.clamp(ee / cc, 0, 1)
    elseif cc <= length_eps * length_eps then
        tc = 0
        sc = math.clamp(-dd / aa, 0, 1)
    elseif denominator > (length_eps * length_eps) ^ 2 then
        sc = math.clamp((bb * ee - cc * dd) / denominator, 0, 1)
        tc = (bb * sc + ee) / cc

        if tc < 0 then
            tc = 0
            sc = math.clamp(-dd / aa, 0, 1)
        elseif tc > 1 then
            tc = 1
            sc = math.clamp((bb - dd) / aa, 0, 1)
        end
    else

        local candidates = {
            {0, math.clamp(ee / cc, 0, 1)},
            {1, math.clamp((bb + ee) / cc, 0, 1)},
            {math.clamp(-dd / aa, 0, 1), 0},
            {math.clamp((bb - dd) / aa, 0, 1), 1},
        }
        local best = math.huge
        for _, pair in ipairs(candidates) do
            local pa = a0 + u * pair[1]
            local pb = b0 + v * pair[2]
            local d = (pb - pa).Magnitude
            if d < best then
                best = d
                sc, tc = pair[1], pair[2]
            end
        end
    end

    local point_a = a0 + u * sc
    local point_b = b0 + v * tc
    return (point_b - point_a).Magnitude
end

-- Calculates a support point of a finite cylinder in a direction.
function circuit_cylinder_support(geometry, direction)
    local axis = (geometry.axis_finish - geometry.axis_start)
    local axis_length = axis.Magnitude
    local half_length = axis_length * 0.5
    if axis_length <= eps then
        return geometry.center
    end

    axis = axis / axis_length
    local projection = axis:Dot(direction)
    local axial = axis * (projection >= 0 and half_length or -half_length)
    local radial = direction - axis * projection

    if radial.Magnitude > eps then
        radial = radial.Unit * geometry.radius
    else
        radial = Vector3.zero
    end

    return geometry.center + axial + radial
end

-- Calculates a support point of the expanded Minkowski difference of two cylinders.
function circuit_cylinder_minkowski_support(first, second, direction, extra)
    if direction.Magnitude <= eps then
        direction = Vector3.xAxis
    end

    local unit_direction = direction.Unit
    return circuit_cylinder_support(first, direction)
        - circuit_cylinder_support(second, -direction)
        + unit_direction * extra
end

-- Reduces a GJK simplex containing a line to the relevant search direction.
function circuit_gjk_line_simplex(simplex)
    local a = simplex[#simplex]
    local b = simplex[#simplex - 1]
    local ao = -a
    local ab = b - a

    if ab:Dot(ao) <= 0 then
        simplex[1] = a
        simplex[2] = nil
        return false, ao
    end

    local direction = ab:Cross(ao):Cross(ab)
    if direction.Magnitude <= eps then
        direction = ab:Cross(Vector3.xAxis)
        if direction.Magnitude <= eps then
            direction = ab:Cross(Vector3.yAxis)
        end
        if direction.Magnitude <= eps then
            direction = ab:Cross(Vector3.zAxis)
        end
    end

    return false, direction
end

-- Reduces a GJK simplex containing a triangle to the relevant search direction.
function circuit_gjk_triangle_simplex(simplex)
    local a = simplex[#simplex]
    local b = simplex[#simplex - 1]
    local c = simplex[#simplex - 2]
    local ao = -a
    local ab = b - a
    local ac = c - a
    local abc = ab:Cross(ac)

    if abc.Magnitude <= eps then
        if ab.Magnitude > eps then
            simplex[1] = b
            simplex[2] = a
            simplex[3] = nil
            return circuit_gjk_line_simplex(simplex)
        end

        simplex[1] = a
        simplex[2] = nil
        simplex[3] = nil
        return false, ao
    end

    local ac_region = abc:Cross(ac)
    if ac_region:Dot(ao) > 0 then
        if ac:Dot(ao) > 0 then
            simplex[1] = c
            simplex[2] = a
            simplex[3] = nil
            local direction = ac:Cross(ao):Cross(ac)
            if direction.Magnitude <= eps then
                direction = ac:Cross(Vector3.xAxis)
                if direction.Magnitude <= eps then
                    direction = ac:Cross(Vector3.yAxis)
                end
            end
            return false, direction
        end

        if ab:Dot(ao) > 0 then
            simplex[1] = b
            simplex[2] = a
            simplex[3] = nil
            local direction = ab:Cross(ao):Cross(ab)
            if direction.Magnitude <= eps then
                direction = ab:Cross(Vector3.xAxis)
                if direction.Magnitude <= eps then
                    direction = ab:Cross(Vector3.yAxis)
                end
            end
            return false, direction
        end

        simplex[1] = a
        simplex[2] = nil
        simplex[3] = nil
        return false, ao
    end

    local ab_region = ab:Cross(abc)
    if ab_region:Dot(ao) > 0 then
        if ab:Dot(ao) > 0 then
            simplex[1] = b
            simplex[2] = a
            simplex[3] = nil
            local direction = ab:Cross(ao):Cross(ab)
            if direction.Magnitude <= eps then
                direction = ab:Cross(Vector3.xAxis)
                if direction.Magnitude <= eps then
                    direction = ab:Cross(Vector3.yAxis)
                end
            end
            return false, direction
        end

        simplex[1] = a
        simplex[2] = nil
        simplex[3] = nil
        return false, ao
    end

    if abc:Dot(ao) > 0 then
        return false, abc
    end

    simplex[1], simplex[2] = b, c
    return false, -abc
end

-- Reduces a GJK simplex containing a tetrahedron and tests containment.
function circuit_gjk_tetrahedron_simplex(simplex)
    local a = simplex[#simplex]
    local b = simplex[#simplex - 1]
    local c = simplex[#simplex - 2]
    local d = simplex[#simplex - 3]
    local ao = -a

    local ab = b - a
    local ac = c - a
    local ad = d - a

    local abc = ab:Cross(ac)
    if abc:Dot(ao) > 0 then
        simplex[1] = c
        simplex[2] = b
        simplex[3] = a
        simplex[4] = nil
        return circuit_gjk_triangle_simplex(simplex)
    end

    local acd = ac:Cross(ad)
    if acd:Dot(ao) > 0 then
        simplex[1] = d
        simplex[2] = c
        simplex[3] = a
        simplex[4] = nil
        return circuit_gjk_triangle_simplex(simplex)
    end

    local adb = ad:Cross(ab)
    if adb:Dot(ao) > 0 then
        simplex[1] = b
        simplex[2] = d
        simplex[3] = a
        simplex[4] = nil
        return circuit_gjk_triangle_simplex(simplex)
    end

    return true, Vector3.zero
end

-- Tests whether two finite endpoint cylinders intersect or touch.
function circuit_endpoint_cylinders_touch(first, second, extra)
    local direction = second.center - first.center
    if direction.Magnitude <= eps then
        direction = Vector3.xAxis
    end

    local simplex = {circuit_cylinder_minkowski_support(first, second, direction, extra)}
    direction = -simplex[1]

    if direction.Magnitude <= length_eps then
        return true
    end

    for _ = 1, 48 do
        local support = circuit_cylinder_minkowski_support(first, second, direction, extra)

        if support:Dot(direction) < -length_eps then
            return false
        end

        local duplicate = false
        for _, point in ipairs(simplex) do
            if (point - support).Magnitude <= length_eps then
                duplicate = true
                break
            end
        end

        if duplicate then
            return false
        end

        table.insert(simplex, support)

        local contains_origin, new_direction
        if #simplex == 2 then
            contains_origin, new_direction = circuit_gjk_line_simplex(simplex)
        elseif #simplex == 3 then
            contains_origin, new_direction = circuit_gjk_triangle_simplex(simplex)
        elseif #simplex == 4 then
            contains_origin, new_direction = circuit_gjk_tetrahedron_simplex(simplex)
        else
            return false
        end

        if contains_origin then
            return true
        end

        if new_direction.Magnitude <= length_eps then
            return true
        end

        direction = new_direction
    end

    return false
end

-- Checks whether two wire endpoint parts physically touch.
function circuit_endpoint_parts_touch(wire_a, at_start_a, wire_b, at_start_b)
    local first = circuit_get_endpoint_geometry(wire_a, at_start_a)
    local second = circuit_get_endpoint_geometry(wire_b, at_start_b)
    if not first or not second then
        return false
    end

    local allowed_extra = math.max(0, tonumber(circuit_settings.endpoint_conductivity_distance) or 0)
    return circuit_endpoint_cylinders_touch(first, second, allowed_extra + eps)
end

-- Builds electrical components from old wire endpoints and their contacts.
function circuit_build_topology(source_art, tolerance)
    local nodes = {}
    local node_buckets = {}
    local wire_records = {}

    local bucket_size = math.max(tolerance, length_eps)

    local function bucket_coordinate(value)
        return math.floor(value / bucket_size)
    end

    local function bucket_key(x, y, z)
        return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    end

    local function get_node_id(point)
        local cx = bucket_coordinate(point.X)
        local cy = bucket_coordinate(point.Y)
        local cz = bucket_coordinate(point.Z)

        for ox = -1, 1 do
            for oy = -1, 1 do
                for oz = -1, 1 do
                    local key = bucket_key(cx + ox, cy + oy, cz + oz)
                    local bucket = node_buckets[key]
                    if bucket then
                        for _, existing_id in ipairs(bucket) do
                            if circuit_distance(nodes[existing_id].position, point)
                                <= tolerance + length_eps then
                                return existing_id
                            end
                        end
                    end
                end
            end
        end

        local node_id = #nodes + 1
        nodes[node_id] = {
            position = circuit_copy_vector3(point),
            incident_wires = {},
        }

        local own_key = bucket_key(cx, cy, cz)
        node_buckets[own_key] = node_buckets[own_key] or {}
        table.insert(node_buckets[own_key], node_id)
        return node_id
    end

    for mini_index, mini_art in ipairs(source_art or {}) do
        if type(mini_art) == "table" then
            for wire_index, wire in ipairs(mini_art) do
                if type(wire) == "table"
                    and #wire >= 2
                    and typeof(wire[1]) == "Vector3"
                    and typeof(wire[#wire]) == "Vector3"
                then
                    local start_id = get_node_id(wire[1])
                    local finish_id = get_node_id(wire[#wire])

                    local min_point = circuit_copy_vector3(wire[1])
                    local max_point = circuit_copy_vector3(wire[1])
                    local total_length = 0
                    local cumulative = {0}

                    for point_index = 2, #wire do
                        local point = wire[point_index]
                        min_point = Vector3.new(
                            math.min(min_point.X, point.X),
                            math.min(min_point.Y, point.Y),
                            math.min(min_point.Z, point.Z)
                        )
                        max_point = Vector3.new(
                            math.max(max_point.X, point.X),
                            math.max(max_point.Y, point.Y),
                            math.max(max_point.Z, point.Z)
                        )

                        local segment_length = circuit_distance(wire[point_index - 1], point)
                        total_length += segment_length
                        cumulative[point_index] = total_length
                    end

                    local record = {
                        mini_index = mini_index,
                        wire_index = wire_index,
                        wire = wire,
                        start_node = start_id,
                        finish_node = finish_id,
                        min = min_point,
                        max = max_point,
                        total_length = total_length,
                        cumulative = cumulative,
                    }

                    table.insert(wire_records, record)
                    table.insert(nodes[start_id].incident_wires, record)
                    table.insert(nodes[finish_id].incident_wires, record)
                end
            end
        end
    end

    local find, union = circuit_make_union_find(#nodes)

    for _, record in ipairs(wire_records) do
        union(record.start_node, record.finish_node)
    end

    local endpoint_entries = {}
    local endpoint_buckets = {}
    local old_stats = wire_stats[wire_type_name] or wire_stats.Wire
    local old_endpoint_half = old_stats.end_size.X * 0.5
    local old_endpoint_radius = math.max(old_stats.end_size.Y, old_stats.end_size.Z) * 0.5
    local endpoint_extra = math.max(0, tonumber(circuit_settings.endpoint_conductivity_distance) or 0)
    local endpoint_bucket_size = math.max(
        length_eps,
        math.sqrt(old_endpoint_half * old_endpoint_half + old_endpoint_radius * old_endpoint_radius)
            + math.sqrt(old_endpoint_half * old_endpoint_half + old_endpoint_radius * old_endpoint_radius)
            + endpoint_extra + min_distance
    )

    function endpoint_bucket_coordinate(value)
        return math.floor(value / endpoint_bucket_size)
    end

    function endpoint_bucket_key(x, y, z)
        return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    end

    function add_endpoint_entry(record, at_start)
        local wire = record.wire
        local index = at_start and 1 or #wire
        local position = wire[index]
        local cx = endpoint_bucket_coordinate(position.X)
        local cy = endpoint_bucket_coordinate(position.Y)
        local cz = endpoint_bucket_coordinate(position.Z)
        local entry = {
            record = record,
            at_start = at_start,
            node_id = at_start and record.start_node or record.finish_node,
            bucket_x = cx,
            bucket_y = cy,
            bucket_z = cz,
        }
        table.insert(endpoint_entries, entry)
        local key = endpoint_bucket_key(cx, cy, cz)
        endpoint_buckets[key] = endpoint_buckets[key] or {}
        table.insert(endpoint_buckets[key], entry)
    end

    for _, record in ipairs(wire_records) do
        add_endpoint_entry(record, true)
        add_endpoint_entry(record, false)
    end

    for _, entry in ipairs(endpoint_entries) do
        for ox = -1, 1 do
            for oy = -1, 1 do
                for oz = -1, 1 do
                    local key = endpoint_bucket_key(
                        entry.bucket_x + ox,
                        entry.bucket_y + oy,
                        entry.bucket_z + oz
                    )
                    local bucket = endpoint_buckets[key]
                    if bucket then
                        for _, other in ipairs(bucket) do
                            if other ~= entry and other.node_id ~= entry.node_id then
                                if circuit_endpoint_parts_touch(
                                    entry.record.wire,
                                    entry.at_start,
                                    other.record.wire,
                                    other.at_start
                                ) then
                                    union(entry.node_id, other.node_id)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local components_by_root = {}
    for node_id, node in ipairs(nodes) do
        local root = find(node_id)
        local component = components_by_root[root]
        if not component then
            component = {
                root = root,
                node_ids = {},
                nodes = {},
                wire_records = {},
                min = nil,
                max = nil,
            }
            components_by_root[root] = component
        end

        table.insert(component.node_ids, node_id)
        table.insert(component.nodes, node)
        circuit_update_component_bounds(component, node.position)
    end

    local components = {}
    local component_by_node = {}
    local roots = {}

    for root in pairs(components_by_root) do
        table.insert(roots, root)
    end
    table.sort(roots)

    for _, root in ipairs(roots) do
        local component = components_by_root[root]
        component.id = #components + 1

        for _, node_id in ipairs(component.node_ids) do
            component_by_node[node_id] = component.id
        end

        table.insert(components, component)
    end

    for _, record in ipairs(wire_records) do
        local component_id = component_by_node[record.start_node]
        record.component_id = component_id
        table.insert(components[component_id].wire_records, record)
    end

    return nodes, wire_records, components, component_by_node
end

-- Finds the closest points between two line segments.
function circuit_segment_closest_points(a0, a1, b0, b1)
    local u = a1 - a0
    local v = b1 - b0
    local w = a0 - b0

    local aa = u:Dot(u)
    local bb = u:Dot(v)
    local cc = v:Dot(v)
    local dd = u:Dot(w)
    local ee = v:Dot(w)
    local denominator = aa * cc - bb * bb

    local sc
    local tc
    local squared_eps = length_eps * length_eps
    local denominator_eps = squared_eps * squared_eps

    if aa <= squared_eps and cc <= squared_eps then
        sc = 0
        tc = 0
    elseif aa <= squared_eps then
        sc = 0
        tc = math.clamp(ee / cc, 0, 1)
    elseif cc <= squared_eps then
        tc = 0
        sc = math.clamp(-dd / aa, 0, 1)
    else
        if denominator > denominator_eps then
            sc = math.clamp((bb * ee - cc * dd) / denominator, 0, 1)
            tc = (bb * sc + ee) / cc
        else

            sc = 0
            tc = math.clamp(ee / cc, 0, 1)
        end

        if tc < 0 then
            tc = 0
            sc = math.clamp(-dd / aa, 0, 1)
        elseif tc > 1 then
            tc = 1
            sc = math.clamp((bb - dd) / aa, 0, 1)
        end
    end

    local point_a = a0 + u * sc
    local point_b = b0 + v * tc
    return point_a, point_b, circuit_distance(point_a, point_b), sc, tc
end

-- Builds parameter intervals where an interior contact remains legal.
function circuit_get_safe_parameter_intervals(segment_length)
    if segment_length <= length_eps then
        return {}
    end

    local margin = min_distance / segment_length
    local result = {
        {0, 0},
        {1, 1},
    }

    if margin < 0.5 - length_eps then
        table.insert(result, {margin, 1 - margin})
    end

    return result
end

-- Finds closest points on two segments while restricting both parameters to legal intervals.
function circuit_restricted_segment_closest_points(
    a0,
    a1,
    b0,
    b1,
    a_min,
    a_max,
    b_min,
    b_max
)
    local best = nil
    local u = a1 - a0
    local v = b1 - b0
    local aa = u:Dot(u)
    local cc = v:Dot(v)

    local function evaluate(t_a, t_b)
        t_a = math.clamp(t_a, a_min, a_max)
        t_b = math.clamp(t_b, b_min, b_max)

        local point_a = a0:Lerp(a1, t_a)
        local point_b = b0:Lerp(b1, t_b)
        local distance = circuit_distance(point_a, point_b)

        if not best or distance < best.distance - length_eps then
            best = {
                position_a = point_a,
                position_b = point_b,
                distance = distance,
                t_a = t_a,
                t_b = t_b,
            }
        end
    end

    local unconstrained_a, unconstrained_b, _, unconstrained_t_a, unconstrained_t_b =
        circuit_segment_closest_points(a0, a1, b0, b1)

    if unconstrained_a and unconstrained_b
        and unconstrained_t_a >= a_min - length_eps
        and unconstrained_t_a <= a_max + length_eps
        and unconstrained_t_b >= b_min - length_eps
        and unconstrained_t_b <= b_max + length_eps
    then
        evaluate(unconstrained_t_a, unconstrained_t_b)
    end

    for _, fixed_a in ipairs({a_min, a_max}) do
        local point_a = a0:Lerp(a1, fixed_a)
        local t_b
        if cc <= length_eps * length_eps then
            t_b = b_min
        else
            t_b = math.clamp((point_a - b0):Dot(v) / cc, b_min, b_max)
        end
        evaluate(fixed_a, t_b)
    end

    for _, fixed_b in ipairs({b_min, b_max}) do
        local point_b = b0:Lerp(b1, fixed_b)
        local t_a
        if aa <= length_eps * length_eps then
            t_a = a_min
        else
            t_a = math.clamp((point_b - a0):Dot(u) / aa, a_min, a_max)
        end
        evaluate(t_a, fixed_b)
    end

    return best
end

-- Finds a point-to-segment distance and its segment parameter.
function circuit_point_segment_distance_and_t(point, a0, a1)
    local delta = a1 - a0
    local denominator = delta:Dot(delta)
    if denominator <= length_eps * length_eps then
        return circuit_distance(point, a0), 0
    end

    local t = math.clamp((point - a0):Dot(delta) / denominator, 0, 1)
    local projected = a0 + delta * t
    return circuit_distance(point, projected), t
end

-- Finds segment-circle intersection parameters.
function circuit_solve_segment_circle(point, seg_a, seg_b, radius)
    local d = seg_b - seg_a
    local f = seg_a - point
    local aa = d:Dot(d)
    if aa <= length_eps * length_eps then
        return {}
    end

    local bb = 2 * f:Dot(d)
    local cc = f:Dot(f) - radius * radius
    local discriminant = bb * bb - 4 * aa * cc

    if discriminant < -length_eps then
        return {}
    end

    if discriminant < 0 then
        discriminant = 0
    end

    local root = math.sqrt(discriminant)
    local t1 = (-bb - root) / (2 * aa)
    local t2 = (-bb + root) / (2 * aa)
    local result = {}

    if t1 >= -length_eps and t1 <= 1 + length_eps then
        table.insert(result, math.clamp(t1, 0, 1))
    end
    if math.abs(t2 - t1) > length_eps
        and t2 >= -length_eps
        and t2 <= 1 + length_eps
    then
        table.insert(result, math.clamp(t2, 0, 1))
    end

    return result
end

-- Finds the nearest point on an old-wire trajectory to an endpoint.
function circuit_arc_to_nearest_endpoint(record, segment_index, segment_t)
    local a = record.wire[segment_index]
    local b = record.wire[segment_index + 1]
    local segment_length = circuit_distance(a, b)
    local arc_from_start = record.cumulative[segment_index] + segment_length * segment_t
    local arc_to_finish = math.max(0, record.total_length - arc_from_start)

    if arc_from_start <= arc_to_finish then
        return arc_from_start, record.start_node, true, arc_from_start, arc_to_finish
    end

    return arc_to_finish, record.finish_node, false, arc_from_start, arc_to_finish
end

-- Compares two circuit contact candidates using the configured priorities.
function circuit_candidate_better(a, b)
    if not b then
        return true
    end

    if a.connector_length < b.connector_length - length_eps then
        return true
    elseif a.connector_length > b.connector_length + length_eps then
        return false
    end

    if a.estimated_wires ~= b.estimated_wires then
        return a.estimated_wires < b.estimated_wires
    end

    if a.effective_length < b.effective_length - length_eps then
        return true
    elseif a.effective_length > b.effective_length + length_eps then
        return false
    end

    if math.abs(a.closest_pair_shift - b.closest_pair_shift) > length_eps then
        return a.closest_pair_shift < b.closest_pair_shift
    end

    return false
end

-- Finds the best legal contact between a pair of old-wire segments.
function circuit_find_best_segment_contact(record_a, seg_a_index, record_b, seg_b_index)
    local a0 = record_a.wire[seg_a_index]
    local a1 = record_a.wire[seg_a_index + 1]
    local b0 = record_b.wire[seg_b_index]
    local b1 = record_b.wire[seg_b_index + 1]

    local segment_length_a = circuit_distance(a0, a1)
    local segment_length_b = circuit_distance(b0, b1)
    if segment_length_a <= length_eps or segment_length_b <= length_eps then
        return nil
    end

    local intervals_a = circuit_get_safe_parameter_intervals(segment_length_a)
    local intervals_b = circuit_get_safe_parameter_intervals(segment_length_b)

    local best = nil

    local function evaluate(t_a, t_b, forced_minimum)
        t_a = math.clamp(t_a, 0, 1)
        t_b = math.clamp(t_b, 0, 1)

        local point_a = a0:Lerp(a1, t_a)
        local point_b = b0:Lerp(b1, t_b)
        local distance = circuit_distance(point_a, point_b)

        if distance < min_distance - length_eps then
            return
        end

        local arc_a, endpoint_node_a, endpoint_at_start_a = circuit_arc_to_nearest_endpoint(
            record_a,
            seg_a_index,
            t_a
        )
        local arc_b, endpoint_node_b, endpoint_at_start_b = circuit_arc_to_nearest_endpoint(
            record_b,
            seg_b_index,
            t_b
        )

        local effective_length = distance + arc_a + arc_b
        local estimated_wires = circuit_estimated_wire_count(
            effective_length,
            split_max_len
        )

        local candidate = {
            position_a = point_a,
            position_b = point_b,
            distance = distance,
            connector_length = distance,
            effective_length = effective_length,
            estimated_wires = estimated_wires,
            endpoint_arc_a = arc_a,
            endpoint_arc_b = arc_b,
            endpoint_arc_total = arc_a + arc_b,
            endpoint_node_a = endpoint_node_a,
            endpoint_node_b = endpoint_node_b,
            endpoint_at_start_a = endpoint_at_start_a,
            endpoint_at_start_b = endpoint_at_start_b,
            segment_index_a = seg_a_index,
            segment_index_b = seg_b_index,
            segment_t_a = t_a,
            segment_t_b = t_b,
            closest_pair_shift = 0,
            forced_minimum = forced_minimum == true,
        }

        if candidate.estimated_wires == math.huge then
            return
        end

        if circuit_candidate_better(candidate, best) then
            best = candidate
        end
    end

    local closest_candidates = {}

    for _, interval_a in ipairs(intervals_a) do
        for _, interval_b in ipairs(intervals_b) do
            local closest = circuit_restricted_segment_closest_points(
                a0,
                a1,
                b0,
                b1,
                interval_a[1],
                interval_a[2],
                interval_b[1],
                interval_b[2]
            )

            if closest then
                table.insert(closest_candidates, closest)

                if closest.distance >= min_distance - length_eps then
                    evaluate(closest.t_a, closest.t_b, false)
                end
            end
        end
    end

    if best then
        return best
    end

    local radius = min_distance

    local function t_is_in_any_safe_interval(t, intervals)
        for _, interval in ipairs(intervals) do
            if t >= interval[1] - length_eps and t <= interval[2] + length_eps then
                return true
            end
        end
        return false
    end

    local function evaluate_circle_from_a(t_a, point_a)
        for _, interval_b in ipairs(intervals_b) do
            for _, t_b in ipairs(circuit_solve_segment_circle(point_a, b0, b1, radius)) do
                if t_b >= interval_b[1] - length_eps and t_b <= interval_b[2] + length_eps then
                    evaluate(t_a, t_b, true)
                end
            end
        end
    end

    local function evaluate_circle_from_b(t_b, point_b)
        for _, interval_a in ipairs(intervals_a) do
            for _, t_a in ipairs(circuit_solve_segment_circle(point_b, a0, a1, radius)) do
                if t_a >= interval_a[1] - length_eps and t_a <= interval_a[2] + length_eps then
                    evaluate(t_a, t_b, true)
                end
            end
        end
    end

    for _, closest in ipairs(closest_candidates) do
        if closest.distance < min_distance - length_eps then
            evaluate_circle_from_a(closest.t_a, closest.position_a)
            evaluate_circle_from_b(closest.t_b, closest.position_b)
        end
    end

    local boundary_t_a = {}
    for _, interval in ipairs(intervals_a) do
        table.insert(boundary_t_a, interval[1])
        table.insert(boundary_t_a, interval[2])
    end

    local boundary_t_b = {}
    for _, interval in ipairs(intervals_b) do
        table.insert(boundary_t_b, interval[1])
        table.insert(boundary_t_b, interval[2])
    end

    for _, t_a in ipairs(boundary_t_a) do
        evaluate_circle_from_a(t_a, a0:Lerp(a1, t_a))
    end

    for _, t_b in ipairs(boundary_t_b) do
        evaluate_circle_from_b(t_b, b0:Lerp(b1, t_b))
    end

    return best
end

-- Finds the closest legal contact between two complete old wires.
function circuit_find_closest_points_between_wires(record_a, record_b)
    if type(record_a.wire) ~= "table" or #record_a.wire < 2 then
        return nil
    end
    if type(record_b.wire) ~= "table" or #record_b.wire < 2 then
        return nil
    end

    local best = nil

    for seg_a_index = 1, #record_a.wire - 1 do
        local a0 = record_a.wire[seg_a_index]
        local a1 = record_a.wire[seg_a_index + 1]
        local segment_length_a = circuit_distance(a0, a1)
        if segment_length_a > length_eps then
            for seg_b_index = 1, #record_b.wire - 1 do
                local b0 = record_b.wire[seg_b_index]
                local b1 = record_b.wire[seg_b_index + 1]
                local segment_length_b = circuit_distance(b0, b1)

                if segment_length_b > length_eps then

                    if not best then
                        local candidate = circuit_find_best_segment_contact(
                            record_a,
                            seg_a_index,
                            record_b,
                            seg_b_index
                        )
                        if candidate then
                            best = candidate
                        end
                    else
                        local min_a = Vector3.new(
                            math.min(a0.X, a1.X),
                            math.min(a0.Y, a1.Y),
                            math.min(a0.Z, a1.Z)
                        )
                        local max_a = Vector3.new(
                            math.max(a0.X, a1.X),
                            math.max(a0.Y, a1.Y),
                            math.max(a0.Z, a1.Z)
                        )
                        local min_b = Vector3.new(
                            math.min(b0.X, b1.X),
                            math.min(b0.Y, b1.Y),
                            math.min(b0.Z, b1.Z)
                        )
                        local max_b = Vector3.new(
                            math.max(b0.X, b1.X),
                            math.max(b0.Y, b1.Y),
                            math.max(b0.Z, b1.Z)
                        )
                        local lower_bound = circuit_bbox_distance(min_a, max_a, min_b, max_b)

                        if lower_bound <= best.connector_length + length_eps
                            or best.connector_length <= min_distance + length_eps
                        then
                            local candidate = circuit_find_best_segment_contact(
                                record_a,
                                seg_a_index,
                                record_b,
                                seg_b_index
                            )
                            if candidate and circuit_candidate_better(candidate, best) then
                                best = candidate
                            end
                        end
                    end
                end
            end
        end
    end

    return best
end

-- Finds the best connection between two different electrical components.
function circuit_find_connection(component_a, component_b)
    local best = nil

    for _, record_a in ipairs(component_a.wire_records) do
        for _, record_b in ipairs(component_b.wire_records) do

            if not best then
                local contact = circuit_find_closest_points_between_wires(record_a, record_b)
                if contact then
                    best = contact
                    best.source_record = record_a
                    best.target_record = record_b
                end
            else
                local lower_bound = circuit_bbox_distance(
                    record_a.min,
                    record_a.max,
                    record_b.min,
                    record_b.max
                )

                if lower_bound <= best.connector_length + length_eps
                    or best.connector_length <= min_distance + length_eps
                then
                    local contact = circuit_find_closest_points_between_wires(record_a, record_b)
                    if contact then
                        contact.source_record = record_a
                        contact.target_record = record_b
                        if circuit_candidate_better(contact, best) then
                            best = contact
                        end
                    end
                end
            end
        end
    end

    return best
end

-- Builds the exact old-wire path from an endpoint to an interior contact.
function circuit_build_endpoint_to_contact_path(record, segment_index, segment_t, endpoint_at_start)
    if not record or type(record.wire) ~= "table" then
        return nil
    end

    local wire = record.wire
    if #wire < 2 or not segment_index or not segment_t then
        return nil
    end

    local contact = wire[segment_index]:Lerp(wire[segment_index + 1], segment_t)
    local path = {}

    local function append(point)
        if typeof(point) ~= "Vector3" then
            return
        end
        if #path == 0 or circuit_distance(path[#path], point) > length_eps then
            table.insert(path, circuit_copy_vector3(point))
        end
    end

    if endpoint_at_start then
        append(wire[1])
        for point_index = 2, segment_index do
            append(wire[point_index])
        end
        append(contact)
    else
        append(wire[#wire])
        for point_index = #wire - 1, segment_index + 1, -1 do
            append(wire[point_index])
        end
        append(contact)
    end

    return path
end

-- Reverses a polyline path in place and returns it.
function circuit_reverse_path(path)
    local result = {}
    for index = #path, 1, -1 do
        table.insert(result, path[index])
    end
    return result
end

-- Builds the full endpoint-to-endpoint route through old trajectories and a new connector.
function circuit_build_connection_route(connection)
    if not connection then
        return nil, "Missing circuit connection."
    end

    local path_a = circuit_build_endpoint_to_contact_path(
        connection.source_record,
        connection.segment_index_a,
        connection.segment_t_a,
        connection.endpoint_at_start_a
    )

    local path_b = circuit_build_endpoint_to_contact_path(
        connection.target_record,
        connection.segment_index_b,
        connection.segment_t_b,
        connection.endpoint_at_start_b
    )

    if not path_a or #path_a < 1 then
        return nil, "Could not build source old-trajectory path to endpoint."
    end

    if not path_b or #path_b < 1 then
        return nil, "Could not build target old-trajectory path to endpoint."
    end

    local route = {}

    local function append(point)
        if not point then
            return
        end
        if #route == 0 or circuit_distance(route[#route], point) > length_eps then
            table.insert(route, circuit_copy_vector3(point))
        end
    end

    for _, point in ipairs(path_a) do
        append(point)
    end

    append(connection.position_b)

    local reversed_b = circuit_reverse_path(path_b)
    for _, point in ipairs(reversed_b) do
        append(point)
    end

    if #route < 2 then
        return nil, "Circuit connection route collapsed to fewer than two points."
    end

    return route
end

-- Calculates the total length of a circuit route.
function circuit_route_length(route)
    if type(route) ~= "table" or #route < 2 then
        return 0
    end

    local total = 0
    for i = 2, #route do
        if typeof(route[i - 1]) ~= "Vector3" or typeof(route[i]) ~= "Vector3" then
            return math.huge
        end
        total += circuit_distance(route[i - 1], route[i])
    end
    return total
end

-- Verifies that a generated route reaches the expected old endpoints.
function circuit_validate_endpoint_route(route, connection)
    if type(route) ~= "table" or #route < 2 then
        return false, "Route has fewer than two points."
    end

    local route_length = circuit_route_length(route)
    if route_length == math.huge then
        return false, "Route contains invalid points."
    end

    local expected = (connection.connector_length or connection.distance or 0)
        + (connection.endpoint_arc_a or 0)
        + (connection.endpoint_arc_b or 0)

    if math.abs(route_length - expected) > math.max(length_eps * 10, 1e-4) then
        return false, string.format(
            "Route length mismatch: got %.6f, expected %.6f.",
            route_length,
            expected
        )
    end

    return true
end

-- Splits a straight circuit connector into the minimum number of legal wires.
function circuit_split_straight(start_point, finish_point, minimum_length, maximum_length)
    local distance = circuit_distance(start_point, finish_point)
    if distance < minimum_length - length_eps then
        return nil, "Straight connector is shorter than minimum wire length."
    end

    local count = math.max(1, math.ceil(distance / maximum_length - length_eps))
    local piece_length = distance / count

    if piece_length < minimum_length - length_eps
        or piece_length > maximum_length + length_eps
    then
        return nil, "Unable to split straight connector into legal wires."
    end

    local result = {}
    for index = 1, count do
        local p0 = start_point:Lerp(finish_point, (index - 1) / count)
        local p1 = start_point:Lerp(finish_point, index / count)
        table.insert(result, {p0, p1})
    end
    return result
end

-- Splits a complete circuit route into legal physical wires.
function circuit_route_to_wires(route, minimum_length, maximum_length)
    if not route or #route < 2 then
        return nil, "Empty circuit route."
    end

    if #route == 2 then
        return circuit_split_straight(route[1], route[2], minimum_length, maximum_length)
    end

    local result, split_report = ArtPipeline.split({route}, minimum_length, maximum_length)
    if split_report.split_failed_lists == 0 and #result > 0 then
        return result[1]
    end

    return nil, "Circuit route could not be split into valid wires."
end

-- Selects the minimum spanning set of circuit connections between components.
function circuit_kruskal(component_count, edges)
    local find, union = circuit_make_union_find(component_count)

    table.sort(edges, function(a, b)

        if math.abs(a.connector_length - b.connector_length) > length_eps then
            return a.connector_length < b.connector_length
        end

        if a.estimated_wires ~= b.estimated_wires then
            return a.estimated_wires < b.estimated_wires
        end

        if math.abs(a.endpoint_arc_total - b.endpoint_arc_total) > length_eps then
            return a.endpoint_arc_total < b.endpoint_arc_total
        end

        if a.component_a ~= b.component_a then
            return a.component_a < b.component_a
        end
        return a.component_b < b.component_b
    end)

    local chosen = {}
    for _, edge in ipairs(edges) do
        if union(edge.component_a, edge.component_b) then
            table.insert(chosen, edge)
            if #chosen == component_count - 1 then
                break
            end
        end
    end

    return chosen, find
end

-- Generates the complete hidden circuit art from the original wire topology.
function CircuitBuilder.generate(source_art)
    local circuit_type = circuit_settings.wire_type_name
    local circuit_maximum = max_lengths[circuit_type]
    if not circuit_maximum then
        return nil, "Unknown circuit wire type: " .. tostring(circuit_type)
    end

    local replicated = replicated_wires[circuit_type]
    if not replicated then
        return nil, "Replicated circuit wire object not found for: " .. tostring(circuit_type)
    end

    local circuit_split_maximum = circuit_maximum - wire_max_margin - math.max(0.0001, length_eps * 2)
    if circuit_split_maximum < min_distance then
        return nil, "Circuit wire maximum length is too close to minimum wire length."
    end

    local tolerance = math.max(0, tonumber(circuit_settings.endpoint_tolerance) or 0)
    if tolerance < length_eps then
        tolerance = length_eps
    end

    local nodes, wire_records, components = circuit_build_topology(source_art, tolerance)

    if #wire_records == 0 then
        return nil, "No valid old wires were found for circuit generation."
    end

    if #components <= 1 then
        return {
            art = {},
            validation = ArtPipeline.validate({}),
            drawable = {},
            source_wires = #wire_records,
            new_wires = 0,
            node_count = #nodes,
            component_count = #components,
            connector_count = 0,
            connector_length = 0,
            route_length = 0,
            effective_route_length = 0,
            estimated_tree_wires = 0,
            split_failures = 0,
            fallback_connections = 0,
            endpoint_conductivity_distance = math.max(0, tonumber(circuit_settings.endpoint_conductivity_distance) or 0),
            wire_type_name = circuit_type,
            max_length = circuit_maximum,
            replicated_wire = replicated,
            chosen_edges = {},
            note = "All old endpoints already belong to one electrical component. No new circuit wire is necessary.",
        }
    end

    local edges = {}
    for component_a = 1, #components do
        for component_b = component_a + 1, #components do
            local connection = circuit_find_connection(components[component_a], components[component_b])
            if connection then
                table.insert(edges, {
                    component_a = component_a,
                    component_b = component_b,
                    start_node = connection.endpoint_node_a,
                    finish_node = connection.endpoint_node_b,
                    start_position = connection.position_a,
                    finish_position = connection.position_b,
                    distance = connection.distance,
                    connector_length = connection.connector_length,
                    effective_length = connection.connector_length + connection.endpoint_arc_total,
                    endpoint_arc_total = connection.endpoint_arc_total,
                    endpoint_arc_a = connection.endpoint_arc_a,
                    endpoint_arc_b = connection.endpoint_arc_b,
                    estimated_wires = connection.estimated_wires,
                    effective_length = connection.effective_length,
                    route = nil,
                    source_record = connection.source_record,
                    target_record = connection.target_record,
                    contact = connection,
                })
            end
        end
    end

    local chosen_edges = circuit_kruskal(#components, edges)
    if #chosen_edges < #components - 1 then
        return nil, string.format(
            "Could not connect all electrical components. Connected %d of %d.",
            #chosen_edges + 1,
            #components
        )
    end

    for edge_index, edge in ipairs(chosen_edges) do
        local route, route_error = circuit_build_connection_route(edge.contact)
        if not route then
            return nil,
                "Failed to build endpoint-tracing route for circuit connection #"
                .. tostring(edge_index)
                .. ": "
                .. tostring(route_error)
        end
        local route_ok, route_validation_error = circuit_validate_endpoint_route(route, edge.contact)
        if not route_ok then
            return nil,
                "Failed to validate endpoint-tracing route for circuit connection #"
                .. tostring(edge_index)
                .. ": "
                .. tostring(route_validation_error)
        end

        edge.route = route
    end

    local final_wires = {}
    local total_route_length = 0
    local connector_length = 0
    local effective_route_length = 0
    local split_failures = 0

    for edge_index, edge in ipairs(chosen_edges) do
        local route = edge.route
        local route_length = circuit_route_length(route)
        if route_length == math.huge then
            split_failures += 1
            return nil, "Selected circuit connection #" .. tostring(edge_index) .. " contains invalid points."
        end

        local expected_start
        if edge.contact.endpoint_at_start_a then
            expected_start = edge.contact.source_record.wire[1]
        else
            expected_start = edge.contact.source_record.wire[#edge.contact.source_record.wire]
        end

        local expected_finish
        if edge.contact.endpoint_at_start_b then
            expected_finish = edge.contact.target_record.wire[1]
        else
            expected_finish = edge.contact.target_record.wire[#edge.contact.target_record.wire]
        end

        if circuit_distance(route[1], expected_start) > tolerance + length_eps
            or circuit_distance(route[#route], expected_finish) > tolerance + length_eps
        then
            split_failures += 1
            return nil, "Selected circuit connection #" .. tostring(edge_index) .. " does not terminate at both old endpoints."
        end

        total_route_length += route_length
        connector_length += edge.connector_length
        effective_route_length += edge.effective_length

        local wires, split_error = circuit_route_to_wires(
            route,
            min_distance,
            circuit_split_maximum
        )

        if not wires then
            split_failures += 1
            return nil,
                "Failed to split selected circuit connection #"
                .. tostring(edge_index)
                .. ": "
                .. tostring(split_error)
        end

        for _, wire in ipairs(wires) do
            local info = inspect_wire_for_type(wire, circuit_type)
            if not info.valid then
                split_failures += 1
                return nil, string.format(
                    "Circuit connection #%d produced an invalid Wire segment: total=%.6f, min_segment=%.6f.",
                    edge_index,
                    info.total_length or 0,
                    info.min_segment or 0
                )
            end
            table.insert(final_wires, wire)
        end
    end

    local final_art = {}
    if #final_wires > 0 then
        table.insert(final_art, final_wires)
    end

    local validation = ArtPipeline.validate(final_art)
    if validation.invalid ~= 0 then
        return nil, "Circuit validation failed: " .. tostring(validation.errors[1] or "unknown error")
    end

    return {
        art = final_art,
        validation = validation,
        drawable = final_art,
        source_wires = #wire_records,
        new_wires = #final_wires,
        node_count = #nodes,
        component_count = #components,
        connector_count = #chosen_edges,
        connector_length = connector_length,
        route_length = total_route_length,
        effective_route_length = effective_route_length,
        estimated_tree_wires = #final_wires,
        split_failures = split_failures,
        fallback_connections = 0,
        endpoint_conductivity_distance = math.max(0, tonumber(circuit_settings.endpoint_conductivity_distance) or 0),
        wire_type_name = circuit_type,
        max_length = circuit_maximum,
        replicated_wire = replicated,
        chosen_edges = chosen_edges,
        note = "New wires connect the shortest legal points on different old-wire trajectories. Existing old wires provide the hidden path to their endpoints.",
    }
end

-- Filters generated art to only the wires that can be rendered in the preview.
function ArtPipeline.filter_short_wires(source_art)
    local result = {}
    local report = {
        source_wires = ArtPipeline.count_wires(source_art),
        drawn_wires = 0,
        short_wires = 0,
        too_long_wires = 0,
        malformed_wires = 0,
        total_omitted = 0,
        short_numbers = {},
        too_long_numbers = {},
        malformed_numbers = {}}
    local global_number = 0
    for _, mini_art in ipairs(source_art) do
        local result_mini_art = {}
        for _, wire in ipairs(mini_art) do
            global_number += 1
            local info = inspect_wire(wire)
            if info.valid then
                table.insert(result_mini_art, wire)
                report.drawn_wires += 1
            else
                report.total_omitted += 1
                if info.too_short then
                    report.short_wires += 1
                    table.insert(report.short_numbers, global_number)
                end
                if info.too_long then
                    report.too_long_wires += 1
                    table.insert(report.too_long_numbers, global_number)
                end
                if info.malformed then
                    report.malformed_wires += 1
                    table.insert(report.malformed_numbers, global_number)
                end
            end
        end
        if #result_mini_art > 0 then
            table.insert(result, result_mini_art)
        end
    end
    return result, report
end

-- Assigns stable global numbers to generated wires.
function ArtPipeline.index_wires(source_art)
    local result = {}
    local number = 0
    wire_number_by_table = {}
    for mini_index, mini_art in ipairs(source_art or {}) do
        for wire_index, wire in ipairs(mini_art) do
            number += 1
            wire_number_by_table[wire] = number
            table.insert(result, {number = number, mini_index = mini_index, wire_index = wire_index, wire = wire})
        end
    end
    return result
end

-- Formats sorted wire numbers as compact numeric ranges.
function format_number_ranges(numbers, maximum_ranges)
    maximum_ranges = maximum_ranges or 20
    if not numbers or #numbers == 0 then
        return ""
    end
    local result = {}
    local start_number = numbers[1]
    local previous = numbers[1]
    local range_count = 0
    local function flush_range(range_start, range_end)
        if range_count >= maximum_ranges then
            return false
        end
        if range_start == range_end then
            table.insert(result, tostring(range_start))
        else
            table.insert(result, tostring(range_start) .. "-" .. tostring(range_end))
        end
        range_count += 1
        return true
    end
    for i = 2, #numbers do
        local current = numbers[i]
        if current == previous + 1 then
            previous = current
        else
            if not flush_range(start_number, previous) then
                table.insert(result, "...")
                return table.concat(result, ", ")
            end
            start_number = current
            previous = current
        end
    end
    flush_range(start_number, previous)
    return table.concat(result, ", ")
end

-- Checks whether a preview wire entry has been permanently deleted.
function is_wire_deleted_entry(entry)
    if not entry then
        return false
    end
    return deleted_wire_numbers[entry.number] == true or deleted_wire_refs[entry.wire] == true
end

-- Selects the requested numbered wire range for the preview.
function ArtPipeline.select_wire_range(source_art, first_wire, last_wire, indexed_entries, include_non_correct)
    first_wire = math.floor(tonumber(first_wire) or 1)
    last_wire = tonumber(last_wire)
    if first_wire < 1 then
        first_wire = 1
    end
    if last_wire == nil then
        last_wire = math.huge
    end
    if last_wire ~= math.huge then
        last_wire = math.floor(last_wire)
    end

    include_non_correct = include_non_correct == nil and show_non_correct or include_non_correct

    local entries = indexed_entries or ArtPipeline.index_wires(source_art)
    local total_wires = #entries
    local result = {}
    local groups = {}
    local report = {
        first = first_wire,
        last = last_wire,
        total_generated = total_wires,
        requested_count = 0,
        rendered_wires = 0,
        short_wires = 0,
        too_long_wires = 0,
        malformed_wires = 0,
        omitted_total = 0,
        non_correct_rendered = 0,
        deleted_wires = 0,
        missing_ranges = {},
        deleted_numbers = {},
        short_numbers = {},
        too_long_numbers = {},
        malformed_numbers = {},
        non_correct_numbers = {}
    }

    if first_wire > last_wire then
        return result, report, entries
    end

    if last_wire == math.huge then
        report.requested_count = math.max(total_wires - first_wire + 1, 0)
    else
        report.requested_count = math.max(last_wire - first_wire + 1, 0)
    end

    if total_wires < first_wire then
        table.insert(report.missing_ranges, {first_wire, last_wire})
    elseif last_wire ~= math.huge and last_wire > total_wires then
        table.insert(report.missing_ranges, {math.max(first_wire, total_wires + 1), last_wire})
    end

    for _, entry in ipairs(entries) do
        if entry.number < first_wire then
            continue
        end
        if entry.number > last_wire then
            break
        end

        if is_wire_deleted_entry(entry) then
            report.deleted_wires += 1
            table.insert(report.deleted_numbers, entry.number)
            continue
        end

        local info = inspect_wire(entry.wire)

        if not info.valid then
            if info.too_short then
                report.short_wires += 1
                table.insert(report.short_numbers, entry.number)
            end
            if info.too_long then
                report.too_long_wires += 1
                table.insert(report.too_long_numbers, entry.number)
            end
            if info.malformed then
                report.malformed_wires += 1
                table.insert(report.malformed_numbers, entry.number)
            end

            if include_non_correct then
                report.non_correct_rendered += 1
                table.insert(report.non_correct_numbers, entry.number)
            else
                report.omitted_total += 1
                continue
            end
        end

        local group = groups[entry.mini_index]
        if not group then
            group = {mini_index = entry.mini_index, wires = {}}
            groups[entry.mini_index] = group
        end
        table.insert(group.wires, entry.wire)
        report.rendered_wires += 1
    end

    local sorted_group_indices = {}
    for mini_index in pairs(groups) do
        table.insert(sorted_group_indices, mini_index)
    end
    table.sort(sorted_group_indices)

    for _, mini_index in ipairs(sorted_group_indices) do
        table.insert(result, groups[mini_index].wires)
    end

    return result, report, entries
end

-- Formats missing wire numbers as compact ranges.
function format_missing_ranges(ranges, maximum_ranges)
    maximum_ranges = maximum_ranges or 20
    if not ranges or #ranges == 0 then
        return ""
    end
    local result = {}
    for i = 1, math.min(#ranges, maximum_ranges) do
        local range = ranges[i]
        local first = range[1]
        local last = range[2]
        if last == math.huge then
            table.insert(result, tostring(first) .. "-END")
        elseif first == last then
            table.insert(result, tostring(first))
        else
            table.insert(result, tostring(first) .. "-" .. tostring(last))
        end
    end
    if #ranges > maximum_ranges then
        table.insert(result, "...")
    end
    return table.concat(result, ", ")
end

-- Formats a first-to-last preview range as text.
function get_range_text(first_wire, last_wire)
    if first_wire > last_wire then
        return "empty"
    end
    if last_wire == math.huge then
        return tostring(first_wire) .. "-END"
    end
    return tostring(first_wire) .. "-" .. tostring(last_wire)
end

-- Prints the current preview range and omission report.
function print_preview_range_report(report, action)
    local prefix = action and "[" .. action .. "] " or ""
    print(prefix .. "Preview range: " .. get_range_text(report.first, report.last) .. " | Rendered: " .. tostring(report.rendered_wires) .. "/" .. tostring(report.requested_count))
    if report.non_correct_rendered > 0 then
        print(prefix .. "Incorrect wires shown in red: " .. tostring(report.non_correct_rendered))
    end
    if #report.missing_ranges > 0 then
        report_warn(prefix .. "Requested wire numbers not found: " .. format_missing_ranges(report.missing_ranges))
    end
    if report.omitted_total > 0 then
        report_warn(prefix .. "Not rendered (incorrect): " .. tostring(report.omitted_total))
    end
    if #report.short_numbers > 0 and not show_non_correct then
        report_warn(prefix .. "Not rendered (< " .. tostring(min_distance) .. "): " .. format_number_ranges(report.short_numbers))
    end
    if #report.too_long_numbers > 0 and not show_non_correct then
        report_warn(prefix .. "Not rendered (too long): " .. format_number_ranges(report.too_long_numbers))
    end
    if #report.malformed_numbers > 0 and not show_non_correct then
        report_warn(prefix .. "Not rendered (malformed): " .. format_number_ranges(report.malformed_numbers))
    end
    if #report.deleted_numbers > 0 then
        report_warn(prefix .. "Deleted permanently: " .. format_number_ranges(report.deleted_numbers))
    end
end

-- Applies a new preview range while preserving the current placement state.
function apply_preview_range(action, rebuild_preview)
    local selected_art, report, entries = ArtPipeline.select_wire_range(generated_art, preview_first_wire, preview_last_wire, generated_wire_entries)
    art = selected_art
    generated_wire_entries = entries
    current_preview_report = report
    if rebuild_preview then
        local was_placing = preview_placing
        local was_mouse_following = preview_connection ~= nil
        local old_position = preview_position
        local old_rotation = preview_rotation
        local old_anchor = preview_anchor
        local had_visual_content = preview_model and #preview_model:GetChildren() > 0
        preview_destroy()
        preview_create(art, old_position, old_rotation, had_visual_content and old_anchor or nil)
        if was_placing then
            preview_start_placement(art, was_mouse_following)
        end
    end
    print_preview_range_report(report, action)
    return art, report
end

-- Finds the first currently rendered wire entry.
function find_first_rendered_wire()
    for _, entry in ipairs(generated_wire_entries) do
        if entry.number < preview_first_wire then
            continue
        end
        if entry.number > preview_last_wire then
            break
        end
        if not is_wire_deleted_entry(entry) and (inspect_wire(entry.wire).valid or show_non_correct) then
            return entry
        end
    end
    return nil
end

-- Finds the last currently rendered wire entry.
function find_last_rendered_wire()
    local result = nil
    for _, entry in ipairs(generated_wire_entries) do
        if entry.number < preview_first_wire then
            continue
        end
        if entry.number > preview_last_wire then
            break
        end
        if not is_wire_deleted_entry(entry) and (inspect_wire(entry.wire).valid or show_non_correct) then
            result = entry
        end
    end
    return result
end

-- Finds the nearest renderable wire before the current first boundary.
function find_previous_rendered_wire(number)
    for i = #generated_wire_entries, 1, -1 do
        local entry = generated_wire_entries[i]
        if entry.number >= number then
            continue
        end
        if not is_wire_deleted_entry(entry) and (inspect_wire(entry.wire).valid or show_non_correct) then
            return entry
        end
    end
    return nil
end

-- Finds the nearest renderable wire after the current last boundary.
function find_next_rendered_wire(number)
    for _, entry in ipairs(generated_wire_entries) do
        if entry.number <= number then
            continue
        end
        if not is_wire_deleted_entry(entry) and (inspect_wire(entry.wire).valid or show_non_correct) then
            return entry
        end
    end
    return nil
end

-- Removes the first currently rendered wire from the preview range.
function preview_remove_first_wire()
    local entry = find_first_rendered_wire()
    if not entry then
        report_warn("[Z] There are no rendered wires to remove.")
        return
    end
    preview_first_wire = entry.number + 1
    apply_preview_range("Z", true)
    if current_preview_report.rendered_wires == 0 then
        print("[Z] Removed final rendered wire #" .. tostring(entry.number))
    end
end

-- Adds one renderable wire before the current first preview wire.
function preview_add_first_wire()
    local entry = find_previous_rendered_wire(preview_first_wire)
    if not entry then
        report_warn("[X] The first rendered wire is already shown.")
        return
    end
    preview_first_wire = entry.number
    apply_preview_range("X", true)
end

-- Removes the last currently rendered wire from the preview range.
function preview_remove_last_wire()
    local entry = find_last_rendered_wire()
    if not entry then
        report_warn("[V] There are no rendered wires to remove.")
        return
    end
    preview_last_wire = entry.number - 1
    apply_preview_range("V", true)
end

-- Adds one renderable wire after the current last preview wire.
function preview_add_last_wire()
    local entry = find_next_rendered_wire(preview_last_wire)
    if not entry then
        report_warn("[C] The last rendered wire is already shown.")
        return
    end
    preview_last_wire = entry.number
    apply_preview_range("C", true)
end

-- Prints the main art-processing and rendering report.
function ArtPipeline.print_report(generated, drawable, preview_report, split_report)
    local generated_count = ArtPipeline.count_wires(generated)
    local drawable_count = ArtPipeline.count_wires(drawable)
    print("")
    print("============= ART REPORT =============")
    print("Generated wires:", generated_count)
    print("Rendered wires:", drawable_count)
    print("Missing from preview - short segment:", preview_report.short_wires)
    print("Missing from preview - too long:", preview_report.too_long_wires)
    print("Missing from preview - malformed:", preview_report.malformed_wires)
    print("Missing from preview - TOTAL:", preview_report.total_omitted)
    if split_report then
        print("Mini-arts too short:", split_report.too_short_lists)
        print("Split failures:", split_report.split_failed_lists)
        print("Extra-piece splits:", split_report.extra_piece_splits)
    end
    print("=======================================")
end

-- Runs the complete art-processing pipeline from source vectors to preview art.
function process_art(source_vectors)

    local filtered = ArtPipeline.filter(source_vectors)
    local scaled, scale_report = ArtPipeline.rescale(filtered)
    local normalized = ArtPipeline.normalize(scaled)

    local generated, split_report = ArtPipeline.split(
        normalized,
        min_distance,
        split_max_len
    )

    local validation = ArtPipeline.validate(generated)
    local full_drawable, full_preview_report = ArtPipeline.filter_short_wires(generated)

    return {
        filtered = filtered,
        normalized = normalized,
        scaled = scaled,
        generated = generated,
        drawable = full_drawable,
        scale_report = scale_report,
        split_report = split_report,
        validation = validation,
        preview_report = full_preview_report
    }
end

-- Creates and configures a preview Part instance.
function create_part(name, size, cframe, parent, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or wire_color
    part.Material = Enum.Material.Plastic
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = true
    part.Parent = parent or preview_model
    return part
end

-- Stops the active mouse-follow placement connection.
function preview_stop_placement()
    preview_placing = false
    safe_disconnect(preview_connection)
    preview_connection = nil
end

-- Destroys the current preview model and placement state.
function preview_destroy()
    preview_stop_placement()
    if preview_model then
        pcall(function()
            preview_model:Destroy()
        end)
        preview_model = nil
    end
    preview_wire_models = {}
    preview_position = Vector3.zero
    preview_rotation = 0
    preview_anchor = Vector3.zero
end

-- Creates a cylindrical preview line segment between two points.
function preview_create_line(p1, p2, parent, color)
    local direction = p2 - p1
    local length = direction.Magnitude
    if length <= eps then
        return
    end
    local center = (p1 + p2) / 2
    local y_axis = direction.Unit
    local reference = Vector3.yAxis
    if math.abs(y_axis:Dot(reference)) > 0.999 then
        reference = Vector3.xAxis
    end
    local x_axis = reference:Cross(y_axis).Unit
    local z_axis = x_axis:Cross(y_axis).Unit
    local cframe = CFrame.fromMatrix(center, x_axis, y_axis, z_axis)
    local part = create_part("Line", Vector3.new(line_width, length, line_width), cframe, parent, color)
    part.Shape = Enum.PartType.Block
    local mesh = Instance.new("CylinderMesh")
    mesh.Parent = part
end

-- Creates a preview endpoint part with the selected wire type geometry.
function preview_create_end(position, direction, parent, color)
    if direction.Magnitude <= eps then
        return
    end
    local x_axis = direction.Unit
    local reference = Vector3.yAxis
    if math.abs(x_axis:Dot(reference)) > 0.999 then
        reference = Vector3.zAxis
    end
    local y_axis = reference:Cross(x_axis).Unit
    local z_axis = x_axis:Cross(y_axis).Unit
    local cframe = CFrame.fromMatrix(position, x_axis, y_axis, z_axis)
    local part = create_part("End", end_size, cframe, parent, color)
    part.Shape = Enum.PartType.Cylinder
end

-- Creates a preview point part for an interior vertex.
function preview_create_point(position, parent, color)
    local part = create_part("Point", point_size, CFrame.new(position), parent, color)
    part.Shape = Enum.PartType.Ball
end

-- Creates the complete preview geometry for one wire.
function preview_create_wire(wire, wire_model, color)
    if #wire < 2 then
        return
    end
    local start_direction = wire[2] - wire[1]
    local end_direction = wire[#wire] - wire[#wire - 1]
    preview_create_end(wire[1], start_direction, wire_model, color)
    for i = 2, #wire - 1 do
        preview_create_point(wire[i], wire_model, color)
    end
    preview_create_end(wire[#wire], end_direction, wire_model, color)
    for i = 1, #wire - 1 do
        preview_create_line(wire[i], wire[i + 1], wire_model, color)
    end
end

-- Creates one preview wire using the visual settings of a specific type.
function preview_create_wire_for_type(wire, wire_model, type_name, color)
    local stats = wire_stats[type_name] or wire_stats.Wire

    local old_line_width = line_width
    local old_end_size = end_size
    local old_point_size = point_size

    line_width = stats.line_width
    end_size = stats.end_size
    point_size = stats.point_size

    preview_create_wire(wire, wire_model, color or stats.wire_color)

    line_width = old_line_width
    end_size = old_end_size
    point_size = old_point_size
end

-- Returns the world-space bottom Y coordinate of a part.
function get_part_bottom_y(part)
    local cf = part.CFrame
    local size = part.Size
    local half_x = size.X / 2
    local half_y = size.Y / 2
    local half_z = size.Z / 2
    local y_extent = math.abs(cf.XVector.Y) * half_x +
        math.abs(cf.YVector.Y) * half_y +
        math.abs(cf.ZVector.Y) * half_z
    return cf.Position.Y - y_extent
end

-- Calculates the visual bottom of a part from its oriented geometry.
function get_visual_bottom_y(cframe, size)
    local half_x = size.X / 2
    local half_y = size.Y / 2
    local half_z = size.Z / 2
    local y_extent = math.abs(cframe.XVector.Y) * half_x +
        math.abs(cframe.YVector.Y) * half_y +
        math.abs(cframe.ZVector.Y) * half_z
    return cframe.Position.Y - y_extent
end

-- Calculates preview line geometry for a segment without creating it.
function get_preview_line_geometry(p1, p2)
    local direction = p2 - p1
    local length = direction.Magnitude
    if length <= eps then
        return nil, nil
    end

    local center = (p1 + p2) / 2
    local y_axis = direction.Unit
    local reference = Vector3.yAxis
    if math.abs(y_axis:Dot(reference)) > 0.999 then
        reference = Vector3.xAxis
    end
    local x_axis = reference:Cross(y_axis).Unit
    local z_axis = x_axis:Cross(y_axis).Unit
    local cframe = CFrame.fromMatrix(center, x_axis, y_axis, z_axis)
    local size = Vector3.new(line_width, length, line_width)
    return cframe, size
end

-- Calculates preview endpoint geometry without creating an instance.
function get_preview_end_geometry(position, direction)
    if direction.Magnitude <= eps then
        return nil, nil
    end

    local x_axis = direction.Unit
    local reference = Vector3.yAxis
    if math.abs(x_axis:Dot(reference)) > 0.999 then
        reference = Vector3.zAxis
    end
    local y_axis = reference:Cross(x_axis).Unit
    local z_axis = x_axis:Cross(y_axis).Unit
    local cframe = CFrame.fromMatrix(position, x_axis, y_axis, z_axis)
    return cframe, end_size
end

-- Returns the configured anchor mode for the preview.
function get_anchor_mode()
    local mode = tostring(preview_anchor_position or "BottomCenterCenter")

    for y_name, _ in pairs(anchor_y_values) do
        for x_name, _ in pairs(anchor_x_values) do
            for z_name, _ in pairs(anchor_z_values) do
                if mode == y_name .. x_name .. z_name then
                    return y_name, x_name, z_name
                end
            end
        end
    end

    report_warn("Invalid preview_anchor_position '" .. mode .. "'. Using 'BottomCenterCenter'.")
    return "Bottom", "Center", "Center"
end

-- Expands visual bounds using an oriented part.
function add_visual_bounds_from_part(bounds, cframe, size)
    if not bounds or not cframe or not size then
        return
    end

    local half_x = size.X / 2
    local half_y = size.Y / 2
    local half_z = size.Z / 2

    local center = cframe.Position

    local extent_x =
        math.abs(cframe.XVector.X) * half_x +
        math.abs(cframe.YVector.X) * half_y +
        math.abs(cframe.ZVector.X) * half_z

    local extent_y =
        math.abs(cframe.XVector.Y) * half_x +
        math.abs(cframe.YVector.Y) * half_y +
        math.abs(cframe.ZVector.Y) * half_z

    local extent_z =
        math.abs(cframe.XVector.Z) * half_x +
        math.abs(cframe.YVector.Z) * half_y +
        math.abs(cframe.ZVector.Z) * half_z

    bounds.min_x = math.min(bounds.min_x, center.X - extent_x)
    bounds.min_y = math.min(bounds.min_y, center.Y - extent_y)
    bounds.min_z = math.min(bounds.min_z, center.Z - extent_z)

    bounds.max_x = math.max(bounds.max_x, center.X + extent_x)
    bounds.max_y = math.max(bounds.max_y, center.Y + extent_y)
    bounds.max_z = math.max(bounds.max_z, center.Z + extent_z)

    bounds.found = true
end

-- Calculates the placement anchor from the full visual art bounds.
function calculate_visual_anchor(source_art, rotation_degrees)
    local anchor_source = placement_reference_art or generated_art

    if type(anchor_source) ~= "table" or #anchor_source == 0 then
        anchor_source = source_art
    end

    if type(anchor_source) ~= "table" then
        return Vector3.zero
    end

    local rotation = CFrame.Angles(0, math.rad(tonumber(rotation_degrees) or 0), 0)
    local width_axis_world = rotation:VectorToWorldSpace(art_local_x_axis)
    local height_axis_world = rotation:VectorToWorldSpace(art_height_axis)
    local depth_axis_world = width_axis_world:Cross(height_axis_world)

    if depth_axis_world.Magnitude <= eps then
        depth_axis_world = Vector3.yAxis:Cross(width_axis_world)
    end
    if depth_axis_world.Magnitude <= eps then
        depth_axis_world = Vector3.zAxis
    else
        depth_axis_world = depth_axis_world.Unit
    end

    local bounds = {
        min_width = math.huge,
        min_height = math.huge,
        min_depth = math.huge,
        max_width = -math.huge,
        max_height = -math.huge,
        max_depth = -math.huge,
        found = false,
    }

    local function add_oriented_visual_bounds(cframe, size)
        if not cframe or not size then
            return
        end

        local half_x = size.X * 0.5
        local half_y = size.Y * 0.5
        local half_z = size.Z * 0.5
        local center = cframe.Position

        local width_center = center:Dot(width_axis_world)
        local height_center = center:Dot(height_axis_world)
        local depth_center = center:Dot(depth_axis_world)

        local width_extent =
            math.abs(cframe.XVector:Dot(width_axis_world)) * half_x +
            math.abs(cframe.YVector:Dot(width_axis_world)) * half_y +
            math.abs(cframe.ZVector:Dot(width_axis_world)) * half_z

        local height_extent =
            math.abs(cframe.XVector:Dot(height_axis_world)) * half_x +
            math.abs(cframe.YVector:Dot(height_axis_world)) * half_y +
            math.abs(cframe.ZVector:Dot(height_axis_world)) * half_z

        local depth_extent =
            math.abs(cframe.XVector:Dot(depth_axis_world)) * half_x +
            math.abs(cframe.YVector:Dot(depth_axis_world)) * half_y +
            math.abs(cframe.ZVector:Dot(depth_axis_world)) * half_z

        bounds.min_width = math.min(bounds.min_width, width_center - width_extent)
        bounds.max_width = math.max(bounds.max_width, width_center + width_extent)
        bounds.min_height = math.min(bounds.min_height, height_center - height_extent)
        bounds.max_height = math.max(bounds.max_height, height_center + height_extent)
        bounds.min_depth = math.min(bounds.min_depth, depth_center - depth_extent)
        bounds.max_depth = math.max(bounds.max_depth, depth_center + depth_extent)
        bounds.found = true
    end

    for _, mini_art in ipairs(anchor_source) do
        if type(mini_art) == "table" then
            for _, wire in ipairs(mini_art) do
                if type(wire) == "table" and #wire >= 2 then
                    local first_position = rotation:PointToWorldSpace(wire[1])
                    local first_direction = rotation:VectorToWorldSpace(wire[2] - wire[1])
                    local last_position = rotation:PointToWorldSpace(wire[#wire])
                    local last_direction = rotation:VectorToWorldSpace(wire[#wire] - wire[#wire - 1])

                    do
                        local cframe, size = get_preview_end_geometry(first_position, first_direction)
                        add_oriented_visual_bounds(cframe, size)
                    end

                    for point_index = 2, #wire - 1 do
                        local position = rotation:PointToWorldSpace(wire[point_index])
                        add_oriented_visual_bounds(CFrame.new(position), point_size)
                    end

                    do
                        local cframe, size = get_preview_end_geometry(last_position, last_direction)
                        add_oriented_visual_bounds(cframe, size)
                    end

                    for segment_index = 1, #wire - 1 do
                        local p1 = rotation:PointToWorldSpace(wire[segment_index])
                        local p2 = rotation:PointToWorldSpace(wire[segment_index + 1])
                        local cframe, size = get_preview_line_geometry(p1, p2)
                        add_oriented_visual_bounds(cframe, size)
                    end
                end
            end
        end
    end

    if not bounds.found then
        return Vector3.zero
    end

    local y_name, x_name, z_name = get_anchor_mode()
    local x_ratio = anchor_x_values[x_name]
    local y_ratio = anchor_y_values[y_name]
    local z_ratio = anchor_z_values[z_name]

    local actual_width = bounds.max_width - bounds.min_width
    local actual_height = bounds.max_height - bounds.min_height
    local actual_depth = bounds.max_depth - bounds.min_depth

    local custom_width = tonumber(default_art_width)
    local custom_height = tonumber(default_art_height)
    local effective_width = (custom_width and custom_width > 0) and custom_width or actual_width
    local effective_height = (custom_height and custom_height > 0) and custom_height or actual_height
    local effective_depth = actual_depth

    local center_width = (bounds.min_width + bounds.max_width) * 0.5
    local center_height = (bounds.min_height + bounds.max_height) * 0.5
    local center_depth = (bounds.min_depth + bounds.max_depth) * 0.5

    local world_anchor =
        width_axis_world * (center_width + x_ratio * 0.5 * effective_width) +
        height_axis_world * (center_height + y_ratio * 0.5 * effective_height) +
        depth_axis_world * (center_depth + z_ratio * 0.5 * effective_depth)

    return rotation:Inverse():PointToWorldSpace(world_anchor)
end

-- Sets the preview model position using the current anchor and rotation.
function preview_set_position(position)
    if not preview_model then
        return
    end
    preview_position = position
    local rotation = CFrame.Angles(0, math.rad(preview_rotation), 0)
    preview_model:PivotTo(CFrame.new(position) * rotation)
end

-- Builds the preview model and places its visual geometry.
function preview_create(source_art, restore_position, restore_rotation, restore_anchor)
    preview_destroy()
    preview_rotation = restore_rotation or 0
    preview_model = Instance.new("Model")
    preview_model.Name = preview_model_name
    preview_model.Parent = Workspace
    local visual_wire_index = 0
    for _, mini_art in ipairs(source_art or {}) do
        for _, wire in ipairs(mini_art) do
            visual_wire_index += 1
            local wire_number = wire_number_by_table[wire]
            local valid = inspect_wire(wire).valid
            local wire_model = Instance.new("Model")
            if wire_number then
                wire_model.Name = "Wire_" .. tostring(wire_number)
                wire_model:SetAttribute("WireNumber", wire_number)
            else
                wire_model.Name = "Wire_Preview_" .. tostring(visual_wire_index)
                wire_model:SetAttribute("WireNumber", 0)
            end
            wire_model:SetAttribute("NonCorrect", not valid)
            wire_model:SetAttribute("OldWire", false)
            wire_model.Parent = preview_model
            preview_wire_models[wire_model] = {number = wire_number, wire = wire, valid = valid, old = false}
            preview_create_wire(wire, wire_model, valid and wire_color or non_correct_color)
        end
    end

    if circuit_settings.enabled and circuit_settings.show_old_wires and type(circuit_source_art) == "table" then
        local old_wire_index = 0
        local old_stats = wire_stats[wire_type_name] or wire_stats.Wire
        for _, mini_art in ipairs(circuit_source_art) do
            for _, wire in ipairs(mini_art) do
                old_wire_index += 1

                local valid = inspect_wire_for_type(wire, wire_type_name).valid
                local wire_model = Instance.new("Model")
                wire_model.Name = "OldWire_" .. tostring(old_wire_index)
                wire_model:SetAttribute("WireNumber", 0)
                wire_model:SetAttribute("OldWire", true)
                wire_model:SetAttribute("NonCorrect", not valid)
                wire_model.Parent = preview_model

                preview_wire_models[wire_model] = {
                    number = nil,
                    wire = wire,
                    valid = valid,
                    old = true,
                }

                local old_color = valid and old_stats.wire_color or non_correct_color
                preview_create_wire_for_type(wire, wire_model, wire_type_name, old_color)
            end
        end
    end

    if restore_anchor ~= nil then
        preview_anchor = restore_anchor
    else
        local anchor_source = placement_reference_art or generated_art
        if type(anchor_source) ~= "table" or #anchor_source == 0 then
            anchor_source = source_art
        end
        preview_anchor = calculate_visual_anchor(anchor_source, preview_rotation)
    end
    preview_model.WorldPivot = CFrame.new(preview_anchor)
    preview_position = restore_position or Vector3.zero
    preview_set_position(preview_position)
end

-- Rotates the preview by 90 degrees around world Y.
function preview_rotate()
    if not preview_model then
        return
    end

    local was_placing = preview_placing
    local was_mouse_following = preview_connection ~= nil
    local was_using_default_position = preview_using_default_position
    local current_position = preview_position
    local current_mouse_offset = preview_mouse_offset
    local new_rotation = (preview_rotation + preview_rotation_step) % 360

    preview_stop_placement()
    preview_create(art, current_position, new_rotation)

    if was_placing then
        if was_using_default_position then
            preview_placing = true
            preview_using_default_position = true
            preview_mouse_offset = Vector3.zero
            preview_set_position(current_position)
        elseif was_mouse_following then
            preview_start_placement(art, true, current_mouse_offset)
        else
            preview_placing = true
            preview_using_default_position = false
            preview_mouse_offset = current_mouse_offset
            preview_set_position(current_position)
        end
    end
end

-- Applies a manual position delta and preserves it while following the mouse.
function preview_apply_manual_delta(delta)
    if not delta or delta.Magnitude <= eps then
        return
    end

    if preview_placing then
        preview_using_default_position = false
        preview_mouse_offset += delta
        local mouse_position = preview_get_mouse_position()
        if mouse_position then
            preview_set_position(mouse_position + preview_mouse_offset)
        else
            preview_set_position(preview_position + delta)
        end
    else
        preview_set_position(preview_position + delta)
    end
end

-- Checks whether preview movement is currently allowed.
function can_move_preview()
    if preview_placing or preview_locked then
        return true
    end
    report_warn("Preview must be active before moving it.")
    return false
end

-- Returns the world axis used for horizontal preview movement.
function get_horizontal_movement_axis()
    local rotation = CFrame.Angles(0, math.rad(preview_rotation), 0)
    return rotation:VectorToWorldSpace(art_local_x_axis)
end

-- Moves the preview along its configured horizontal art axis.
function preview_move_sideways(direction)
    if not can_move_preview() then
        return
    end

    if invert_horizontal_movement then
        direction = -direction
    end

    local movement_axis = get_horizontal_movement_axis()
    preview_apply_manual_delta(movement_axis * direction)
end

-- Rounds the preview position along its horizontal art axis.
function preview_round_side_position()
    if not can_move_preview() then
        return
    end

    local movement_axis = get_horizontal_movement_axis()
    local side_coordinate = preview_position:Dot(movement_axis)
    local rounded_coordinate = math.round(side_coordinate)

    preview_apply_manual_delta(
        movement_axis * (rounded_coordinate - side_coordinate)
    )
end

-- Moves the preview vertically along world Y.
function preview_move_vertical(direction)
    if not can_move_preview() then
        return
    end

    if invert_vertical_movement then
        direction = -direction
    end

    preview_apply_manual_delta(Vector3.yAxis * direction)
end

-- Rounds the preview position along world Y.
function preview_round_vertical_position()
    if not can_move_preview() then
        return
    end

    local rounded_y = math.round(preview_position.Y)
    preview_apply_manual_delta(
        Vector3.new(preview_position.X, rounded_y, preview_position.Z) - preview_position
    )
end

-- Returns the current mouse or touch screen position used by the preview.
function get_pointer_screen_position()
    if preview_touch_position then
        return preview_touch_position
    end
    return UserInputService:GetMouseLocation()
end

-- Gets the world-space pointer position used for preview placement.
function preview_get_mouse_position()
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end
    local mouse_position = get_pointer_screen_position()
    local ray = camera:ViewportPointToRay(mouse_position.X, mouse_position.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    local local_player = Players.LocalPlayer
    if local_player and local_player.Character then
        table.insert(exclude, local_player.Character)
    end
    if player and player ~= local_player and player.Character then
        table.insert(exclude, player.Character)
    end
    if preview_model then
        table.insert(exclude, preview_model)
    end
    params.FilterDescendantsInstances = exclude
    local result = Workspace:Raycast(ray.Origin, ray.Direction * ray_distance, params)
    if not result then
        return nil
    end
    return result.Position
end

-- Raycasts the preview model to find the wire under the mouse.
function preview_get_wire_hit()
    if not preview_model then
        return nil, nil
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil, nil
    end
    local mouse_position = get_pointer_screen_position()
    local ray = camera:ViewportPointToRay(mouse_position.X, mouse_position.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {preview_model}
    local result = Workspace:Raycast(ray.Origin, ray.Direction * ray_distance, params)
    if not result then
        return nil, nil
    end
    local current = result.Instance
    while current and current.Parent and current.Parent ~= preview_model do
        current = current.Parent
    end
    if not current or current.Parent ~= preview_model then
        return nil, nil
    end
    local info = preview_wire_models[current]
    if not info then
        return nil, nil
    end
    return current, info
end

-- Toggles permanent preview wire deletion mode.
function toggle_deletion_mode()
    if build_running then
        return
    end
    if not preview_locked then
        report_warn("[M] Delete mode is available only after the preview is confirmed with LMB.")
        return
    end
    if not preview_model then
        report_warn("[M] Preview is not available.")
        return
    end
    deletion_mode = not deletion_mode
    if deletion_mode then
        print("[M] DELETE MODE: ON")
        print("Click a preview wire to permanently remove it.")
    else
        print("[M] DELETE MODE: OFF")
    end
end

-- Deletes the preview wire currently under the mouse.
function preview_delete_wire_at_mouse()
    if not preview_locked then
        report_warn("[M] Preview must be confirmed before deleting wires.")
        return
    end
    if not deletion_mode then
        return
    end
    local wire_model, info = preview_get_wire_hit()
    if not wire_model or not info then
        report_warn("[M] No preview wire was found under the cursor.")
        return
    end
    if info.old then
        report_warn("[M] Old art wires are not removable from the preview.")
        return
    end
    if info.number then
        deleted_wire_numbers[info.number] = true
        print("[M] Permanently deleted preview wire #" .. tostring(info.number))
    else
        deleted_wire_refs[info.wire] = true
        print("[M] Permanently deleted an unnumbered preview wire.")
    end

    pcall(function()
        wire_model:Destroy()
    end)
    preview_wire_models[wire_model] = nil

    apply_preview_range("M", true)
    gui_update_position(true)
end

-- Starts mouse-follow placement for the preview.
function preview_start_placement(source_art, force_mouse, restore_mouse_offset)
    if not preview_model then
        preview_create(source_art or art)
    end

    if preview_placing and not force_mouse then
        return
    end

    preview_stop_placement()
    preview_placing = true
    gui_report_set_state("Selecting position")

    if not force_mouse and typeof(default_position) == "Vector3" then
        preview_mouse_offset = Vector3.zero
        preview_using_default_position = true
        preview_set_position(default_position)
        return
    end

    preview_mouse_offset = restore_mouse_offset or Vector3.zero
    preview_using_default_position = false
    preview_connection = RunService.RenderStepped:Connect(function()
        if not preview_placing then
            return
        end

        local ok, err = pcall(function()
            local position = preview_get_mouse_position()
            if position then
                preview_set_position(position + preview_mouse_offset)
            end
        end)

        if not ok then
            report_warn("Preview update error:")
            report_warn(err)
            preview_stop_placement()
        end
    end)
end

-- Returns the current confirmed or preview placement information.
function preview_get_placement()
    if not preview_model then
        return nil
    end
    return {position = preview_position, rotation = preview_rotation, anchor = preview_anchor}
end

-- Transforms source art into world-space coordinates for building.
function preview_get_world_art(source_art)
    source_art = source_art or {}
    local result = {}
    local rotation = CFrame.Angles(0, math.rad(preview_rotation), 0)
    local placement = CFrame.new(preview_position) * rotation
    for _, mini_art in ipairs(source_art) do
        local result_mini_art = {}
        for _, wire in ipairs(mini_art) do
            local result_wire = {}
            for _, point in ipairs(wire) do
                local local_point = point - preview_anchor
                local world_point = placement
                    :PointToWorldSpace(local_point)
                table.insert(result_wire, world_point)
            end
            table.insert(result_mini_art, result_wire)
        end
        table.insert(result, result_mini_art)
    end
    return result
end

-- Confirms the current preview placement and prints its details.
function preview_confirm()
    if not preview_placing then
        return nil
    end
    preview_stop_placement()
    preview_using_default_position = false
    preview_locked = true
    deletion_mode = false
    local placement = preview_get_placement()
    if not placement then
        return nil
    end
    print("========== PREVIEW CONFIRMED ==========")
    print("Position:", placement.position)
    print(string.format("Copy to default_position: Vector3.new(%.9f, %.9f, %.9f)", placement.position.X, placement.position.Y, placement.position.Z))
    print("Rotation:", placement.rotation)
    print("Wire range:", get_range_text(preview_first_wire, preview_last_wire))
    print("Anchor:", placement.anchor)
    print("========================================")
    gui_report_set_state("Art locked")
    return placement
end

-- Returns the wire boxes for the currently active wire type.
function get_boxes()
    return get_boxes_for_type(active_wire_type_name)
end

-- Counts wires that are eligible for building with a given type.
function count_buildable_wires(source_art, type_name)
    local count = 0
    for _, mini_art in ipairs(source_art or {}) do
        for _, wire in ipairs(mini_art) do
            local wire_number = wire_number_by_table[wire]
            local deleted = deleted_wire_refs[wire] == true
                or (wire_number ~= nil and deleted_wire_numbers[wire_number] == true)
            if not deleted and (build_non_correct or inspect_wire_for_type(wire, type_name or active_wire_type_name).valid) then
                count += 1
            end
        end
    end
    return count
end

-- Builds the current inventory and timing report.
function get_build_report()
    local preview_wires = ArtPipeline.count_wires(art)
    local old_wires = 0
    local old_buildable = 0

    if circuit_settings.enabled and type(circuit_source_art) == "table" then
        old_wires = ArtPipeline.count_wires(circuit_source_art)
        old_buildable = count_buildable_wires(circuit_source_art, wire_type_name)
    end

    local correct_wires = 0
    for _, mini_art in ipairs(art or {}) do
        for _, wire in ipairs(mini_art) do
            if inspect_wire_for_type(wire, active_wire_type_name).valid then
                correct_wires += 1
            end
        end
    end

    local build_preview_art = select(
        1,
        ArtPipeline.select_wire_range(
            generated_art,
            preview_first_wire,
            preview_last_wire,
            generated_wire_entries,
            build_non_correct
        )
    )
    local buildable_wires = count_buildable_wires(build_preview_art, active_wire_type_name)

    local generated_wires = ArtPipeline.count_wires(generated_art)
    local required_by_type = {}
    required_by_type[active_wire_type_name] = buildable_wires
    if circuit_settings.enabled and circuit_settings.build_old_wires and old_buildable > 0 then
        required_by_type[wire_type_name] = (required_by_type[wire_type_name] or 0) + old_buildable
    end

    local boxes_by_type = {}
    local missing_by_type = {}
    local total_missing = 0
    local total_required = 0

    for type_name, required in pairs(required_by_type) do
        total_required += required
        local boxes = get_boxes_for_type(type_name)
        boxes_by_type[type_name] = #boxes
        if required > #boxes then
            local missing = required - #boxes
            missing_by_type[type_name] = missing
            total_missing += missing
        end
    end

    local projected_total_wires = total_required
    local projected_correct_wires = circuit_settings.enabled and circuit_settings.build_old_wires
        and (correct_wires + old_buildable)
        or correct_wires

    local build_time_all = math.max(projected_total_wires - 1, 0) * place_delay
    local build_time_correct = math.max(projected_correct_wires - 1, 0) * place_delay

    return {
        generated = generated_wires,
        preview = preview_wires,
        correct = correct_wires,
        buildable = buildable_wires,
        required = total_required,
        boxes = boxes_by_type[active_wire_type_name] or 0,
        boxes_by_type = boxes_by_type,
        required_by_type = required_by_type,
        missing_by_type = missing_by_type,
        missing = total_missing,
        enough = total_missing == 0,
        deleted_preview_wires = current_preview_report and current_preview_report.deleted_wires or 0,
        build_time_all = build_time_all,
        build_time_correct = build_time_correct,
        old_wires = old_wires,
        old_buildable = old_buildable,
        old_boxes = boxes_by_type[wire_type_name] or 0,
        old_shown = circuit_settings.enabled and circuit_settings.show_old_wires or false,
        old_build_enabled = circuit_settings.enabled and circuit_settings.build_old_wires or false,
    }
end

-- Prints the current build and inventory report.
function print_build_report()
    local report = get_build_report()
    local bta = string.format(
        "%d:%02d:%02d",
        math.floor(report.build_time_all / 3600),
        math.floor((report.build_time_all % 3600) / 60),
        report.build_time_all % 60
    )
    local btc = string.format(
        "%d:%02d:%02d",
        math.floor(report.build_time_correct / 3600),
        math.floor((report.build_time_correct % 3600) / 60),
        report.build_time_correct % 60
    )

    print("")
    print("============ BUILD REPORT ============")
    print("Generated wires:", report.generated)
    print("Wires in preview:", report.preview)
    print("Correct wires in preview:", report.correct)
    print("Wires to build:", report.buildable)
    print("Preview range:", get_range_text(preview_first_wire, preview_last_wire))
    print("Build time (all): " .. bta)
    print("Build time (correct): " .. btc)
    print("Delete mode:", deletion_mode and "ON" or "OFF")
    print("Build incorrect:", build_non_correct and "ON" or "OFF")

    print("Required/available by type:")
    local type_names = {}
    for type_name in pairs(report.required_by_type or {}) do
        table.insert(type_names, type_name)
    end
    table.sort(type_names)
    for _, type_name in ipairs(type_names) do
        local required = report.required_by_type[type_name] or 0
        local available = report.boxes_by_type[type_name] or 0
        local missing = math.max(required - available, 0)
        print(
            "  " .. tostring(type_name)
            .. ": " .. tostring(required)
            .. " / " .. tostring(available)
            .. (missing > 0 and (" (missing " .. tostring(missing) .. ")") or "")
        )
    end

    print("Boxes missing total:", report.missing)
    if circuit_settings.enabled then
        print("Old wires shown:", circuit_settings.show_old_wires and "ON" or "OFF")
        print("Old wires built:", circuit_settings.build_old_wires and "ON" or "OFF")
        print("Old wires total:", report.old_wires)
        print("Old wires to build:", report.old_buildable)
        print("Old wire type:", wire_type_name)
    end

    if current_preview_report then
        print("Preview wires not rendered:", current_preview_report.omitted_total)
        print("  short:", current_preview_report.short_wires)
        print("  too long:", current_preview_report.too_long_wires)
        print("  malformed:", current_preview_report.malformed_wires)
        print("  incorrect shown in red:", current_preview_report.non_correct_rendered)
        print("  permanently deleted:", current_preview_report.deleted_wires)
    end
    print("=======================================")
    return report
end

-- Places one wire through the server event using a specific type.
function place_wire_with_type(wire_box, points, type_name)
    if not PlaceWireEvent then
        return false, "ClientPlacedWire event not found."
    end

    local value = tostring(type_name or "")
    local replicated = replicated_wires[value]
    if not replicated then
        return false, "Replicated wire object not found for: " .. value
    end

    local ok, err = pcall(function()
        PlaceWireEvent:FireServer(replicated, points, player, wire_box, true)
    end)
    if not ok then
        return false, err
    end

    return true
end

-- Places one wire using the active wire type.
function place_wire(wire, points)
    return place_wire_with_type(wire, points, active_wire_type_name)
end

-- Waits between wire placements while allowing cancellation.
function wait_build_delay(duration)
    local finish = os.clock() + duration
    while os.clock() < finish do
        if build_cancelled then
            return false
        end
        task.wait(build_poll_interval)
    end
    return true
end

-- Filters source art to only the wires that should be built.
function get_buildable_art(source_art, type_name)
    local result = {}
    for _, mini_art in ipairs(source_art or {}) do
        local result_mini_art = {}
        for _, wire in ipairs(mini_art) do
            local wire_number = wire_number_by_table[wire]
            local deleted = deleted_wire_refs[wire] == true
                or (wire_number ~= nil and deleted_wire_numbers[wire_number] == true)
            if not deleted and (build_non_correct or inspect_wire_for_type(wire, type_name or active_wire_type_name).valid) then
                table.insert(result_mini_art, wire)
            end
        end
        if #result_mini_art > 0 then
            table.insert(result, result_mini_art)
        end
    end
    return result
end

-- Builds all selected old-art and generated wires in their appropriate groups.
function perform_build(source_art)
    if build_cancelled then
        return {status = "cancelled", placed = 0}
    end

    local build_groups = {}

    if circuit_settings.enabled and circuit_settings.build_old_wires and type(circuit_source_art) == "table" then
        local old_source = get_buildable_art(circuit_source_art, wire_type_name)
        local old_world_art = preview_get_world_art(old_source)
        local old_count = ArtPipeline.count_wires(old_world_art)

        if old_count > 0 then
            table.insert(build_groups, {
                type_name = wire_type_name,
                world_art = old_world_art,
                wire_count = old_count,
                label = "old",
            })
        end
    end

    local generated_source = source_art or art
    if build_non_correct then
        generated_source = select(
            1,
            ArtPipeline.select_wire_range(generated_art, preview_first_wire, preview_last_wire, generated_wire_entries, true)
        )
    end

    generated_source = get_buildable_art(generated_source, active_wire_type_name)
    local generated_world_art = preview_get_world_art(generated_source)
    local generated_count = ArtPipeline.count_wires(generated_world_art)
    if generated_count > 0 then
        table.insert(build_groups, {
            type_name = active_wire_type_name,
            world_art = generated_world_art,
            wire_count = generated_count,
            label = circuit_settings.enabled and "circuit" or nil,
        })
    end

    local total_wire_count = 0
    local required_by_type = {}
    for _, group in ipairs(build_groups) do
        total_wire_count += group.wire_count
        required_by_type[group.type_name] = (required_by_type[group.type_name] or 0) + group.wire_count
    end

    if total_wire_count == 0 then
        report_warn("There are no drawable wires.")
        return {status = "no_wires", placed = 0}
    end

    local boxes_by_type = {}
    for type_name, required in pairs(required_by_type) do
        local boxes = get_boxes_for_type(type_name)
        boxes_by_type[type_name] = boxes

        if required > #boxes then
            local missing = required - #boxes
            report_warn("Not enough wire boxes for " .. tostring(type_name) .. ".")
            report_warn("Required:", required)
            report_warn("Available:", #boxes)
            report_warn("Missing:", missing)
            return {
                status = "not_enough_boxes",
                placed = 0,
                required = total_wire_count,
                available = #boxes,
                missing = missing,
                missing_type = type_name,
            }
        end
    end

    local placement = preview_get_placement()
    preview_destroy()

    local box_index_by_type = {}
    local counter = 1

    for _, group in ipairs(build_groups) do
        local type_name = group.type_name
        local boxes = boxes_by_type[type_name]
        local box_index = box_index_by_type[type_name] or 1

        for _, mini_art in ipairs(group.world_art) do
            for _, points in ipairs(mini_art) do
                if build_cancelled then
                    return {status = "cancelled", placed = counter - 1, placement = placement}
                end

                local wire_box = boxes[box_index]
                if not wire_box then
                    error("Wire box #" .. tostring(box_index) .. " for " .. tostring(type_name) .. " is missing.")
                end

                local placed, err = place_wire_with_type(wire_box, points, type_name)
                if not placed then
                    error("Failed to place " .. tostring(group.label) .. " wire #" .. tostring(counter) .. ":\n" .. tostring(err))
                end

                print(
                    "Placed " .. tostring(counter) .. "/" .. tostring(total_wire_count)
                    .. (group.label and (" [" .. tostring(group.label) .. "]") or "")
                    .. " " .. tostring(type_name)
                )
                gui_report_log(
                    "Wire " .. tostring(counter) .. "/" .. tostring(total_wire_count)
                    .. " placed | " .. tostring(type_name)
                )

                counter += 1
                box_index += 1
                box_index_by_type[type_name] = box_index

                if counter <= total_wire_count then
                    if not wait_build_delay(place_delay) then
                        return {status = "cancelled", placed = counter - 1, placement = placement}
                    end
                end
            end
        end
    end

    return {status = "success", placed = total_wire_count, placement = placement}
end

-- Restores the preview after a build operation is cancelled before placement.
function restore_preview(placement)
    preview_locked = false
    deletion_mode = false
    preview_create(art, placement and placement.position or Vector3.zero, placement and placement.rotation or 0)
    preview_start_placement(art)
end

-- Starts a build operation and handles cancellation and errors.
build_art = function(source_art)
    if build_running then
        return false
    end
    if preview_using_default_position and typeof(default_position) == "Vector3" and preview_model then
        preview_set_position(default_position)
    end

    local placement = preview_get_placement()
    if not placement then
        report_warn("Build error: preview placement is unavailable.")
        gui_set_status("Preview placement is unavailable.", true)
        return false
    end
    print(string.format("Build started: Vector3.new(%.9f, %.9f, %.9f)", placement.position.X, placement.position.Y, placement.position.Z))
    source_art = source_art or art
    gui_report_reset()
    gui_report_build_start()
    gui_report_set_state("Art building")
    gui_report_log("Art build started.")
    build_running = true
    build_cancelled = false
    deletion_mode = false

    safe_disconnect(main_inputs)
    main_inputs = nil

    safe_disconnect(build_connection)
    build_connection = nil
    gui_set_status("Build started…")

    local ok, result = xpcall(
        function()
            return perform_build(source_art)
        end,
        function(error_message)
            if debug and debug.traceback then
                return debug.traceback(tostring(error_message))
            end
            return tostring(error_message)
        end
    )

    safe_disconnect(build_connection)
    build_connection = nil
    build_running = false

    if not ok then
        report_warn("Build error:")
        report_warn(result)
        gui_report_log("Build error: " .. tostring(result))
        gui_report_build_finish()
        gui_report_set_state("Art locked")
        cleanup_all(true, true)
        return false
    end

    if result.status == "cancelled" then
        build_cancelled = false
        gui_report_log("Build cancelled.")
        gui_report_build_finish()
        if result.placed == 0 then
            restore_preview(result.placement)
            gui_report_set_state("Selecting position")
        else
            report_warn("Build canceled after " .. tostring(result.placed) .. " wire(s).")
            gui_report_set_state("Art locked")
            cleanup_all(true, true)
            return false
        end
        connect_main_inputs()
        return false
    end

    if result.status == "not_enough_boxes" then
        gui_report_log("Build stopped: not enough wire boxes.")
        gui_report_build_finish()
        gui_report_set_state("Art locked")
        connect_main_inputs()
        return false
    end

    if result.status == "no_wires" then
        gui_report_log("Build stopped: there are no drawable wires.")
        gui_report_build_finish()
        gui_report_set_state("Art locked")
        connect_main_inputs()
        return false
    end

    if result.status == "success" then
        gui_report_log("Art build finished.")
        gui_report_build_finish()
        gui_report_set_state("Art built")
        cleanup_all(true, true)
        print("=============BUILD_COMPLETED=============")
        return true
    end

    report_warn("Unknown build result.")
    cleanup_all(true, true)
    return false
end

-- Connects mouse, touch, and keyboard controls for preview placement.
connect_main_inputs = function()
    safe_disconnect(main_inputs)

    local input_began = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if build_running then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if gameProcessed or gui_mouse_over_ui(input.Position) then
                return
            end

            local ok, err = pcall(function()
                if deletion_mode and preview_locked then
                    preview_delete_wire_at_mouse()
                else
                    preview_confirm()
                end
            end)

            if not ok then
                report_warn("Mouse input error:")
                report_warn(err)
                gui_set_status(tostring(err), true)
            end
            return
        end

        if input.KeyCode == Enum.KeyCode.R then
            if UserInputService:GetFocusedTextBox() then
                return
            end

            local ok, err = pcall(preview_rotate)
            if not ok then
                report_warn("Rotate input error:")
                report_warn(err)
                gui_set_status(tostring(err), true)
            end
        end
    end)

    local touch_started = UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
        if build_running or gameProcessed or gui_mouse_over_ui(touch.Position) then
            return
        end

        preview_touch_input = touch
        preview_touch_position = touch.Position
    end)

    local touch_moved = UserInputService.TouchMoved:Connect(function(touch)
        if touch == preview_touch_input then
            preview_touch_position = touch.Position
        end
    end)

    local touch_ended = UserInputService.TouchEnded:Connect(function(touch)
        if touch == preview_touch_input then
            preview_touch_input = nil
            preview_touch_position = nil
        end
    end)

    local touch_tap = UserInputService.TouchTapInWorld:Connect(function(position, processed_by_ui)
        if build_running or processed_by_ui then
            return
        end

        preview_touch_position = position

        local ok, err = pcall(function()
            if deletion_mode and preview_locked then
                preview_delete_wire_at_mouse()
            else
                preview_confirm()
            end
        end)

        preview_touch_input = nil
        preview_touch_position = nil

        if not ok then
            report_warn("Touch input error:")
            report_warn(err)
            gui_set_status(tostring(err), true)
        end
    end)

    main_inputs = {input_began, touch_started, touch_moved, touch_ended, touch_tap}
end
-- Initializes the art, preview, optional circuit, reports, and input controls.
function initialize()
    if use_test_art then
        generated_art = test_art
        local validation = ArtPipeline.validate(generated_art)
        local full_drawable, full_preview_report = ArtPipeline.filter_short_wires(generated_art)
        pipeline_report = {
            filtered = generated_art,
            normalized = generated_art,
            scaled = generated_art,
            generated = generated_art,
            drawable = full_drawable,
            validation = validation,
            preview_report = full_preview_report,
            split_report = nil,
            scale_report = {enabled = false, applied = false, minimum_before = ArtPipeline.get_art_min_distance(generated_art), scale = 1, center = Vector3.zero}}
    else
        local loaded = load_vectors()
        if #loaded == 0 then
            report_warn("No source vectors loaded.")
            return false
        end
        vectors = loaded
        print("Source vector lists:", #vectors)
        pipeline_report = process_art(vectors)
        vectors = pipeline_report.scaled
    end

    generated_art = pipeline_report.generated
    placement_reference_art = generated_art
    local original_art_size = get_art_size(placement_reference_art)

    if circuit_settings.enabled then
        local ok_type, type_error = set_active_wire_type(circuit_settings.wire_type_name)
        if not ok_type then
            report_warn("Circuit mode initialization failed:")
            report_warn(type_error)
            return false
        end

        circuit_source_art = generated_art
        local generated_circuit, circuit_error = CircuitBuilder.generate(circuit_source_art)
        if not generated_circuit then
            report_warn("Circuit generation failed:")
            report_warn(circuit_error)
            return false
        end

        circuit_report = generated_circuit
        generated_art = generated_circuit.art

        local circuit_drawable, circuit_preview_report = ArtPipeline.filter_short_wires(generated_art)
        pipeline_report.generated = generated_art
        pipeline_report.drawable = circuit_drawable
        pipeline_report.validation = generated_circuit.validation
        pipeline_report.preview_report = circuit_preview_report
        pipeline_report.split_report = nil
    else
        local ok_type, type_error = set_active_wire_type(wire_type_name)
        if not ok_type then
            report_warn(type_error)
            return false
        end
    end

    generated_wire_entries = ArtPipeline.index_wires(generated_art)

    local art_size = original_art_size
    print("Art local X direction:", art_local_x_axis_name)
    print("Art height direction:", art_height_axis_name)
    print(string.format("Art size: width = %.3f studs | height = %.3f studs", art_size.X, art_size.Y))
    print("Horizontal movement axis:", art_local_x_axis_name)
    print("Placement anchor position:", tostring(preview_anchor_position))
    print("Horizontal movement inversion:", invert_horizontal_movement and "ON" or "OFF")
    print("Vertical movement inversion:", invert_vertical_movement and "ON" or "OFF")
    print("Circuit mode:", circuit_settings.enabled and "ON" or "OFF")
    print("Active wire type:", active_wire_type_name)
    if circuit_settings.enabled then
        print("Old wires shown:", circuit_settings.show_old_wires and "ON" or "OFF")
        print("Old wires built:", circuit_settings.build_old_wires and "ON" or "OFF")
    end

    if circuit_report then
        print("")
        print("=========== HIDDEN CIRCUIT REPORT ===========")
        print("Original wires:", circuit_report.source_wires)
        print("Original electrical components:", circuit_report.component_count)
        print("New wires:", circuit_report.new_wires)
        print("Connector count:", circuit_report.connector_count)
        print("Connector geometry length:", circuit_report.connector_length)
        print("Total new route length:", circuit_report.route_length)
        print("Effective electrical route length:", circuit_report.effective_route_length or circuit_report.route_length)
        print("Fallback trajectory connections:", circuit_report.fallback_connections or 0)
        print("=============================================")
    end

    local initial_first = tonumber(preview_first_wire)
    if not initial_first then
        report_warn("Invalid preview_first_wire; using 1.")
        initial_first = 1
    end
    initial_first = math.max(1, math.floor(initial_first))
    local initial_last = tonumber(preview_last_wire)
    if initial_last == nil then
        report_warn("Invalid preview_last_wire; using END.")
        initial_last = math.huge
    end
    if initial_last ~= math.huge then
        initial_last = math.max(1, math.floor(initial_last))
    end
    if initial_last ~= math.huge and initial_last < initial_first then
        report_warn("preview_last_wire is smaller than preview_first_wire; values were swapped.")
        local temp = initial_first
        initial_first = initial_last
        initial_last = temp
    end
    preview_first_wire = initial_first
    preview_last_wire = initial_last
    preview_locked = false
    deletion_mode = false

    apply_preview_range(nil, false)

    print("Initial preview range:", get_range_text(preview_first_wire, preview_last_wire))

    local scale_report = pipeline_report.scale_report
    print("")
    print("============= SCALE REPORT =============")
    print("Rescale enabled:", scale_report.enabled)
    print("Rescale applied:", scale_report.applied)
    print("Scale factor:", scale_report.scale)
    if scale_report.minimum_before == math.huge then
        print("Minimum before scaling: none")
    else
        print("Minimum before scaling:", scale_report.minimum_before)
    end
    print("=========================================")

    local validation = pipeline_report.validation
    if validation.invalid == 0 then
        print("Art validation: OK")
    else
        report_warn("Art validation found " .. tostring(validation.invalid) .. " generated wire(s).")
        report_warn("Short:", validation.short)
        report_warn("Too long:", validation.too_long)
        report_warn("Malformed:", validation.malformed)
        local print_count = math.min(#validation.errors, max_validation_errors)
        for i = 1, print_count do
            report_warn(validation.errors[i])
        end
        if #validation.errors > print_count then
            report_warn("... and " .. tostring(#validation.errors - print_count) .. " more.")
        end
    end

    ArtPipeline.print_report(generated_art, pipeline_report.drawable, pipeline_report.preview_report, pipeline_report.split_report)

    print_build_report()

    return true
end

local TweenService = game:GetService("TweenService")

local GUI_NAME = "WireArtGUI"
local gui_root = nil
local gui_window = nil
local gui_restore = nil
local gui_tabs = {}
local gui_pages = {}
local gui_fields = {}
local gui_connections = {}
local gui_drag_connections = {}
local gui_dragging = false
local gui_drag_start = nil
local gui_window_start = nil
local gui_drag_input = nil
local gui_selected_tab = nil
local gui_position_label = nil
local gui_build_button = nil
local gui_delete_button = nil
local gui_player_dropdown_refresh = nil
local selected_player = Players.LocalPlayer
local gui_last_position_update = 0
local gui_last_status = ""
local gui_last_status_error = false
local gui_report_state = "Selecting position"
local gui_report_initial_first = 1
local gui_report_initial_last = math.huge
local gui_report_build_started_at = nil
local gui_report_build_elapsed = 0
local gui_report_log_lines = {}
local gui_report_status_label = nil
local gui_report_log_label = nil
local gui_report_log_scroll = nil
local gui_report_last_refresh = 0
local gui_move_h_step = 1.0
local gui_move_v_step = 1.0
local gui_move_d_step = 1.0
local gui_mouse_over_window = false
local gui_mouse_over_restore = false
local gui_open_dropdown = nil

-- Checks whether an input is a primary mouse or touch input.
function is_primary_pointer_input(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

-- Returns the current screen viewport size.
function gui_get_viewport()
    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(460, 450)
end

-- Returns whether the GUI should use its compact touch layout.
function gui_is_compact_device()
    local viewport = gui_get_viewport()
    return UserInputService.TouchEnabled and viewport.X < 700
end

-- Returns the lowest usable screen coordinate above the on-screen keyboard.
function gui_get_screen_bottom()
    local viewport = gui_get_viewport()
    local bottom = viewport.Y - 8

    if UserInputService.OnScreenKeyboardVisible then
        local keyboard_top = UserInputService.OnScreenKeyboardPosition.Y
        if keyboard_top > 0 then
            bottom = math.min(bottom, keyboard_top - 8)
        end
    end

    return bottom
end

-- Resizes and repositions the GUI window for the current screen and keyboard state.
function gui_update_window_layout()
    if not gui_window then
        return
    end

    local viewport = gui_get_viewport()
    local compact = gui_is_compact_device()
    local width = math.max(compact and 200 or 240, math.min(460, viewport.X - 16))
    local screen_bottom = gui_get_screen_bottom()
    local available_height = math.max(1, screen_bottom - 8)
    local min_height = math.min(compact and 220 or 320, available_height)
    local height = math.min(450, math.max(min_height, available_height))

    gui_window.Size = UDim2.fromOffset(width, height)

    local x = math.clamp(gui_window.Position.X.Offset, 8, math.max(8, viewport.X - width - 8))
    local y = math.clamp(gui_window.Position.Y.Offset, 8, math.max(8, screen_bottom - height))
    gui_window.Position = UDim2.fromOffset(x, y)
end

-- Scrolls a page so a focused text box remains visible above the mobile keyboard.
function gui_scroll_to_focused_textbox(textbox)
    if not textbox or not textbox:IsA("TextBox") then
        return
    end

    local page = textbox.Parent
    while page and not page:IsA("ScrollingFrame") do
        page = page.Parent
    end

    if not page then
        return
    end

    task.defer(function()
        if not textbox.Parent or not page.Parent then
            return
        end

        local top = textbox.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
        local bottom = top + textbox.AbsoluteSize.Y
        local visible_top = page.CanvasPosition.Y + 6
        local visible_bottom = page.CanvasPosition.Y + page.AbsoluteSize.Y - 6
        local target = page.CanvasPosition.Y

        if top < visible_top then
            target = top - 6
        elseif bottom > visible_bottom then
            target = bottom - page.AbsoluteSize.Y + 6
        end

        local maximum = math.max(0, page.CanvasSize.Y.Offset - page.AbsoluteSize.Y)
        page.CanvasPosition = Vector2.new(0, math.clamp(target, 0, maximum))
    end)
end

local GUI = {
    bg = Color3.fromRGB(14, 19, 16),
    panel = Color3.fromRGB(21, 29, 24),
    panel2 = Color3.fromRGB(28, 39, 32),
    input = Color3.fromRGB(10, 15, 12),
    border = Color3.fromRGB(54, 83, 62),
    accent = Color3.fromRGB(55, 184, 93),
    accent_dark = Color3.fromRGB(32, 118, 59),
    accent_hover = Color3.fromRGB(41, 77, 52),
    text = Color3.fromRGB(234, 244, 237),
    muted = Color3.fromRGB(153, 174, 160),
    danger = Color3.fromRGB(211, 78, 78),
    warning = Color3.fromRGB(211, 163, 70),
}

-- Returns the GUI parent container.
function gui_parent()
    if type(gethui) == "function" then
        local ok, value = pcall(gethui)
        if ok and value then
            return value
        end
    end

    local ok, core_gui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and core_gui then
        return core_gui
    end

    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Safely destroys a GUI instance.
function gui_safe_destroy(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

-- Disconnects all GUI event connections.
function gui_disconnect_all()
    for _, connection in ipairs(gui_connections) do
        safe_disconnect(connection)
    end
    gui_connections = {}
end

-- Creates a GUI instance and applies its properties.
function gui_make(class_name, properties, parent)
    local object = Instance.new(class_name)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

-- Applies rounded corners to a GUI object.
function gui_round(object, radius)
    gui_make("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
    }, object)
end

-- Applies an outline stroke to a GUI object.
function gui_stroke(object, color, thickness, transparency)
    return gui_make("UIStroke", {
        Color = color or GUI.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, object)
end

-- Creates a configured GUI text label.
function gui_label(parent, text_value, height, color, text_size)
    return gui_make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 22),
        Font = Enum.Font.Gotham,
        Text = tostring(text_value or ""),
        TextColor3 = color or GUI.text,
        TextSize = text_size or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
    }, parent)
end

-- Creates a configured GUI button.
function gui_button(parent, text_value, width, height)
    local button = gui_make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = GUI.panel2,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width or 100, height or 29),
        Font = Enum.Font.GothamMedium,
        Text = tostring(text_value or ""),
        TextColor3 = GUI.text,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextWrapped = false,
        ZIndex = 5,
    }, parent)

    gui_round(button, 6)
    gui_stroke(button, GUI.border, 1, 0.25)

    local normal = GUI.panel2
    local hover = GUI.accent_hover
    local press = GUI.accent_dark

    table.insert(gui_connections, button.MouseEnter:Connect(function()
        if button.Active then
            TweenService:Create(button, TweenInfo.new(0.08), {
                BackgroundColor3 = hover,
            }):Play()
        end
    end))

    table.insert(gui_connections, button.MouseLeave:Connect(function()
        if button.Active then
            TweenService:Create(button, TweenInfo.new(0.08), {
                BackgroundColor3 = normal,
            }):Play()
        end
    end))

    table.insert(gui_connections, button.InputBegan:Connect(function(input)
        if button.Active and is_primary_pointer_input(input) then
            TweenService:Create(button, TweenInfo.new(0.05), {
                BackgroundColor3 = press,
            }):Play()
        end
    end))

    table.insert(gui_connections, button.InputEnded:Connect(function(input)
        if button.Active and is_primary_pointer_input(input) then
            TweenService:Create(button, TweenInfo.new(0.05), {
                BackgroundColor3 = hover,
            }):Play()
        end
    end))

    return button
end

-- Creates a configured single-line GUI text box.
function gui_textbox(parent, text_value, placeholder, width, height)
    local box = gui_make("TextBox", {
        ClearTextOnFocus = false,
        BackgroundColor3 = GUI.input,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width or 180, height or 28),
        Font = Enum.Font.Code,
        PlaceholderText = tostring(placeholder or ""),
        PlaceholderColor3 = GUI.muted,
        Text = tostring(text_value or ""),
        TextColor3 = GUI.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 5,
    }, parent)

    gui_round(box, 5)
    gui_stroke(box, GUI.border, 1, 0.38)
    gui_make("UIPadding", {
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
    }, box)
    table.insert(gui_connections, box.Focused:Connect(function()
        gui_scroll_to_focused_textbox(box)
    end))
    return box
end

-- Creates a configured multiline GUI text box.
function gui_multiline_textbox(parent, text_value, placeholder, height)
    local box = gui_make("TextBox", {
        ClearTextOnFocus = false,
        MultiLine = true,
        TextWrapped = false,
        BackgroundColor3 = GUI.input,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 160),
        Font = Enum.Font.Code,
        PlaceholderText = tostring(placeholder or ""),
        PlaceholderColor3 = GUI.muted,
        Text = tostring(text_value or ""),
        TextColor3 = GUI.text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 5,
    }, parent)

    gui_round(box, 5)
    gui_stroke(box, GUI.border, 1, 0.38)
    gui_make("UIPadding", {
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
    }, box)
    table.insert(gui_connections, box.Focused:Connect(function()
        gui_scroll_to_focused_textbox(box)
    end))
    return box
end

-- Creates a large labeled GUI input field.
function gui_large_field(parent, key, title, value, placeholder, height)
    local row = gui_make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, (height or 160) + 24),
        LayoutOrder = 0,
        ZIndex = 3,
    }, parent)

    local label = gui_label(row, title, 17, GUI.muted, 9)
    label.Position = UDim2.fromOffset(0, 0)
    label.Size = UDim2.new(1, 0, 0, 17)
    label.ZIndex = 4

    local box = gui_multiline_textbox(row, value, placeholder, height or 160)
    box.Position = UDim2.fromOffset(0, 19)
    box.Size = UDim2.new(1, 0, 0, height or 160)
    box:SetAttribute("WireArtField", key)
    gui_fields[key] = box

    return row
end

-- Reads the boolean value represented by a checkbox.
function gui_checkbox_value(box)
    return tostring(box.Text or ""):lower():gsub("%s+", "")
end

-- Converts a boolean value into toggle text.
function gui_toggle_value_text(value)
    return value and "ON" or "OFF"
end

-- Creates a GUI row containing a toggle control.
function gui_toggle_row(parent, key, title, value, on_changed)
    local row = gui_make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        LayoutOrder = 0,
        ZIndex = 3,
    }, parent)

    local label = gui_label(row, title, 17, GUI.muted, 10)
    label.Position = UDim2.fromOffset(0, 0)
    label.Size = UDim2.new(1, 0, 0, 17)
    label.ZIndex = 4

    local button = gui_button(row, gui_toggle_value_text(value), 100, 28)
    button.Position = UDim2.fromOffset(0, 19)
    button.Size = UDim2.new(1, 0, 0, 28)
    button.ZIndex = 5
    gui_fields[key] = button

    local function update(new_value)
        button.Text = gui_toggle_value_text(new_value)
        button.TextColor3 = new_value and GUI.accent or GUI.text
    end

    update(value)

    table.insert(gui_connections, button.Activated:Connect(function()
        if build_running then
            gui_set_status("Build is running. Stop the build before changing Circuit settings.", true)
            return
        end

        local current = tostring(button.Text):upper() == "ON"
        local new_value = not current
        update(new_value)
        if on_changed then
            on_changed(new_value)
        end
        gui_update_position(true)
    end))

    return row, button
end

-- Creates a row of GUI toggle fields.
function gui_toggle_field_row(parent, fields, row_height)
    local row = gui_make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, row_height or 50),
        LayoutOrder = 0,
        ZIndex = 3,
    }, parent)

    local count = #fields
    for index, field in ipairs(fields) do
        local left = (index - 1) / count
        local cell = gui_make("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(left, index == 1 and 0 or 3, 0, 0),
            Size = UDim2.new(1 / count, -8, 1, 0),
            ZIndex = 3,
        }, row)

        local label = gui_label(cell, field.title, 17, GUI.muted, 9)
        label.Position = UDim2.fromOffset(0, 0)
        label.Size = UDim2.new(1, 0, 0, 17)
        label.ZIndex = 4

        local button = gui_button(cell, field.value and "ON" or "OFF", 100, 28)
        button.Position = UDim2.fromOffset(0, 19)
        button.Size = UDim2.new(1, 0, 0, 28)
        button.TextColor3 = field.value and GUI.accent or GUI.text
        button:SetAttribute("WireArtField", field.key)
        gui_fields[field.key] = button

        table.insert(gui_connections, button.Activated:Connect(function()
            if build_running then
                gui_set_status("Build is running. Stop the build before changing settings.", true)
                return
            end

            local enabled = tostring(button.Text):upper() ~= "ON"
            button.Text = enabled and "ON" or "OFF"
            button.TextColor3 = enabled and GUI.accent or GUI.text

            local ok_settings, err = gui_apply_settings_from_fields()
            if not ok_settings then
                gui_set_status(err, true)
                gui_refresh_fields()
                return
            end

            gui_set_status("Setting updated.")
            gui_refresh_fields()
        end))
    end

    return row
end

-- Enables or disables a GUI button.
function gui_set_enabled(button, enabled)
    button.Active = enabled
    button.AutoButtonColor = false
    button.TextTransparency = enabled and 0 or 0.45
    button.BackgroundTransparency = enabled and 0 or 0.45
end

-- Creates a scrolling GUI page container.
function gui_page(parent)
    local page = gui_make("ScrollingFrame", {
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasPosition = Vector2.zero,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollingEnabled = true,
        ScrollBarImageColor3 = GUI.accent_dark,
        ScrollBarImageTransparency = 0.2,
        ScrollBarThickness = gui_is_compact_device() and 7 or 4,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 2,
    }, parent)

    gui_make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, page)

    local layout = gui_make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, page)

    table.insert(gui_connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, math.max(layout.AbsoluteContentSize.Y + 14, page.AbsoluteSize.Y))
    end))

    table.insert(gui_connections, page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, math.max(layout.AbsoluteContentSize.Y + 14, page.AbsoluteSize.Y))
    end))

    return page
end

-- Creates a GUI section header.
function gui_section(parent, title)
    local section = gui_make("Frame", {
        BackgroundColor3 = GUI.panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28),
        LayoutOrder = 0,
        ZIndex = 3,
    }, parent)
    gui_round(section, 6)
    gui_stroke(section, GUI.border, 1, 0.42)

    local label = gui_label(section, title, 28, GUI.accent)
    label.Position = UDim2.fromOffset(9, 0)
    label.Size = UDim2.new(1, -18, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.ZIndex = 4
    return section
end

-- Creates a GUI dropdown and its option menu.
function gui_dropdown(parent, key, title, value, options, callback, before_open)
    local row = gui_make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        LayoutOrder = 0,
        ZIndex = 10,
    }, parent)

    local label = gui_label(row, title, 17, GUI.muted, 10)
    label.Position = UDim2.fromOffset(0, 0)
    label.Size = UDim2.new(1, 0, 0, 17)
    label.ZIndex = 11

    local cell = gui_make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 19),
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 11,
    }, row)

    local button = gui_button(cell, value, 100, 28)
    button.Position = UDim2.fromScale(0, 0)
    button.Size = UDim2.new(1, 0, 1, 0)
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.ZIndex = 12
    gui_make("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 20),
    }, button)
    gui_fields[key] = button

    local arrow = gui_make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(10, 28),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = GUI.muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Active = false,
        ZIndex = 13,
    }, button)

    local compact = gui_is_compact_device()
    local option_height = compact and 34 or 26
    local max_menu_height = compact and 250 or 230

    local menu = gui_make("ScrollingFrame", {
        BackgroundColor3 = GUI.panel2,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(180, 28),
        CanvasSize = UDim2.new(0, 0, 0, 4),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ScrollingEnabled = true,
        ScrollBarImageColor3 = GUI.accent_dark,
        ScrollBarThickness = compact and 7 or 4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Active = true,
        ClipsDescendants = true,
        ZIndex = 200,
    }, gui_root)
    gui_round(menu, 6)
    gui_stroke(menu, GUI.border, 1, 0.15)

    gui_make("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
    }, menu)

    local layout = gui_make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
    }, menu)

    local current_options = {}

    local function position_menu()
        local absolute_position = button.AbsolutePosition
        local absolute_size = button.AbsoluteSize
        local viewport = gui_get_viewport()
        local menu_width = math.min(absolute_size.X, math.max(1, viewport.X - 8))
        local menu_height = math.min(max_menu_height, math.max(option_height, #current_options * option_height + 4))
        local bottom = gui_get_screen_bottom()
        local below_y = absolute_position.Y + absolute_size.Y + 2
        local above_y = absolute_position.Y - menu_height - 2
        local y = below_y

        if y + menu_height > bottom and above_y >= 8 then
            y = above_y
        end

        local x = math.clamp(absolute_position.X, 4, math.max(4, viewport.X - menu_width - 4))
        y = math.clamp(y, 4, math.max(4, bottom - menu_height))

        menu.Size = UDim2.fromOffset(menu_width, menu_height)
        menu.Position = UDim2.fromOffset(x, y)
    end

    local function rebuild_options(new_options)
        current_options = new_options or {}

        for _, child in ipairs(menu:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for index, option in ipairs(current_options) do
            local option_text = tostring(option)
            local option_button = gui_button(menu, option_text, 100, option_height)
            option_button.LayoutOrder = index
            option_button.Size = UDim2.new(1, -4, 0, option_height)
            option_button.Position = UDim2.fromOffset(0, 0)
            option_button.TextXAlignment = Enum.TextXAlignment.Left
            option_button.ZIndex = 201
            gui_make("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
            }, option_button)

            gui_bind(option_button, function()
                button.Text = option_text
                menu.Visible = false
                if gui_open_dropdown == menu then
                    gui_open_dropdown = nil
                end
                if callback then
                    callback(option)
                end
            end, true)
        end

        menu.CanvasSize = UDim2.new(0, 0, 0, #current_options * option_height + 4)
        menu.Size = UDim2.fromOffset(button.AbsoluteSize.X, math.min(max_menu_height, math.max(option_height, #current_options * option_height + 4)))
    end

    rebuild_options(options)

    table.insert(gui_connections, button.Activated:Connect(function()
        if gui_open_dropdown and gui_open_dropdown ~= menu then
            gui_open_dropdown.Visible = false
        end

        if menu.Visible then
            menu.Visible = false
            gui_open_dropdown = nil
        else
            if before_open then
                before_open()
            end
            position_menu()
            menu.Visible = true
            gui_open_dropdown = menu
        end
    end))

    table.insert(gui_connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        menu.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
        if menu.Visible then
            position_menu()
        end
    end))

    return row, button, rebuild_options
end

-- Creates a row of labeled GUI input fields.
function gui_field_row(parent, fields, row_height)
    local single_height = row_height or 50
    local count = #fields
    local columns = count

    if gui_is_compact_device() and count >= 3 then
        columns = 2
    end

    local rows = math.ceil(count / columns)
    local row = gui_make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, single_height * rows + 6 * (rows - 1)),
        LayoutOrder = 0,
        ZIndex = 3,
    }, parent)

    for index, field in ipairs(fields) do
        local row_index = math.floor((index - 1) / columns)
        local column_index = (index - 1) % columns
        local left = column_index / columns
        local right_gap = 5
        local cell = gui_make("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(left, column_index == 0 and 0 or 3, 0, row_index * (single_height + 6)),
            Size = UDim2.new(1 / columns, -right_gap - 3, 0, single_height),
            ZIndex = 3,
        }, row)

        local label = gui_label(cell, field.title, 17, GUI.muted, 9)
        label.Position = UDim2.fromOffset(0, 0)
        label.Size = UDim2.new(1, 0, 0, 17)
        label.ZIndex = 4

        local box = gui_textbox(cell, field.value, field.placeholder, 100, 28)
        box.Position = UDim2.fromOffset(0, 19)
        box.Size = UDim2.new(1, 0, 0, 28)
        box:SetAttribute("WireArtField", field.key)
        gui_fields[field.key] = box
    end

    return row
end

-- Creates a full-width GUI input field.
function gui_full_field(parent, key, title, value, placeholder)
    return gui_field_row(parent, {
        {key = key, title = title, value = value, placeholder = placeholder},
    }, 50)
end

-- Creates a row of GUI buttons.
function gui_button_row(parent, specs, height)
    local single_height = height or 30
    local count = #specs
    local columns = count

    if gui_is_compact_device() and count >= 4 then
        columns = 2
    end

    local rows = math.ceil(count / columns)
    local row = gui_make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, single_height * rows + 5 * (rows - 1)),
        LayoutOrder = 0,
        ZIndex = 3,
    }, parent)

    local gap = 6
    for index, spec in ipairs(specs) do
        local row_index = math.floor((index - 1) / columns)
        local column_index = (index - 1) % columns
        local left = column_index / columns
        local button = gui_button(row, spec.text, 100, single_height)
        button.Position = UDim2.new(left, column_index == 0 and 0 or 3, 0, row_index * (single_height + 5))
        button.Size = UDim2.new(1 / columns, -gap - 3, 0, single_height)
        spec.button = button
    end
    return specs
end

-- Creates a wrapped informational GUI label.
function gui_note(parent, text_value, color)
    local label = gui_label(parent, text_value, 32, color or GUI.muted, 9)
    label.TextWrapped = true
    return label
end

-- Parses a numeric GUI field value.
function parse_number(value, field_name, allow_blank)
    local s = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" and allow_blank then
        return nil
    end
    local number = tonumber(s)
    if number == nil then
        return nil, field_name .. " must be a number."
    end
    return number
end

-- Parses a boolean value from GUI text.
function parse_bool(value, default_value)
    local s = tostring(value or ""):lower():gsub("%s+", "")
    if s == "true" or s == "1" or s == "yes" or s == "on" then
        return true
    end
    if s == "false" or s == "0" or s == "no" or s == "off" then
        return false
    end
    if default_value ~= nil then
        return default_value
    end
    return nil
end

-- Parses an optional boolean GUI value.
function parse_optional_bool(value, field_name)
    local s = tostring(value or ""):lower():gsub("%s+", "")
    if s == "" or s == "auto" or s == "nil" then
        return nil
    end
    if s == "true" or s == "1" then
        return true
    end
    if s == "false" or s == "0" then
        return false
    end
    return nil, field_name .. ": use Auto / true / false."
end

-- Parses a Vector3 value from GUI text.
function parse_vector3(value, field_name, allow_blank)
    local s = tostring(value or "")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")

    if s == "" or s:lower() == "nil" then
        if allow_blank then
            return nil
        end
        return nil, field_name .. " cannot be empty."
    end

    local inner = s:match("^Vector3%s*%.%s*new%s*%((.*)%)$")
    if inner then
        s = inner
    end

    local values = {}
    for token in s:gmatch("[^,]+") do
        token = token:gsub("^%s+", ""):gsub("%s+$", "")
        local number = tonumber(token)
        if number == nil then
            return nil, field_name .. " must be x, y, z or Vector3.new(x, y, z)."
        end
        table.insert(values, number)
    end

    if #values ~= 3 then
        return nil, field_name .. " must be x, y, z or Vector3.new(x, y, z)."
    end

    return Vector3.new(values[1], values[2], values[3])
end

-- Parses an RGB color from GUI text.
function parse_color(value, field_name, fallback)
    local s = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then
        return fallback
    end

    local values = {}
    for token in s:gmatch("%d+") do
        table.insert(values, tonumber(token))
    end

    if #values ~= 3 then
        return nil, field_name .. " must be R, G, B."
    end

    return Color3.fromRGB(
        math.clamp(values[1], 0, 255),
        math.clamp(values[2], 0, 255),
        math.clamp(values[3], 0, 255)
    )
end

-- Checks whether an anchor mode is valid.
function is_valid_anchor_mode(value)
    for y_name in pairs(anchor_y_values) do
        for x_name in pairs(anchor_x_values) do
            for z_name in pairs(anchor_z_values) do
                if value == y_name .. x_name .. z_name then
                    return true
                end
            end
        end
    end
    return false
end

-- Formats a numeric value for the GUI.
function gui_format_num(value)
    if value == nil then
        return ""
    end
    if math.abs(value - math.round(value)) < 1e-8 then
        return tostring(math.round(value))
    end
    return string.format("%.4f", value)
end

-- Formats a Vector3 value for the GUI.
function gui_format_vector(value)
    if typeof(value) ~= "Vector3" then
        return ""
    end
    return string.format("%.4f, %.4f, %.4f", value.X, value.Y, value.Z)
end

-- Formats the current preview status for the GUI.
function gui_format_status(_prefix)
    local placement = preview_get_placement()
    if not placement then
        return "Position: unavailable | Rotation: 0° | Wires: unavailable"
    end

    return string.format(
        "Position: %s | Rotation: %d° | Wires: %s",
        gui_format_vector(placement.position),
        math.round(placement.rotation),
        get_range_text(preview_first_wire, preview_last_wire)
    )
end

-- Updates the GUI status label and error state.
function gui_set_status_impl(message, is_error)
    gui_last_status = tostring(message or "")
    gui_last_status_error = not not is_error
    gui_update_position(true)
end

gui_set_status = gui_set_status_impl

-- Formats the current preview range for the report.
function gui_report_range_text(first_wire, last_wire)
    return get_range_text(first_wire, last_wire)
end

-- Formats a build duration for the report.
function gui_report_format_build_time(seconds)
    if seconds == nil then
        return "—"
    end
    seconds = math.max(0, seconds)
    local minutes = math.floor(seconds / 60)
    local remaining = seconds - minutes * 60
    return string.format("%02d:%05.2f", minutes, remaining)
end

-- Resets the GUI build report and output.
gui_report_reset = function()
    gui_report_initial_first = preview_first_wire
    gui_report_initial_last = preview_last_wire
    gui_report_build_started_at = nil
    gui_report_build_elapsed = 0
    gui_report_log_lines = {}
    gui_report_early_log_lines = {}
end

-- Stores the current preview range as the report baseline.
gui_report_set_range_baseline = function()
    gui_report_initial_first = preview_first_wire
    gui_report_initial_last = preview_last_wire
end

-- Updates the GUI report state text.
gui_report_set_state = function(state)
    gui_report_state = tostring(state or "")
end

-- Starts the GUI build timer and report state.
gui_report_build_start = function()
    gui_report_build_started_at = os.clock()
    gui_report_build_elapsed = 0
end

-- Stops the GUI build timer.
gui_report_build_finish = function()
    if gui_report_build_started_at then
        gui_report_build_elapsed = math.max(0, os.clock() - gui_report_build_started_at)
    end
    gui_report_build_started_at = nil
end

-- Appends a message to the GUI build output.
gui_report_log = function(message)
    local elapsed = 0
    if gui_report_build_started_at then
        elapsed = math.max(0, os.clock() - gui_report_build_started_at)
    end
    table.insert(
        gui_report_log_lines,
        string.format("[+%07.2fs] %s", elapsed, tostring(message or ""))
    )
    if #gui_report_log_lines > 500 then
        table.remove(gui_report_log_lines, 1)
    end
end

for _, early_line in ipairs(gui_report_early_log_lines or {}) do
    table.insert(gui_report_log_lines, early_line)
end
gui_report_early_log_lines = {}

-- Returns the elapsed GUI build-report time.
function gui_report_get_elapsed()
    if gui_report_build_started_at then
        return math.max(0, os.clock() - gui_report_build_started_at)
    end
    return gui_report_build_elapsed
end

-- Refreshes the report status text.
function gui_report_update_text()
    if not gui_report_status_label then
        return
    end

    local placement = preview_get_placement()
    local total_wires = ArtPipeline.count_wires(generated_art)
    local rendered_wires = current_preview_report and current_preview_report.rendered_wires or ArtPipeline.count_wires(art)
    local missing_rendered = math.max(total_wires - rendered_wires, 0)

    local initial_range = gui_report_range_text(gui_report_initial_first, gui_report_initial_last)
    local current_range = gui_report_range_text(preview_first_wire, preview_last_wire)

    local scale = 1
    if pipeline_report and pipeline_report.scale_report then
        scale = pipeline_report.scale_report.scale or 1
    end

    local size_source = placement_reference_art or generated_art
    local size = get_art_size(size_source)
    local position_text = placement and string.format(
        "Vector3.new(%.4f, %.4f, %.4f)",
        placement.position.X, placement.position.Y, placement.position.Z
    ) or "unavailable"
    local rotation_text = placement and (tostring(math.round(placement.rotation)) .. "°") or "0°"

    local lines = {
        "Status: " .. tostring(gui_report_state),
        "",
        "Wire type: " .. tostring(active_wire_type_name),
        "Circuit wire type: " .. (tostring(circuit_settings.wire_type_name):gsub("%s*%b()%s*", "")),
        string.format(
            "Rendered wires: %d / %d%s",
            rendered_wires,
            total_wires,
            missing_rendered > 0 and (" (missing " .. tostring(missing_rendered) .. ")") or ""
        ),
        "Current rendered wires: "
            .. initial_range .. " > " .. current_range,
        "",
        string.format("Current scale: %.4f", scale),
        string.format("Size: Width = %.4f | Height = %.4f", size.X, size.Y),
        "Position: " .. position_text,
        "Rotation: " .. rotation_text,
        "",
        "Build time: " .. gui_report_format_build_time((function()
            local build_report = get_build_report()
            return build_report.build_time_all
        end)()),
        "",
        "Required wires:",
    }

    local report = get_build_report()
    local type_names = {}
    for type_name in pairs(report.required_by_type or {}) do
        table.insert(type_names, type_name)
    end
    table.sort(type_names)

    if #type_names == 0 then
        table.insert(lines, "    None")
    else
        for _, type_name in ipairs(type_names) do
            local available = report.boxes_by_type[type_name] or 0
            local required = report.required_by_type[type_name] or 0
            local missing = math.max(required - available, 0)
            table.insert(
                lines,
                "    " .. tostring(type_name)
                .. ": " .. tostring(available) .. " / " .. tostring(required)
                .. (missing > 0 and (" (missing " .. tostring(missing) .. ")") or "")
            )
        end
    end

    gui_report_status_label.Text = table.concat(lines, "\n")
    if gui_report_log_label then
        local log_text = table.concat(gui_report_log_lines, "\n")
        gui_report_log_label.Text = log_text

        if gui_report_log_scroll then
            local old_maximum = math.max(0, gui_report_log_scroll.CanvasSize.Y.Offset - gui_report_log_scroll.AbsoluteSize.Y)
            local old_position = gui_report_log_scroll.CanvasPosition.Y
            local was_at_bottom = old_position >= old_maximum - 6
            local line_count = math.max(1, select(2, log_text:gsub("\n", "")) + 1)
            local text_height = line_count * 15 + 12
            gui_report_log_label.Size = UDim2.new(1, -10, 0, text_height)
            gui_report_log_scroll.CanvasSize = UDim2.new(
                0,
                0,
                0,
                math.max(text_height + 8, gui_report_log_scroll.AbsoluteSize.Y)
            )
            local new_maximum = math.max(0, gui_report_log_scroll.CanvasSize.Y.Offset - gui_report_log_scroll.AbsoluteSize.Y)
            local new_position = was_at_bottom and new_maximum or math.clamp(old_position, 0, new_maximum)
            gui_report_log_scroll.CanvasPosition = Vector2.new(0, new_position)
        end
    end
end

-- Updates the GUI position and placement state.
gui_update_position = function(force)
    local now = os.clock()
    if not force and now - gui_report_last_refresh < 0.10 then
        return
    end
    gui_report_last_refresh = now

    if gui_position_label then
        gui_position_label.Text = gui_format_status()
    end

    gui_report_update_text()
end

-- Clamps the GUI window position to the screen.
function clamp_window_position(position)
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local width = gui_window and gui_window.AbsoluteSize.X or 460
    local height = gui_window and gui_window.AbsoluteSize.Y or 450
    local x = math.clamp(position.X.Offset, 4, math.max(4, viewport.X - width - 4))
    local y = math.clamp(position.Y.Offset, 4, math.max(4, viewport.Y - height - 4))
    return UDim2.fromOffset(x, y)
end

-- Checks whether the mouse or touch point is currently over the GUI.
gui_mouse_over_ui = function(position)
    if position and gui_window and gui_window.Visible and gui_point_in_object(gui_window, position) then
        return true
    end
    if position and gui_restore and gui_restore.Visible and gui_point_in_object(gui_restore, position) then
        return true
    end
    if position and gui_open_dropdown and gui_open_dropdown.Visible and gui_point_in_object(gui_open_dropdown, position) then
        return true
    end
    return gui_mouse_over_window or gui_mouse_over_restore
end

-- Disconnects the active GUI drag connection.
function disconnect_gui_drag()
    for _, connection in ipairs(gui_drag_connections) do
        safe_disconnect(connection)
    end
    gui_drag_connections = {}
    gui_dragging = false
    gui_drag_input = nil
end

-- Checks whether a screen point lies inside a GUI object.
function gui_point_in_object(object, position)
    if not object or not object.Visible then
        return false
    end

    local absolute_position = object.AbsolutePosition
    local absolute_size = object.AbsoluteSize
    return position.X >= absolute_position.X
        and position.Y >= absolute_position.Y
        and position.X <= absolute_position.X + absolute_size.X
        and position.Y <= absolute_position.Y + absolute_size.Y
end

-- Binds mouse and touch dragging for the GUI window.
function bind_gui_drag()
    disconnect_gui_drag()
    if not gui_window then
        return
    end

    local title_bar = gui_window:FindFirstChild("TitleBar")
    if not title_bar then
        return
    end

    gui_window.Active = true
    title_bar.Active = true

    local minimize_button = title_bar:FindFirstChild("Minimize")
    local close_button = title_bar:FindFirstChild("Close")

    local function is_title_drag_area(position)
        if not gui_window.Visible or not title_bar.Visible then
            return false
        end

        if not gui_point_in_object(title_bar, position) then
            return false
        end

        if gui_point_in_object(minimize_button, position)
            or gui_point_in_object(close_button, position) then
            return false
        end

        return true
    end

    table.insert(gui_drag_connections, UserInputService.InputBegan:Connect(function(input)
        if not is_primary_pointer_input(input) then
            return
        end

        if is_title_drag_area(input.Position) then
            gui_dragging = true
            gui_drag_start = Vector3.new(input.Position.X, input.Position.Y, 0)
            gui_window_start = gui_window.Position
            gui_drag_input = input
        end
    end))

    table.insert(gui_drag_connections, UserInputService.InputEnded:Connect(function(input)
        if not is_primary_pointer_input(input) then
            return
        end

        if input == gui_drag_input or input.UserInputType == Enum.UserInputType.MouseButton1 then
            gui_dragging = false
            gui_drag_input = nil
        end
    end))

    table.insert(gui_drag_connections, UserInputService.InputChanged:Connect(function(input)
        if not gui_dragging or not gui_window then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - gui_drag_start
        gui_window.Position = clamp_window_position(UDim2.fromOffset(
            gui_window_start.X.Offset + delta.X,
            gui_window_start.Y.Offset + delta.Y
        ))
    end))

    table.insert(gui_drag_connections, UserInputService.TouchMoved:Connect(function(input)
        if not gui_dragging or not gui_window then
            return
        end

        if input ~= gui_drag_input then
            return
        end

        local delta = input.Position - gui_drag_start
        gui_window.Position = clamp_window_position(UDim2.fromOffset(
            gui_window_start.X.Offset + delta.X,
            gui_window_start.Y.Offset + delta.Y
        ))
    end))
end
-- Rebinds the current preview to the current pointer position.
function gui_rebind_preview_to_mouse()
    if build_running then
        gui_set_status("Build is running. Stop the build before rebinding the preview.", true)
        return false
    end

    if not preview_model then
        gui_set_status("Preview unavailable.", true)
        return false
    end

    preview_stop_placement()
    preview_locked = false
    deletion_mode = false
    preview_mouse_offset = Vector3.zero
    preview_start_placement(art, true)

    return true
end

-- Activates the selected GUI tab.
function gui_set_active_tab(name)
    gui_selected_tab = name

    if gui_open_dropdown then
        gui_open_dropdown.Visible = false
        gui_open_dropdown = nil
    end

    for tab_name, button in pairs(gui_tabs) do
        local active = tab_name == name
        button.BackgroundColor3 = active and GUI.accent_dark or GUI.panel2
        button.TextColor3 = active and GUI.text or GUI.muted
    end

    for page_name, page in pairs(gui_pages) do
        page.Visible = page_name == name
        if page.Visible then
            page.CanvasPosition = Vector2.zero
        end
    end
end

-- Binds a GUI button to a callback.
function gui_bind(button, callback, allow_during_build)
    table.insert(gui_connections, button.Activated:Connect(function()
        if build_running and not allow_during_build then
            gui_set_status("Build is running. Click the build button to cancel.", true)
            return
        end

        local ok, result = xpcall(callback, function(error_message)
            if debug and debug.traceback then
                return debug.traceback(tostring(error_message))
            end
            return tostring(error_message)
        end)

        if not ok then
            report_warn("GUI action error:")
            report_warn(result)
            gui_set_status(result, true)
        end

        gui_update_position(true)
    end))
end

-- Rebuilds the maximum wire-length table.
function gui_rebuild_max_lengths()
    max_lengths.Wire = wire_max_length
    max_lengths.WireWhite = wire_max_length
    max_lengths.WireGreen = wire_max_length
    max_lengths.WireRed = wire_max_length
    max_lengths.WireYellow = wire_max_length
    max_lengths.WireMagenta = wire_max_length

    max_lengths.NeonWireWhite = neon_max_length
    max_lengths.NeonWireOrange = neon_max_length
    max_lengths.NeonWireBlue = neon_max_length
    max_lengths.NeonWireCyan = neon_max_length
    max_lengths.NeonWireGreen = neon_max_length
    max_lengths.NeonWireRed = neon_max_length
    max_lengths.NeonWireYellow = neon_max_length
    max_lengths.NeonWireViolet = neon_max_length
    max_lengths.NeonWirePinky = neon_max_length
end

-- Rebuilds wire visual statistics for the current settings.
function gui_rebuild_wire_stats()
    local result = {
        Wire = {
            line_width = 0.2,
            end_size = Vector3.new(0.16, 0.4, 0.4),
            point_size = Vector3.new(0.2, 0.2, 0.2),
            wire_color = Color3.fromRGB(27, 42, 53),
        },
        NeonWireWhite = {
            line_width = 0.35,
            end_size = Vector3.new(0.152, 0.38, 0.38),
            point_size = Vector3.new(0.35, 0.35, 0.35),
            wire_color = Color3.fromRGB(17, 17, 17),
        },
    }

    for _, name in ipairs({
        "NeonWireOrange",
        "NeonWireBlue",
        "NeonWireCyan",
        "NeonWireGreen",
        "NeonWireRed",
        "NeonWireYellow",
        "NeonWireViolet",
        "NeonWirePinky"
    }) do
        result[name] = {
            line_width = result.NeonWireWhite.line_width,
            end_size = result.NeonWireWhite.end_size,
            point_size = result.NeonWireWhite.point_size,
            wire_color = result.NeonWireWhite.wire_color,
        }
    end

    for _, cwire in ipairs({
        {"WireWhite", Color3.fromRGB(91, 93, 105)},
        {"WireGreen", Color3.fromRGB(39, 70, 45)},
        {"WireRed", Color3.fromRGB(86, 36, 36)},
        {"WireYellow", Color3.fromRGB(126, 104, 63)},
        {"WireMagenta", Color3.fromRGB(89, 34, 89)}
    }) do
        result[cwire[1]] = {
            line_width = result.Wire.line_width,
            end_size = result.Wire.end_size,
            point_size = result.Wire.point_size,
        }
        result[cwire[1]].wire_color = cwire[2]
    end

    if check_mode == true then
        for _, w in pairs(result) do
            w.line_width = math.max(check_reduce, w.line_width - check_reduce)
            w.end_size = Vector3.new(
                math.max(check_reduce, w.end_size.X - check_reduce),
                math.max(check_reduce, w.end_size.Y - check_reduce),
                math.max(check_reduce, w.end_size.Z - check_reduce)
            )
            w.point_size = Vector3.new(
                math.max(check_reduce, w.point_size.X - check_reduce),
                math.max(check_reduce, w.point_size.Y - check_reduce),
                math.max(check_reduce, w.point_size.Z - check_reduce)
            )
            w.wire_color = check_color
        end
    end

    wire_stats = result
end

-- Applies the values from the Main tab.
function gui_apply_main_fields()
    local function field(key)
        return gui_fields[key] and gui_fields[key].Text or ""
    end

    local new_url = field("url")
    local new_filename = field("filename")

    local new_wire = field("wire")
    if new_wire == "" then
        return false, "Wire type cannot be empty."
    end
    if not max_lengths[new_wire] then
        return false, "Unknown Wire type: " .. new_wire
    end

    local scale, scale_err = parse_number(field("scale"), "Art scale multiplier", false)
    if scale_err then return false, scale_err end
    if scale <= 0 then return false, "Art scale multiplier must be > 0." end

    local position_text = tostring(field("default_position") or "")
    position_text = position_text:gsub("^%s+", ""):gsub("%s+$", "")

    local position = nil
    if position_text == "" or position_text:lower() == "nil" then
        position = nil
    else
        local parsed_position, position_err = parse_vector3(position_text, "Default position", false)
        if position_err then return false, position_err end
        position = parsed_position
    end

    local delay, delay_err = parse_number(field("delay"), "Build delay", false)
    if delay_err then return false, delay_err end
    if delay < 0 then return false, "Build delay cannot be negative." end

    url = new_url
    filename = new_filename
    wire_type_name = new_wire
    art_scale_multiplier = scale
    default_position = position
    place_delay = delay

    return true
end

-- Applies the values from the Settings tab.
function gui_apply_settings_from_fields()
    local function field(key)
        return gui_fields[key] and gui_fields[key].Text or ""
    end

    local new_enable_rescale = parse_bool(field("rescale"), enable_rescale)
    local new_test_vectors = parse_bool(field("test_vectors"), use_test_vectors)
    local new_test_art = parse_bool(field("test_art"), use_test_art)
    local new_check_mode = parse_bool(field("check_mode"), check_mode)

    local anchor = field("anchor")
    if anchor ~= "" and not is_valid_anchor_mode(anchor) then
        return false, "Invalid preview anchor: " .. anchor
    end

    local width, width_err = parse_number(field("width"), "Width", true)
    if width_err then return false, width_err end
    if width and width <= 0 then return false, "Width must be > 0." end

    local height, height_err = parse_number(field("height"), "Height", true)
    if height_err then return false, height_err end
    if height and height <= 0 then return false, "Height must be > 0." end

    local first, first_err = parse_number(field("first"), "First wire", false)
    if first_err then return false, first_err end

    local last_text = field("last")
    local last
    if last_text == "" or last_text:lower() == "end" or last_text:lower() == "math.huge" then
        last = math.huge
    else
        local parsed_last, parsed_last_err = parse_number(last_text, "Last wire", false)
        if parsed_last_err then return false, parsed_last_err end
        last = parsed_last
    end

    local move_h = tonumber(field("move_h"))
    local move_v = tonumber(field("move_v"))
    local move_d = tonumber(field("move_d"))
    if move_h ~= nil and move_h >= 0 then gui_move_h_step = move_h end
    if move_v ~= nil and move_v >= 0 then gui_move_v_step = move_v end
    if move_d ~= nil and move_d >= 0 then gui_move_d_step = move_d end

    local new_my_art_text = tostring(field("my_art") or "")
    local parsed_test_vectors = nil
    local my_art_is_blank = new_my_art_text:gsub("%s+", "") == ""
    if my_art_is_blank then
        parsed_test_vectors = original_test_vectors
    else
        local old_text = my_art_text
        my_art_text = new_my_art_text
        local ok, value_or_error = pcall(parse_my_art_source)
        my_art_text = new_my_art_text
        if not ok then
            my_art_text = old_text
            return false, tostring(value_or_error)
        end
        parsed_test_vectors = value_or_error
    end

    preview_first_wire = math.max(1, math.floor(first))
    preview_last_wire = last == math.huge and math.huge or math.max(1, math.floor(last))
    enable_rescale = new_enable_rescale
    use_test_vectors = new_test_vectors
    use_test_art = new_test_art
    preview_anchor_position = anchor ~= "" and anchor or preview_anchor_position
    default_art_width = width
    default_art_height = height
    check_mode = new_check_mode
    if move_h ~= nil and move_h >= 0 then gui_move_h_step = move_h end
    if move_v ~= nil and move_v >= 0 then gui_move_v_step = move_v end
    if move_d ~= nil and move_d >= 0 then gui_move_d_step = move_d end
    my_art_text = new_my_art_text
    if parsed_test_vectors ~= nil then
        test_vectors = parsed_test_vectors
    end

    gui_rebuild_wire_stats()
    return true
end

-- Refreshes GUI fields from the current script state.
function gui_refresh_fields()
    local function set_field(key, value)
        if gui_fields[key] then
            gui_fields[key].Text = tostring(value or "")
        end
    end

    if gui_fields.player then
        gui_fields.player.Text = gui_get_player_label(selected_player)
    end
    set_field("url", url)
    set_field("filename", filename)
    set_field("wire", wire_type_name)
    set_field("scale", gui_format_num(art_scale_multiplier))
    if typeof(default_position) == "Vector3" then
        set_field("default_position", string.format("Vector3.new(%.4f, %.4f, %.4f)", default_position.X, default_position.Y, default_position.Z))
    else
        set_field("default_position", "")
    end
    set_field("delay", gui_format_num(place_delay))

    local function set_toggle_field(key, value)
        if gui_fields[key] then
            gui_fields[key].Text = value and "ON" or "OFF"
            gui_fields[key].TextColor3 = value and GUI.accent or GUI.text
        end
    end
    set_toggle_field("rescale", enable_rescale)
    set_toggle_field("check_mode", check_mode)
    set_toggle_field("test_vectors", use_test_vectors)
    set_toggle_field("test_art", use_test_art)
    set_field("anchor", preview_anchor_position)
    set_field("width", default_art_width and gui_format_num(default_art_width) or "")
    set_field("height", default_art_height and gui_format_num(default_art_height) or "")
    set_field("first", tostring(preview_first_wire))
    set_field("last", preview_last_wire == math.huge and "END" or tostring(preview_last_wire))
    set_field("my_art", my_art_text)

    if gui_fields["circuit_enabled"] then
        gui_fields["circuit_enabled"].Text = gui_toggle_value_text(circuit_settings.enabled)
        gui_fields["circuit_enabled"].TextColor3 = circuit_settings.enabled and GUI.accent or GUI.text
    end
    set_field("circuit_wire", tostring(circuit_settings.wire_type_name))
    if gui_fields["circuit_show_old"] then
        gui_fields["circuit_show_old"].Text = gui_toggle_value_text(circuit_settings.show_old_wires)
        gui_fields["circuit_show_old"].TextColor3 = circuit_settings.show_old_wires and GUI.accent or GUI.text
    end
    if gui_fields["circuit_build_old"] then
        gui_fields["circuit_build_old"].Text = gui_toggle_value_text(circuit_settings.build_old_wires)
        gui_fields["circuit_build_old"].TextColor3 = circuit_settings.build_old_wires and GUI.accent or GUI.text
    end

    set_field("move_h", gui_format_num(gui_move_h_step))
    set_field("move_v", gui_format_num(gui_move_v_step))
    set_field("move_d", gui_format_num(gui_move_d_step))

    gui_update_position(true)
end

-- Reads a movement step from the GUI.
function gui_get_move_step(key, fallback)
    local field = gui_fields[key]
    if field then
        local text_value = tostring(field.Text or "")
        text_value = text_value:gsub("^%s+", "")
        text_value = text_value:gsub("%s+$", "")

        local value = tonumber(text_value)
        if value ~= nil and value >= 0 then
            if key == "move_h" then
                gui_move_h_step = value
            elseif key == "move_v" then
                gui_move_v_step = value
            elseif key == "move_d" then
                gui_move_d_step = value
            end
            return value
        end
    end
    return fallback
end

-- Moves the preview sideways using the GUI step.
function gui_move_sideways(sign)
    if not can_move_preview() then return end
    if invert_horizontal_movement then sign = -sign end
    local step = gui_get_move_step("move_h", gui_move_h_step)
    local axis = get_horizontal_movement_axis()
    preview_apply_manual_delta(axis * (sign * step))
end

-- Moves the preview vertically using the GUI step.
function gui_move_vertical(sign)
    if not can_move_preview() then return end
    if invert_vertical_movement then sign = -sign end
    local step = gui_get_move_step("move_v", gui_move_v_step)
    preview_apply_manual_delta(Vector3.yAxis * (sign * step))
end

-- Returns the world axis used for GUI depth movement.
function gui_depth_axis()
    local horizontal = get_horizontal_movement_axis()
    local depth = Vector3.yAxis:Cross(horizontal)
    if depth.Magnitude <= eps then
        return Vector3.zAxis
    end
    return depth.Unit
end

-- Moves the preview along the GUI depth axis.
function gui_move_depth(sign)
    if not can_move_preview() then return end
    local step = gui_get_move_step("move_d", gui_move_d_step)
    preview_apply_manual_delta(gui_depth_axis() * (sign * step))
end

-- Rounds the preview along its horizontal movement axis.
function gui_round_horizontal()
    if not can_move_preview() then return end
    local axis = get_horizontal_movement_axis()
    local coordinate = preview_position:Dot(axis)
    preview_apply_manual_delta(axis * (math.round(coordinate) - coordinate))
end

-- Rounds the preview vertically.
function gui_round_vertical()
    if not can_move_preview() then return end
    preview_apply_manual_delta(Vector3.new(preview_position.X, math.round(preview_position.Y), preview_position.Z) - preview_position)
end

-- Applies the values from the Circuit tab.
function gui_apply_circuit_fields()
    local function value(key)
        return gui_fields[key] and gui_fields[key].Text or ""
    end

    local enabled = parse_bool(value("circuit_enabled"), circuit_settings.enabled)
    local show_old = parse_bool(value("circuit_show_old"), circuit_settings.show_old_wires)
    local build_old = parse_bool(value("circuit_build_old"), circuit_settings.build_old_wires)
    local wire = value("circuit_wire")
    if wire == "" or not max_lengths[wire] then
        gui_set_status("Unknown Circuit wire type: " .. tostring(wire), true)
        return false
    end

    circuit_settings.enabled = enabled
    circuit_settings.wire_type_name = wire
    circuit_settings.show_old_wires = show_old
    circuit_settings.build_old_wires = build_old
    return true
end

-- Applies all GUI settings to the active script state.
function gui_apply_all_fields()
    local ok_main, main_err = gui_apply_main_fields()
    if not ok_main then
        return false, main_err
    end

    local ok_settings, settings_err = gui_apply_settings_from_fields()
    if not ok_settings then
        return false, settings_err
    end

    local ok_circuit, circuit_err = gui_apply_circuit_fields()
    if not ok_circuit then
        return false, circuit_err
    end

    local target_wire_type = circuit_settings.enabled
        and circuit_settings.wire_type_name
        or wire_type_name
    local ok_type, type_err = set_active_wire_type(target_wire_type)
    if not ok_type then
        return false, type_err
    end

    return true
end

-- Refreshes the Build/Cancel button state.
function gui_update_build_button()
    if not gui_build_button then
        return
    end

    if build_running then
        gui_build_button.Text = "Cancel Build"
        gui_build_button.TextColor3 = GUI.warning
    else
        gui_build_button.Text = "Build"
        gui_build_button.TextColor3 = GUI.text
    end
end

-- Starts a build from the current GUI state.
function gui_build()
    if build_running then
        return
    end
    if not preview_model then
        gui_set_status("Preview unavailable.", true)
        return
    end

    gui_refresh_player_dropdown()
    local local_player = Players.LocalPlayer
    if not selected_player or selected_player.Parent ~= Players then
        selected_player = local_player
        if selected_player then
            local ok_player, player_err = set_active_player(selected_player)
            if not ok_player then
                gui_set_status(player_err, true)
                return
            end
        end
    elseif selected_player ~= player then
        local ok_player, player_err = set_active_player(selected_player)
        if not ok_player then
            gui_set_status(player_err, true)
            return
        end
    end

    local ok_settings, settings_err = gui_apply_all_fields()
    if not ok_settings then
        gui_set_status(settings_err, true)
        return
    end

    gui_update_build_button()
    build_art(art)
    gui_update_build_button()
end

-- Requests cancellation of the current build.
function gui_cancel_build()
    if build_running then
        build_cancelled = true
        gui_set_status("Build cancellation requested…")
        gui_update_build_button()
    end
end

-- Returns the current player list for the dropdown.
function gui_get_player_options()
    local players = game:GetService("Players")
    local local_player = players.LocalPlayer
    local player_list = players:GetPlayers()

    local local_player_present = false
    for _, current_player in ipairs(player_list) do
        if current_player == local_player then
            local_player_present = true
            break
        end
    end

    if local_player and not local_player_present then
        table.insert(player_list, local_player)
    end

    table.sort(player_list, function(a, b)
        if a == b then
            return false
        end
        if a == local_player then
            return true
        end
        if b == local_player then
            return false
        end
        return a.Name:lower() < b.Name:lower()
    end)

    return player_list
end

-- Returns the display name for a player option.
function gui_get_player_label(current_player)
    if not current_player then
        return "No player"
    end

    return current_player.Name
end

-- Refreshes the player dropdown options.
function gui_refresh_player_dropdown()
    if not gui_player_dropdown_refresh then
        return
    end

    local player_list = gui_get_player_options()
    local selected = selected_player
    local selected_present = false

    for _, current_player in ipairs(player_list) do
        if current_player == selected then
            selected_present = true
            break
        end
    end

    if not selected_present then
        selected_player = Players.LocalPlayer or player_list[1]
    end

    if selected_player and selected_player ~= player then
        set_active_player(selected_player)
    end

    local labels = {}
    for _, current_player in ipairs(player_list) do
        table.insert(labels, gui_get_player_label(current_player))
    end

    gui_player_dropdown_refresh(labels)

    if gui_fields.player then
        gui_fields.player.Text = gui_get_player_label(selected_player)
    end
end

-- Creates the complete wire-art GUI.
function create_gui()
    local previous = shared_env.__WIRE_ART_GUI_CLEANUP
    if type(previous) == "function" then
        pcall(previous)
    end

    disconnect_gui_drag()
    gui_disconnect_all()
    gui_fields = {}
    gui_tabs = {}
    gui_pages = {}
    gui_player_dropdown_refresh = nil

    gui_root = gui_make("ScreenGui", {
        Name = GUI_NAME,
        DisplayOrder = 999999,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, gui_parent())

    local viewport = gui_get_viewport()
    local compact = gui_is_compact_device()
    local window_width = math.max(compact and 200 or 240, math.min(460, viewport.X - 16))
    local screen_bottom = gui_get_screen_bottom()
    local window_height = math.min(450, math.max(compact and 220 or 320, screen_bottom - 8))

    gui_window = gui_make("Frame", {
        BackgroundColor3 = GUI.bg,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(window_width, window_height),
        Active = true,
        ClipsDescendants = true,
        ZIndex = 1,
    }, gui_root)
    gui_round(gui_window, 9)
    gui_stroke(gui_window, GUI.border, 1, 0.08)

    local camera = Workspace.CurrentCamera
    if camera then
        table.insert(gui_connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            gui_update_window_layout()
        end))
    end
    table.insert(gui_connections, UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
        gui_update_window_layout()
    end))
    table.insert(gui_connections, UserInputService:GetPropertyChangedSignal("OnScreenKeyboardPosition"):Connect(function()
        gui_update_window_layout()
    end))

    table.insert(gui_connections, gui_window.MouseEnter:Connect(function()
        gui_mouse_over_window = true
    end))
    table.insert(gui_connections, gui_window.MouseLeave:Connect(function()
        gui_mouse_over_window = false
    end))

    local title_bar = gui_make("TextButton", {
        Name = "TitleBar",
        AutoButtonColor = false,
        BackgroundColor3 = GUI.panel,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = "  Ratatog's Wireart",
        TextColor3 = GUI.accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 20,
    }, gui_window)
    gui_round(title_bar, 8)

    local minimize = gui_button(title_bar, "−", 26, 23)
    minimize.Name = "Minimize"
    minimize.Position = UDim2.new(1, -59, 0, 3)
    minimize.ZIndex = 21

    local close = gui_button(title_bar, "×", 26, 23)
    close.Name = "Close"
    close.Position = UDim2.new(1, -30, 0, 3)
    close.TextColor3 = GUI.danger
    close.ZIndex = 21

    table.insert(gui_connections, minimize.Activated:Connect(function()
        gui_window.Visible = false
        gui_restore.Visible = true
        gui_dragging = false
    end))

    table.insert(gui_connections, close.Activated:Connect(function()
        shutdown()
        destroy_gui()
    end))

    bind_gui_drag()

    local status_panel = gui_make("Frame", {
        BackgroundColor3 = GUI.panel,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(7, 37),
        Size = UDim2.new(1, -14, 0, 27),
        ZIndex = 10,
    }, gui_window)
    gui_round(status_panel, 6)
    gui_stroke(status_panel, GUI.border, 1, 0.42)

    gui_position_label = gui_label(status_panel, "", 25, GUI.text, 10)
    gui_position_label.Position = UDim2.fromOffset(8, 1)
    gui_position_label.Size = UDim2.new(1, -16, 1, -2)
    gui_position_label.TextTruncate = Enum.TextTruncate.AtEnd
    gui_position_label.ZIndex = 11

    gui_restore = gui_button(gui_root, "WIRE", 56, 28)
    gui_restore.AnchorPoint = Vector2.new(1, 0.5)
    gui_restore.Position = UDim2.new(1, -7, 0.5, 0)
    gui_restore.Visible = false
    gui_restore.ZIndex = 100
    table.insert(gui_connections, gui_restore.Activated:Connect(function()
        gui_window.Visible = true
        gui_restore.Visible = false
        bind_gui_drag()
    end))
    table.insert(gui_connections, gui_restore.MouseEnter:Connect(function()
        gui_mouse_over_restore = true
    end))
    table.insert(gui_connections, gui_restore.MouseLeave:Connect(function()
        gui_mouse_over_restore = false
    end))

    local tab_bar = gui_make("Frame", {
        BackgroundColor3 = GUI.panel,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(7, 67),
        Size = UDim2.new(1, -14, 0, 30),
        ZIndex = 10,
    }, gui_window)
    gui_round(tab_bar, 6)

    local tab_names = {
        {"main", "Main"},
        {"position", "Position"},
        {"settings", "Settings"},
        {"circuit", "Circuit"},
        {"report", "Report"},
    }

    for index, tab_info in ipairs(tab_names) do
        local name = tab_info[1]
        local title = tab_info[2]
        local button = gui_button(tab_bar, title, 80, 28)
        button.Position = UDim2.new((index - 1) / #tab_names, 1, 0, 1)
        button.Size = UDim2.new(1 / #tab_names, -2, 0, 28)
        button.ZIndex = 11
        gui_tabs[name] = button
    end

    local content = gui_make("Frame", {
        BackgroundColor3 = GUI.panel,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(7, 101),
        Size = UDim2.new(1, -14, 1, -108),
        ClipsDescendants = true,
        ZIndex = 2,
    }, gui_window)
    gui_round(content, 7)
    gui_stroke(content, GUI.border, 1, 0.35)
    gui_update_position(true)

    for _, tab_info in ipairs(tab_names) do
        gui_pages[tab_info[1]] = gui_page(content)
        table.insert(gui_connections, gui_tabs[tab_info[1]].Activated:Connect(function()
            gui_set_active_tab(tab_info[1])
        end))
    end

    do
        local page = gui_pages.main

        local player_list = gui_get_player_options()
        local player_options = {}
        for _, current_player in ipairs(player_list) do
            table.insert(player_options, gui_get_player_label(current_player))
        end

        local selected_present = false
        for _, current_player in ipairs(player_list) do
            if current_player == selected_player then
                selected_present = true
                break
            end
        end
        if not selected_present then
            selected_player = Players.LocalPlayer or player_list[1]
        end
        if selected_player and selected_player ~= player then
            set_active_player(selected_player)
        end

        local _, player_button, refresh_player_options = gui_dropdown(
            page,
            "player",
            "Player",
            gui_get_player_label(selected_player),
            player_options,
            function(option)
                local players = game:GetService("Players")
                for _, current_player in ipairs(players:GetPlayers()) do
                    if current_player.Name == option then
                        selected_player = current_player
                        local ok_player, player_err = set_active_player(current_player)
                        if not ok_player then
                            gui_set_status(player_err, true)
                            return
                        end
                        gui_set_status("Player selected: " .. current_player.Name)
                        return
                    end
                end
            end,
            function()
                gui_refresh_player_dropdown()
            end
        )
        gui_player_dropdown_refresh = refresh_player_options

        gui_full_field(page, "url", "URL", url, "https://...")
        gui_full_field(page, "filename", "Filename", filename, "path/to/file.json")
        local wire_options = {}
        for type_name, replicated in pairs(replicated_wires) do
            if replicated and max_lengths[type_name] then
                table.insert(wire_options, type_name)
            end
        end
        table.sort(wire_options)
        gui_dropdown(page, "wire", "Wire type", wire_type_name, wire_options, function(option)
            wire_type_name = option
            gui_set_status("Wire type updated.")
        end)

        gui_field_row(page, {
            {key = "scale", title = "Art scale", value = gui_format_num(art_scale_multiplier), placeholder = "1.0"},
            {key = "delay", title = "Build delay", value = gui_format_num(place_delay), placeholder = "2.0"},
        }, 50)
        gui_full_field(
            page,
            "default_position",
            "Default position",
            typeof(default_position) == "Vector3"
                and string.format("Vector3.new(%.4f, %.4f, %.4f)", default_position.X, default_position.Y, default_position.Z)
                or "",
            "Vector3.new(x, y, z) / blank = nil"
        )
        local main_buttons = gui_button_row(page, {
            {text = "Redraw"},
            {text = "Build"},
        }, 30)
        gui_build_button = main_buttons[2].button
        gui_bind(main_buttons[1].button, function()
            gui_report_reset()
            local ok_settings, err = gui_apply_all_fields()
            if not ok_settings then
                return gui_set_status(err, true)
            end
            local old_position = gui_window and gui_window.Position
            cleanup_all(true, false)
            preview_mouse_offset = Vector3.zero
            vectors = {}
            generated_art = {}
            placement_reference_art = nil
            circuit_source_art = nil
            circuit_report = nil
            art = {}
            pipeline_report = nil
            generated_wire_entries = {}
            current_preview_report = nil
            preview_locked = false
            deletion_mode = false
            deleted_wire_numbers = {}
            deleted_wire_refs = {}
            wire_number_by_table = {}
            preview_wire_models = {}
            preview_using_default_position = false
            local ok, result = xpcall(initialize, function(error_message)
                if debug and debug.traceback then
                    return debug.traceback(tostring(error_message))
                end
                return tostring(error_message)
            end)
            if not ok or not result then
                gui_set_status(ok and "Redraw failed." or ("Error: " .. tostring(result)), true)
                return
            end

            preview_create(art)
            connect_main_inputs()
            preview_start_placement(art)

            if typeof(default_position) == "Vector3" and preview_model then
                preview_stop_placement()
                preview_placing = true
                preview_using_default_position = true
                preview_set_position(default_position)
            end

            if old_position then
                gui_window.Position = clamp_window_position(old_position)
            end
            gui_refresh_fields()
            gui_report_set_range_baseline()
            gui_report_set_state("Selecting position")
            gui_set_status("Art redrawn with new settings.")
        end)
        gui_bind(main_buttons[2].button, function()
            if build_running then
                gui_cancel_build()
            else
                gui_build()
            end
            gui_update_build_button()
        end, true)

        for _, key in ipairs({"url", "filename", "scale", "default_position", "delay"}) do
            local field = gui_fields[key]
            if field and field:IsA("TextBox") then
                table.insert(gui_connections, field.FocusLost:Connect(function()
                    local ok_main, err = gui_apply_main_fields()
                    if not ok_main then
                        gui_set_status(err, true)
                    else
                        if key == "default_position" then
                            local text_value = tostring(field.Text or "")
                            text_value = text_value:gsub("^%s+", "")
                            text_value = text_value:gsub("%s+$", "")
                            if text_value == "" or text_value:lower() == "nil" then
                                default_position = nil
                                field.Text = ""
                                gui_set_status("Default position cleared.")
                            else
                                gui_set_status("Default position updated.")
                            end
                        else
                            gui_set_status("Setting updated.")
                        end
                    end
                    gui_refresh_fields()
                end))
            end
        end
    end

    do
        local page = gui_pages.position
        gui_field_row(page, {
            {key = "move_h", title = "Horizontal", value = gui_format_num(gui_move_h_step), placeholder = "1"},
            {key = "move_v", title = "Vertical", value = gui_format_num(gui_move_v_step), placeholder = "1"},
            {key = "move_d", title = "Forward / Backward", value = gui_format_num(gui_move_d_step), placeholder = "1"},
        }, 50)

        local movement = gui_button_row(page, {
            {text = "←"}, {text = "→"}, {text = "↑"}, {text = "↓"},
        }, 29)
        gui_bind(movement[1].button, function() gui_move_sideways(-1) end)
        gui_bind(movement[2].button, function() gui_move_sideways(1) end)
        gui_bind(movement[3].button, function() gui_move_vertical(1) end)
        gui_bind(movement[4].button, function() gui_move_vertical(-1) end)

        local movement2 = gui_button_row(page, {
            {text = "Back"}, {text = "Forward"}, {text = "Round X"}, {text = "Round Y"},
        }, 29)
        gui_bind(movement2[1].button, function() gui_move_depth(-1) end)
        gui_bind(movement2[2].button, function() gui_move_depth(1) end)
        gui_bind(movement2[3].button, gui_round_horizontal)
        gui_bind(movement2[4].button, gui_round_vertical)

        local actions = gui_button_row(page, {
            {text = "− First"}, {text = "+ First"}, {text = "− Last"}, {text = "+ Last"},
        }, 29)
        gui_bind(actions[1].button, preview_remove_first_wire)
        gui_bind(actions[2].button, preview_add_first_wire)
        gui_bind(actions[3].button, preview_remove_last_wire)
        gui_bind(actions[4].button, preview_add_last_wire)

        local edit = gui_button_row(page, {
            {text = "Rebind Preview to Pointer"}, {text = "Delete Mode: OFF"},
        }, 29)
        gui_bind(edit[1].button, function()
            gui_rebind_preview_to_mouse()
        end)
        gui_delete_button = edit[2].button
        gui_bind(gui_delete_button, function()
            toggle_deletion_mode()
            gui_delete_button.Text = deletion_mode and "Delete Mode: ON" or "Delete Mode: OFF"
            gui_delete_button.TextColor3 = deletion_mode and GUI.warning or GUI.text
        end)

        local position_rotate = gui_button_row(page, {
            {text = "Rotate"},
        }, 29)
        gui_bind(position_rotate[1].button, preview_rotate)

    end

    do
        local page = gui_pages.settings

        gui_field_row(page, {
            {key = "first", title = "First wire", value = tostring(preview_first_wire), placeholder = "1"},
            {key = "last", title = "Last wire", value = preview_last_wire == math.huge and "END" or tostring(preview_last_wire), placeholder = "END"},
        }, 50)
        gui_toggle_field_row(page, {
            {key = "rescale", title = "Auto rescale", value = enable_rescale},
            {key = "check_mode", title = "Check mode", value = check_mode},
        }, 50)
        gui_field_row(page, {
            {key = "height", title = "Height", value = default_art_height and gui_format_num(default_art_height) or "", placeholder = "blank"},
            {key = "width", title = "Width", value = default_art_width and gui_format_num(default_art_width) or "", placeholder = "blank"},
        }, 50)
        gui_full_field(page, "anchor", "Preview anchor", preview_anchor_position, "BottomCenterCenter")
        gui_toggle_field_row(page, {
            {key = "test_vectors", title = "My art", value = use_test_vectors},
            {key = "test_art", title = "Test art", value = use_test_art},
        }, 50)
        gui_large_field(
            page,
            "my_art",
            "My art data",
            my_art_text,
            "{\n    {Vector3.new(x, y, z), Vector3.new(x, y, z)},\n}",
            170
        )

        for _, key in ipairs({
            "first", "last", "height", "width", "anchor", "my_art",
            "move_h", "move_v", "move_d",
        }) do
            local field = gui_fields[key]
            if field then
                table.insert(gui_connections, field.FocusLost:Connect(function()
                    local ok_settings, err = gui_apply_settings_from_fields()
                    if not ok_settings then
                        gui_set_status(err, true)
                    else
                        gui_set_status("Setting updated.")
                        if key == "first" or key == "last" then
                            apply_preview_range("GUI", false)
                        end
                    end
                    gui_refresh_fields()
                end))
            end
        end
    end

    do
        local page = gui_pages.circuit

        gui_toggle_row(page, "circuit_enabled", "Enabled", circuit_settings.enabled, function(value)
            circuit_settings.enabled = value
            gui_set_status("Circuit setting updated.")
            gui_refresh_fields()
        end)

        local circuit_options = {}
        for type_name, replicated in pairs(replicated_wires) do
            if replicated and max_lengths[type_name] then
                table.insert(circuit_options, type_name)
            end
        end
        table.sort(circuit_options)

        gui_dropdown(page, "circuit_wire", "Circuit wire type", circuit_settings.wire_type_name, circuit_options, function(option)
            circuit_settings.wire_type_name = option
            gui_set_status("Circuit wire type updated.")
            gui_refresh_fields()
        end)

        gui_toggle_row(page, "circuit_show_old", "Show old wires", circuit_settings.show_old_wires, function(value)
            circuit_settings.show_old_wires = value
            gui_set_status("Circuit setting updated.")
            gui_refresh_fields()
        end)

        gui_toggle_row(page, "circuit_build_old", "Build old wires", circuit_settings.build_old_wires, function(value)
            circuit_settings.build_old_wires = value
            gui_set_status("Circuit setting updated.")
            gui_refresh_fields()
        end)
    end

    do
        local page = gui_pages.report

        local status_panel = gui_make("Frame", {
            BackgroundColor3 = GUI.panel,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 230),
            LayoutOrder = 0,
            ZIndex = 3,
        }, page)
        gui_round(status_panel, 6)
        gui_stroke(status_panel, GUI.border, 1, 0.42)

        gui_report_status_label = gui_label(status_panel, "", 220, GUI.text, 11)
        gui_report_status_label.Position = UDim2.fromOffset(9, 6)
        gui_report_status_label.Size = UDim2.new(1, -18, 1, -10)
        gui_report_status_label.TextWrapped = gui_is_compact_device()
        gui_report_status_label.TextYAlignment = Enum.TextYAlignment.Top
        gui_report_status_label.ZIndex = 4

        local log_title = gui_label(page, "Build output", 20, GUI.accent, 10)
        log_title.Font = Enum.Font.GothamBold
        log_title.LayoutOrder = 1
        log_title.ZIndex = 4

        local log_panel = gui_make("Frame", {
            BackgroundColor3 = GUI.input,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, gui_is_compact_device() and 220 or 300),
            LayoutOrder = 2,
            ZIndex = 3,
        }, page)
        gui_round(log_panel, 6)
        gui_stroke(log_panel, GUI.border, 1, 0.42)

        gui_report_log_scroll = gui_make("ScrollingFrame", {
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(5, 5),
            Size = UDim2.new(1, -10, 1, -10),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollingEnabled = true,
            ScrollBarImageColor3 = GUI.accent_dark,
            ScrollBarImageTransparency = 0.2,
            ScrollBarThickness = gui_is_compact_device() and 7 or 4,
            ClipsDescendants = true,
            ZIndex = 4,
        }, log_panel)

        gui_report_log_label = gui_label(gui_report_log_scroll, "", 20, GUI.muted, 11)
        gui_report_log_label.Position = UDim2.fromOffset(5, 4)
        gui_report_log_label.Size = UDim2.new(1, -10, 0, 20)
        gui_report_log_label.TextWrapped = false
        gui_report_log_label.TextYAlignment = Enum.TextYAlignment.Top
        gui_report_log_label.Font = Enum.Font.Code
        gui_report_log_label.ZIndex = 5

        gui_report_set_range_baseline()
        gui_report_update_text()
    end

    gui_ready = true
    for _, early_line in ipairs(gui_report_early_log_lines or {}) do
        table.insert(gui_report_log_lines, early_line)
    end
    gui_report_early_log_lines = {}

    gui_set_active_tab("main")
    gui_refresh_fields()
    gui_update_build_button()
    gui_update_window_layout()
end

-- Destroys the GUI and disconnects its connections.
destroy_gui = function()
    gui_ready = false
    disconnect_gui_drag()
    gui_disconnect_all()
    gui_safe_destroy(gui_root)
    gui_safe_destroy(gui_restore)
    gui_root = nil
    gui_window = nil
    gui_restore = nil
    gui_tabs = {}
    gui_pages = {}
    gui_fields = {}
    gui_build_button = nil
    gui_delete_button = nil
    gui_player_dropdown_refresh = nil
    if shared_env.__WIRE_ART_GUI_CLEANUP == destroy_gui then
        shared_env.__WIRE_ART_GUI_CLEANUP = nil
    end
end

create_gui()
shared_env.__WIRE_ART_GUI_CLEANUP = destroy_gui

table.insert(gui_connections, RunService.RenderStepped:Connect(function()
    gui_update_position(false)
    gui_update_build_button()
end))

local ok, err = xpcall(
    initialize,
    function(error_message)
        if debug and debug.traceback then
            return debug.traceback(tostring(error_message))
        end
        return tostring(error_message)
    end
)

if not ok then
    report_warn("Initialization error:")
    report_warn(err)
    gui_set_status("Startup error: " .. tostring(err), true)
    shutdown()
    return
end

if ok and not err then
    gui_set_status("Art was not loaded. Check the URL/filename and settings.", true)
else
    gui_refresh_fields()
    gui_report_set_range_baseline()
    gui_report_set_state("Art prepared; press Redraw to create the preview.")
    gui_set_status("Art ready. Press Redraw to create the preview.")
end
