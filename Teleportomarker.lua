script_name("TeleportMarker")

local marker = nil
local markerActive = false

function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FF00}[Teleport] Скрипт завантажено. Натисни колесо миші для телепорту", -1)

    while true do
        wait(0)

        -- Перевірка натискання коліщата миші (клавіша 0x04)
        if isKeyJustPressed(0x04) then
            local mode = sampGetCursorMode()

            -- Якщо курсор не активний - активуємо його
            if mode == 0 then
                sampToggleCursor(true)
                markerActive = true
                sampAddChatMessage("{FFFF00}[Teleport] Клікни лівою кнопкою миші куди телепортуватись", -1)
            end
        end

        -- Якщо режим маркера активний
        if markerActive then
            -- Отримуємо позицію курсора
            local cursorX, cursorY = getCursorPos()

            -- Конвертуємо екранні координати в світові
            local camX, camY, camZ = getActiveCameraCoordinates()
            local pointX, pointY, pointZ = convertScreenCoordsToWorld3D(cursorX, cursorY, 700.0)

            local result, colpoint = processLineOfSight(camX, camY, camZ, pointX, pointY, pointZ,
                true, true, false, true, false, false, false)

            if result then
                -- Видаляємо старий маркер якщо є
                if marker then
                    removeBlip(marker)
                end

                -- Створюємо білий маркер
                marker = addBlipForCoord(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3])

                -- Перевірка лівої кнопки миші для телепорту
                if isKeyJustPressed(0x01) then
                    setCharCoordinates(PLAYER_PED, colpoint.pos[1], colpoint.pos[2], colpoint.pos[3])
                    sampAddChatMessage("{00FF00}[Teleport] Телепортовано!", -1)

                    -- Вимикаємо курсор і режим маркера
                    sampToggleCursor(false)
                    markerActive = false

                    -- Видаляємо маркер через секунду
                    lua_thread.create(function()
                        wait(1000)
                        if marker then
                            removeBlip(marker)
                            marker = nil
                        end
                    end)
                end

                -- ESC або права кнопка для скасування
                if isKeyJustPressed(0x1B) or isKeyJustPressed(0x02) then
                    sampToggleCursor(false)
                    markerActive = false
                    if marker then
                        removeBlip(marker)
                        marker = nil
                    end
                    sampAddChatMessage("{FF0000}[Teleport] Скасовано", -1)
                end
            end
        end
    end
end