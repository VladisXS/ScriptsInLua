script_name('Car Break Area')
script_author('Your Name')

require "lib.moonloader"

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('fcar', breakCar)
    sampRegisterChatCommand('excar', breakCarsInRadius)

    sampAddChatMessage('Скрипт завантажено! /fcar - твоя машина, /excar - всі навколо', -1)

    wait(-1)
end

function breakCar()
    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        setCarHealth(car, 250)
        setCarEngineOn(car, false)
        sampAddChatMessage('Машину зламано!', -1)
    else
        sampAddChatMessage('Ти не в машині!', -1)
    end
end

function breakCarsInRadius()
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local count = 0

    for i = 0, 2000 do
        local result, id = sampGetVehicleIdByCarHandle(i)
        if result and doesVehicleExist(i) then
            local vx, vy, vz = getCarCoordinates(i)
            local dist = getDistanceBetweenCoords3d(px, py, pz, vx, vy, vz)

            if dist <= 30.0 then
                setCarHealth(i, 250)
                count = count + 1
            end
        end
    end

    sampAddChatMessage('Зламано машин: ' .. count, -1)
end