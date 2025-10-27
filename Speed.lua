script_name("Alt Speed Boost (Working)")
script_author("VladisX")
require "lib.moonloader"
local vkeys = require "vkeys"
local boostMultiplier = 1.3 -- множник для збільшення швидкості

function main()
    while not isSampAvailable() do
        wait(100)
    end
    wait(500)
    while true do
        wait(0)
        if isCharInAnyCar(PLAYER_PED) then
            local veh = storeCarCharIsInNoSave(PLAYER_PED)
            if isKeyDown(VK_MENU) then
                local currentSpeed = getCarSpeed(veh)
                setCarForwardSpeed(veh, currentSpeed * boostMultiplier) -- множимо поточну швидкість
            end
        end
    end

end
