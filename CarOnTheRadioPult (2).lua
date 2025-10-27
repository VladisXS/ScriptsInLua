script_name("Remote Car Control")
script_author("Assistant")
script_version("5.0")

require "lib.moonloader"
local keys = require "vkeys"
local raknet = require "samp.raknet"

local cursorEnabled = false
local controlEnabled = false
local targetCar = nil
local vehicleId = -1

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("rcar", cmd_rcar)
    sampAddChatMessage("[Remote Car] MMB - cursor, LMB - select car", 0x00FF00)
    sampAddChatMessage("[Remote Car] Car control: [ ; ' / SPACE", 0x00FFFF)

    while true do
        wait(0)

        -- Middle Mouse Button
        if wasKeyPressed(keys.VK_MBUTTON) then
            cursorEnabled = not cursorEnabled
            showCursor(cursorEnabled, false)
            sampAddChatMessage(cursorEnabled and "[RC] Cursor ON" or "[RC] Cursor OFF", 0x00FFFF)
        end

        -- Left Mouse Button
        if cursorEnabled and wasKeyPressed(keys.VK_LBUTTON) then
            local car = getCarUnderCursor()

            if car and doesVehicleExist(car) then
                local result, vehId = sampGetVehicleIdByCarHandle(car)

                if result and vehId then
                    targetCar = car
                    vehicleId = vehId
                    controlEnabled = true
                    cursorEnabled = false
                    showCursor(false, false)

                    sampAddChatMessage("[RC] Car selected! VehID: " .. vehicleId, 0x00FF00)
                    sampAddChatMessage("[RC] [ forward, / backward, ; left, ' right, SPACE brake", 0x00FFFF)
                end
            end
        end

        -- Control (works even if someone is driving)
        if controlEnabled and targetCar and doesVehicleExist(targetCar) then
            local angle = getCarHeading(targetCar)
            local speed = getCarSpeed(targetCar)
            local hasDriver = false

            -- Check if someone is driving
            local driver = getDriverOfCar(targetCar)
            if driver and driver ~= PLAYER_PED then
                hasDriver = true
            end

            -- [ = Forward (VK_OEM_4)
            if isKeyDown(keys.VK_OEM_4) then
                setCarForwardSpeed(targetCar, 25.0)
            end

            -- / = Backward (VK_OEM_2)
            if isKeyDown(keys.VK_OEM_2) then
                setCarForwardSpeed(targetCar, -15.0)
            end

            -- ; = Left (VK_OEM_1)
            if isKeyDown(keys.VK_OEM_1) then
                angle = angle + 5.0
                if angle >= 360 then angle = angle - 360 end
                setCarHeading(targetCar, angle)
            end

            -- ' = Right (VK_OEM_7)
            if isKeyDown(keys.VK_OEM_7) then
                angle = angle - 5.0
                if angle < 0 then angle = angle + 360 end
                setCarHeading(targetCar, angle)
            end

            -- SPACE = Brake
            if isKeyDown(keys.VK_SPACE) then
                setCarForwardSpeed(targetCar, 0.0)
            end
        end
    end
end

function cmd_rcar()
    controlEnabled = not controlEnabled
    if not controlEnabled then
        targetCar = nil
        vehicleId = -1
        sampAddChatMessage("[RC] Disabled", 0xFF0000)
    else
        sampAddChatMessage("[RC] Use cursor to select car", 0x00FFFF)
    end
end

function getCarUnderCursor()
    local cx, cy = getCursorPos()
    local closestCar = nil
    local closestDist = 100

    for i = 0, 2000 do
        local result, car = sampGetCarHandleBySampVehicleId(i)
        if result and car and doesVehicleExist(car) then
            local x, y, z = getCarCoordinates(car)
            local sx, sy = convert3DCoordsToScreen(x, y, z)
            local dist = math.sqrt((sx - cx)^2 + (sy - cy)^2)

            if dist < closestDist then
                closestDist = dist
                closestCar = car
            end
        end
    end

    return closestCar
end

-- Helper function to convert heading to quaternion
function headingToQuaternion(heading)
    local rad = math.rad(heading)
    local w = math.cos(rad / 2)
    local z = math.sin(rad / 2)
    return w, 0.0, 0.0, z
end

-- Send vehicle sync via RakNet (overrides driver sync)
function raknet.onSendPacket(id, bs)
    if controlEnabled and vehicleId ~= -1 and targetCar and doesVehicleExist(targetCar) then
        if id == 200 then
            local x, y, z = getCarCoordinates(targetCar)
            local heading = getCarHeading(targetCar)
            local qw, qx, qy, qz = headingToQuaternion(heading)

            local newBs = raknetNewBitStream()

            raknetBitStreamWriteInt16(newBs, vehicleId)
            raknetBitStreamWriteInt16(newBs, 0)
            raknetBitStreamWriteInt16(newBs, 0)
            raknetBitStreamWriteInt16(newBs, 0)

            raknetBitStreamWriteFloat(newBs, qw)
            raknetBitStreamWriteFloat(newBs, qx)
            raknetBitStreamWriteFloat(newBs, qy)
            raknetBitStreamWriteFloat(newBs, qz)

            raknetBitStreamWriteFloat(newBs, x)
            raknetBitStreamWriteFloat(newBs, y)
            raknetBitStreamWriteFloat(newBs, z)

            raknetBitStreamWriteFloat(newBs, 0.0)
            raknetBitStreamWriteFloat(newBs, 0.0)
            raknetBitStreamWriteFloat(newBs, 0.0)

            raknetBitStreamWriteFloat(newBs, 1000.0)

            raknetBitStreamWriteInt8(newBs, 100)
            raknetBitStreamWriteInt8(newBs, 0)
            raknetBitStreamWriteInt8(newBs, 0)
            raknetBitStreamWriteInt8(newBs, 0)
            raknetBitStreamWriteInt8(newBs, 0)
            raknetBitStreamWriteInt16(newBs, 0)
            raknetBitStreamWriteFloat(newBs, 0.0)

            raknetSendBitStreamEx(newBs, 1, 7, 1)
            raknetDeleteBitStream(newBs)

            return false
        end
    end
end

-- Block incoming vehicle sync from driver
function raknet.onReceivePacket(id, bs)
    if controlEnabled and vehicleId ~= -1 then
        if id == 200 then
            -- Read vehicle ID from packet
            raknetBitStreamIgnoreBits(bs, 16)
            local incomingVehId = raknetBitStreamReadInt16(bs)
            raknetBitStreamResetReadPointer(bs)

            -- Block sync from other players for our controlled car
            if incomingVehId == vehicleId then
                return false
            end
        end
    end
end

-- Thread to send vehicle sync
lua_thread.create(function()
    while true do
        wait(100)

        if controlEnabled and vehicleId ~= -1 and targetCar and doesVehicleExist(targetCar) then
            local x, y, z = getCarCoordinates(targetCar)
            local heading = getCarHeading(targetCar)
            local qw, qx, qy, qz = headingToQuaternion(heading)

            local bs = raknetNewBitStream()

            raknetBitStreamWriteInt16(bs, vehicleId)
            raknetBitStreamWriteInt16(bs, 0)
            raknetBitStreamWriteInt16(bs, 0)
            raknetBitStreamWriteInt16(bs, 0)

            raknetBitStreamWriteFloat(bs, qw)
            raknetBitStreamWriteFloat(bs, qx)
            raknetBitStreamWriteFloat(bs, qy)
            raknetBitStreamWriteFloat(bs, qz)

            raknetBitStreamWriteFloat(bs, x)
            raknetBitStreamWriteFloat(bs, y)
            raknetBitStreamWriteFloat(bs, z)

            raknetBitStreamWriteFloat(bs, 0.0)
            raknetBitStreamWriteFloat(bs, 0.0)
            raknetBitStreamWriteFloat(bs, 0.0)

            raknetBitStreamWriteFloat(bs, 1000.0)
            raknetBitStreamWriteInt8(bs, 100)
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteInt16(bs, 0)
            raknetBitStreamWriteFloat(bs, 0.0)

            raknetSendBitStreamEx(bs, 1, 7, 1)
            raknetDeleteBitStream(bs)
        end
    end
end)