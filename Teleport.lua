script_name("TeleportToPlayer")

function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("tp", function(param)
        if param == "" then
            sampAddChatMessage("{FF0000}[TP] Використання: /tp [ID гравця]", -1)
            return
        end

        local id = tonumber(param)
        if not id then
            sampAddChatMessage("{FF0000}[TP] Введи правильний ID!", -1)
            return
        end

        if not sampIsPlayerConnected(id) then
            sampAddChatMessage("{FF0000}[TP] Гравець з таким ID не в грі!", -1)
            return
        end

        local result, handle = sampGetCharHandleBySampPlayerId(id)
        if result then
            local x, y, z = getCharCoordinates(handle)
            setCharCoordinates(PLAYER_PED, x, y, z)

            local name = sampGetPlayerNickname(id)
            sampAddChatMessage("{00FF00}[TP] Телепортовано до гравця " .. name .. " [" .. id .. "]", -1)
        else
            sampAddChatMessage("{FF0000}[TP] Не вдалося знайти гравця!", -1)
        end
    end)

    sampAddChatMessage("{00FF00}[TP] Скрипт завантажено. Використання: /tp [ID]", -1)

    wait(-1)
end