script_name('VladisX')
script_author('VladisX')
script_version('1.3')

require "lib.moonloader"
local sampev = require 'lib.samp.events'
require "lib.sampfuncs"

local tag = "{00FF00}[RouteBot]: "
local isRecording = false
local isPlaying = false
local recordedRoute = {}
local playThread = nil
local recordThread = nil
local lastRecordTime = 0

local settings = {
    recordInterval = 150,
    smoothTurning = true
}

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('recstart', startRecording)
    sampRegisterChatCommand('recstop', stopRecording)
    sampRegisterChatCommand('playstart', startPlaying)
    sampRegisterChatCommand('startbotd', startPlaying)
    sampRegisterChatCommand('playstop', stopPlaying)
    sampRegisterChatCommand('stopbotd', stopPlaying)
    sampRegisterChatCommand('routesave', saveRoute)
    sampRegisterChatCommand('routeload', loadRoute)

    sampAddChatMessage(tag .. "Bot loaded. Commands: /recstart, /recstop, /startbotd, /stopbotd", -1)

    while true do wait(0) end
end

function startRecording()
    if isRecording then
        sampAddChatMessage(tag .. "Recording is already in progress!", -1)
        return
    end
    if not isCharInAnyCar(PLAYER_PED) then
        sampAddChatMessage(tag .. "You need to be in a car!", -1)
        return
    end

    recordedRoute = {}
    isRecording = true
    lastRecordTime = os.clock()

    recordThread = lua_thread.create(function()
        while isRecording do
            if (os.clock() - lastRecordTime) * 1000 >= settings.recordInterval then
                recordPosition()
                lastRecordTime = os.clock()
            end
            wait(0)
        end
    end)

    sampAddChatMessage(tag .. "Route recording started. Interval: "..settings.recordInterval.."ms", -1)
end

function stopRecording()
    if not isRecording then
        sampAddChatMessage(tag .. "Recording is not active!", -1)
        return
    end

    isRecording = false
    if recordThread then
        recordThread:terminate()
        recordThread = nil
    end

    sampAddChatMessage(tag .. "Recording stopped. Points recorded: "..#recordedRoute, -1)
end

function recordPosition()
    local ped = PLAYER_PED
    local car = storeCarCharIsInNoSave(ped)
    if not car then return end

    local x, y, z = getCarCoordinates(car)
    local heading = getCarHeading(car)
    local speed = getCarSpeed(car)

    table.insert(recordedRoute, {
        x = x,
        y = y,
        z = z,
        heading = heading,
        speed = speed,
        timestamp = os.clock()
    })
end

function startPlaying()
    if isPlaying then
        sampAddChatMessage(tag .. "Playback is already in progress!", -1)
        return
    end
    if #recordedRoute == 0 then
        sampAddChatMessage(tag .. "Route not recorded! Use /routeload to load a route", -1)
        return
    end
    if not isCharInAnyCar(PLAYER_PED) then
        sampAddChatMessage(tag .. "You need to be in a car!", -1)
        return
    end

    isPlaying = true
    local car = storeCarCharIsInNoSave(PLAYER_PED)

    playThread = lua_thread.create(function()
        sampAddChatMessage(tag .. "Route playback started. Points: "..#recordedRoute, -1)

        for i = 1, #recordedRoute do
            if not isPlaying then break end

            local point = recordedRoute[i]

            if not doesVehicleExist(car) then
                sampAddChatMessage(tag .. "Vehicle doesn't exist! Stopping playback", -1)
                break
            end

            if settings.smoothTurning and i > 1 then
                local prev = recordedRoute[i - 1]
                for s = 1, 10 do
                    if not isPlaying then break end
                    local t = s / 10
                    local x = prev.x + (point.x - prev.x) * t
                    local y = prev.y + (point.y - prev.y) * t
                    local z = prev.z + (point.z - prev.z) * t

                    local angleDiff = point.heading - prev.heading
                    if angleDiff > 180 then angleDiff = angleDiff - 360 end
                    if angleDiff < -180 then angleDiff = angleDiff + 360 end
                    local heading = prev.heading + angleDiff * t

                    local speed = prev.speed + (point.speed - prev.speed) * t

                    setCarCoordinates(car, x, y, z)
                    setCarHeading(car, heading)

                    if speed > 0 then
                        setCarForwardSpeed(car, speed)
                    end

                    wait(10)
                end
            else
                setCarCoordinates(car, point.x, point.y, point.z)
                setCarHeading(car, point.heading)

                if point.speed > 0 then
                    setCarForwardSpeed(car, point.speed)
                end

                wait(10)
            end
        end

        isPlaying = false
        sampAddChatMessage(tag .. "Route completed!", -1)
    end)
end

function stopPlaying()
    if not isPlaying then
        sampAddChatMessage(tag .. "Playback is not active!", -1)
        return
    end

    isPlaying = false
    if playThread then
        playThread:terminate()
        playThread = nil
    end

    sampAddChatMessage(tag .. "Playback stopped!", -1)
end

function saveRoute(arg)
    if #recordedRoute == 0 then
        sampAddChatMessage(tag .. "No data to save!", -1)
        return
    end

    local filename = arg and #arg > 0 and arg or "route.dat"
    local file = io.open(getWorkingDirectory().."/"..filename, "w")

    if file then
        local jsonData = encodeJson(recordedRoute)
        file:write(jsonData)
        file:close()
        sampAddChatMessage(tag .. "Route saved to file: "..filename, -1)
    else
        sampAddChatMessage(tag .. "File save error!", -1)
    end
end

function loadRoute(arg)
    local filename = arg and #arg > 0 and arg or "route.dat"
    local file = io.open(getWorkingDirectory().."/"..filename, "r")

    if file then
        local data = file:read("*a")
        file:close()

        local success, result = pcall(decodeJson, data)
        if success and result then
            recordedRoute = result
            sampAddChatMessage(tag .. "Route loaded. Points: "..#recordedRoute, -1)
        else
            sampAddChatMessage(tag .. "File parsing error!", -1)
        end
    else
        sampAddChatMessage(tag .. "File loading error!", -1)
    end
end

function decodeJson(str)
    return loadstring("return "..str)()
end