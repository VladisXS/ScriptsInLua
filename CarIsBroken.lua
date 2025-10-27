script_name('Auto Break Car')
script_author('VladisX')

require "lib.moonloader"

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('fcar', breakCar)

    wait(-1)
end

function breakCar()
    -- Перевіряємо чи ти взагалі в машині (водій або пасажир)
    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)

        -- Ламаємо двигун
        setCarHealth(car, 250)

        -- Вимикаємо двигун
        setCarEngineOn(car, false)
    end

end
