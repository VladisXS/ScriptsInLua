script_name("ESP")

function main()
    while not isSampAvailable() do wait(100) end
    wait(1000)

    while true do
        wait(0)

        for i = 0, 1000 do
            local res, handle = sampGetCharHandleBySampPlayerId(i)
            if res and doesCharExist(handle) then
                local x, y, z = getCharCoordinates(handle)
                local sx, sy = convert3DCoordsToScreen(x, y, z)
                local sx2, sy2 = convert3DCoordsToScreen(x, y, z + 1)

                if sx >= 0 and sy >= 0 and sx < 10000 and sy < 10000 then
                    local height = math.abs(sy2 - sy)
                    local width = height / 2

                    if height > 5 and height < 300 then
                        local bx = sx - width / 2
                        local by = sy - height

                        -- Зелений квадрат
                        renderDrawBox(bx, by, width, height, 0x6000FF00)

                        -- Рамка (4 лінії)
                        renderDrawLine(bx, by, bx + width, by, 2, 0xFF00FF00)
                        renderDrawLine(bx + width, by, bx + width, by + height, 2, 0xFF00FF00)
                        renderDrawLine(bx + width, by + height, bx, by + height, 2, 0xFF00FF00)
                        renderDrawLine(bx, by + height, bx, by, 2, 0xFF00FF00)
                    end
                end
            end
        end
    end
end