script_name("Arizona Mine Helper")
script_author("VladisX")
script_version("2.6")

require "lib.moonloader"
require "lib.sampfuncs"
local imgui = require "mimgui"
local encoding = require "encoding"
encoding.default = "CP1251"
local u8 = encoding.UTF8
local sf = require "lib.sampfuncs"

local spawnPoints = {}
local configFile = getWorkingDirectory() .. "\\config\\mine_points.json"
local mainWindow = imgui.new.bool(false)
local enabled = imgui.new.bool(true)
local addPointMode = imgui.new.bool(false)
local defaultRespawnTime = imgui.new.int(380)
local font = nil

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    font = renderCreateFont("Arial", 10, 5)

    loadSpawnPoints()
    sampAddChatMessage("[Mine Helper] {FFFFFF}Skrypt zavantazheno!", 0x00FF00)
    sampAddChatMessage("[Mine Helper] {FFFFFF}Komandy: {00FF00}/minehelp {FFFFFF}- menyu, {00FF00}/addpoint {FFFFFF}- rezhym dodavannya", 0x00FF00)

    sampRegisterChatCommand("minehelp", function() mainWindow[0] = not mainWindow[0] end)
    sampRegisterChatCommand("addpoint", function()
        addPointMode[0] = not addPointMode[0]
        if addPointMode[0] then
            sampAddChatMessage("[Mine Helper] {00FF00}Rezhym dodavannya tochok uvimkneno! Natysny Q bilya resursu", 0x00FF00)
        else
            sampAddChatMessage("[Mine Helper] {FF0000}Rezhym dodavannya tochok vymkneno!", 0xFF0000)
        end
    end)

    local lastUpdate = os.clock()
    while true do
        wait(0)

        if os.clock() - lastUpdate >= 1 and enabled[0] then
            lastUpdate = os.clock()
            for i, point in ipairs(spawnPoints) do
                if point.reloading then
                    point.reloadTime = point.reloadTime + 1
                    if point.reloadTime >= 9 then
                        point.reloading = false
                        point.reloadTime = 0
                        point.active = false
                        point.currentTime = 0
                        point.notified = false
                        sampAddChatMessage(string.format("[Mine Helper] {00FF00}Tochka #%d: taymer pochynayetsya!", i), 0x00FF00)
                    end
                elseif not point.active then
                    point.currentTime = point.currentTime + 1

                    if point.currentTime == point.respawnTime - 19 and not point.notified then
                        sampAddChatMessage(string.format("[Mine Helper] {FFFF00}Tochka #%d bude dostupna cherez 19 sekund!", i), 0xFFFF00)
                        point.notified = true
                    end

                    if point.currentTime >= point.respawnTime then
                        point.reloading = true
                        point.reloadTime = 0
                        point.notified = false
                        sampAddChatMessage(string.format("[Mine Helper] {FFFF00}Tochka #%d: perezaryadka 9 sek!", i), 0xFFFF00)
                    end
                end
            end
        end

        if addPointMode[0] and isKeyJustPressed(0x51) then
            local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
            table.insert(spawnPoints, {
                x = posX, y = posY, z = posZ,
                respawnTime = defaultRespawnTime[0],
                currentTime = 0,
                active = true,
                reloading = false,
                reloadTime = 0,
                notified = false
            })
            saveSpawnPoints()
            sampAddChatMessage(string.format("[Mine Helper] {00FF00}Dodano tochku #%d (%.1f, %.1f, %.1f)", #spawnPoints, posX, posY, posZ), 0x00FF00)
        end

        if enabled[0] and isKeyDown(0x11) and isKeyDown(0x12) then
            local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
            for i, point in ipairs(spawnPoints) do
                local distance = getDistanceBetweenCoords3d(posX, posY, posZ, point.x, point.y, point.z)
                if distance < 3.0 and point.active then
                    point.active = false
                    point.currentTime = 0
                    point.reloading = false
                    point.reloadTime = 0
                    point.notified = false
                    saveSpawnPoints()
                    sampAddChatMessage(string.format("[Mine Helper] {00FF00}Tochka #%d: taymer %d sek!", i, point.respawnTime), 0x00FF00)
                    wait(500)
                    break
                end
            end
        end

        if enabled[0] and font then
            local sw, sh = getScreenResolution()
            for i, point in ipairs(spawnPoints) do
                local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                local distance = getDistanceBetweenCoords3d(posX, posY, posZ, point.x, point.y, point.z)
                if distance < 300 and isPointInFront(point.x, point.y, point.z) then
                    local color = point.active and 0x6000FF00 or (point.reloading and 0x60FFFF00 or 0x60FF0000)
                    local sx, sy = convert3DCoordsToScreen(point.x, point.y, point.z)
                    local sx2, sy2 = convert3DCoordsToScreen(point.x, point.y, point.z + 1)

                    if sx and sy and sx2 and sy2 and sx >= 0 and sy >= 0 and sx < sw and sy < sh then
                        local height = math.abs(sy2 - sy)
                        local width = height / 2

                        if height > 5 and height < 300 then
                            local bx = sx - width / 2
                            local by = sy - height

                            renderDrawBox(bx, by, width, height, color)

                            local lineColor = point.active and 0xFF00FF00 or (point.reloading and 0xFFFFFF00 or 0xFFFF0000)
                            renderDrawLine(bx, by, bx + width, by, 2, lineColor)
                            renderDrawLine(bx + width, by, bx + width, by + height, 2, lineColor)
                            renderDrawLine(bx + width, by + height, bx, by + height, 2, lineColor)
                            renderDrawLine(bx, by + height, bx, by, 2, lineColor)

                            renderFontDrawText(font, string.format("#%d", i), sx - 15, sy - 15, 0xFFFFFFFF)
                            if point.active then
                                renderFontDrawText(font, "DOSTUPNO", sx - 30, sy, 0xFF00FF00)
                            elseif point.reloading then
                                renderFontDrawText(font, string.format("RELOAD: %ds", 9 - point.reloadTime), sx - 35, sy, 0xFFFFFF00)
                            else
                                local timeLeft = point.respawnTime - point.currentTime
                                local minutes = math.floor(timeLeft / 60)
                                local seconds = timeLeft % 60
                                renderFontDrawText(font, string.format("%02d:%02d", minutes, seconds), sx - 20, sy, 0xFFFFFFFF)
                            end
                            renderFontDrawText(font, string.format("%.1fm", distance), sx - 15, sy + 15, 0xFFFFFF00)
                        end
                    end
                end
            end
        end

        if addPointMode[0] and font then
            renderFontDrawText(font, "Rezhym dodavannya tochok: Natysny Q bilya resursu", 10, 400, 0xFF00FF00)
        end
    end
end

function isPointInFront(x, y, z)
    local camX, camY, camZ = getActiveCameraCoordinates()
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    if not camX or not px then return false end
    local dist = getDistanceBetweenCoords3d(camX, camY, camZ, x, y, z)
    local screenX, screenY = convert3DCoordsToScreen(x, y, z)
    local sw, sh = getScreenResolution()
    if not screenX or not screenY or not sw or not sh then return false end
    local vecX, vecY, vecZ = x - camX, y - camY, z - camZ
    local camToPlayerX, camToPlayerY = px - camX, py - camY
    local dot = vecX * camToPlayerX + vecY * camToPlayerY
    return dist < 300 and screenX > 0 and screenX < sw and screenY > 0 and screenY < sh and dot > 0
end

function saveSpawnPoints()
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    local file = io.open(configFile, "w")
    if file then
        local json = encodeJson(spawnPoints)
        file:write(json)
        file:close()
    end
end

function loadSpawnPoints()
    if doesFileExist(configFile) then
        local file = io.open(configFile, "r")
        if file then
            local content = file:read("*all")
            file:close()
            local success, result = pcall(decodeJson, content)
            if success and result then
                spawnPoints = result
                for i, point in ipairs(spawnPoints) do
                    point.respawnTime = 380
                    point.active = true
                    point.currentTime = 0
                    point.reloading = false
                    point.reloadTime = 0
                    point.notified = false
                end
            else
                spawnPoints = {}
            end
        end
    end
end

imgui.OnFrame(function() return mainWindow[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(450, 500), imgui.Cond.FirstUseEver)
    imgui.Begin(u8"Pomichnyk shakhty Arizona RP", mainWindow)

    if imgui.Checkbox(u8"Uvimknuty vidobrazhennya", enabled) then
        sampAddChatMessage(enabled[0] and "[Mine Helper] {00FF00}Uvimkneno" or "[Mine Helper] {FF0000}Vymkneno", -1)
    end
    imgui.Separator()

    if imgui.Checkbox(u8"Rezhym dodavannya tochok (Q)", addPointMode) then
        sampAddChatMessage(addPointMode[0] and "[Mine Helper] {00FF00}Rezhym dodavannya uvimkneno" or "[Mine Helper] {FF0000}Rezhym dodavannya vymkneno", -1)
    end

    imgui.Text(u8"Standartnyy chas respavnu dlya novykh tochok:")
    imgui.SliderInt(u8"##default_time", defaultRespawnTime, 60, 600)
    imgui.SameLine()
    local minutes = math.floor(defaultRespawnTime[0] / 60)
    local seconds = defaultRespawnTime[0] % 60
    imgui.Text(string.format(u8"%d:%02d", minutes, seconds))

    imgui.Separator()
    imgui.Text(u8"Vs'oho tochok: " .. #spawnPoints)

    imgui.BeginChild("PointsList", imgui.ImVec2(0, 250), true)
    for i, point in ipairs(spawnPoints) do
        local status
        if point.active then
            status = u8"✓ Dostupno"
        elseif point.reloading then
            status = string.format(u8"⚡ Perezaryadka: %ds", 9 - point.reloadTime)
        else
            local timeLeft = point.respawnTime - point.currentTime
            local min = math.floor(timeLeft / 60)
            local sec = timeLeft % 60
            status = string.format(u8"⏱ %d:%02d", min, sec)
        end
        imgui.Text(string.format(u8"#%d: %s", i, status))
        imgui.Text(string.format(u8" Koordynaty: (%.1f, %.1f, %.1f)", point.x, point.y, point.z))

        imgui.Text(u8" Taymer respavnu:")
        imgui.SameLine()
        local tmpTimer = imgui.new.int(point.respawnTime)
        imgui.PushItemWidth(100)
        if imgui.SliderInt(u8"##timer" .. i, tmpTimer, 60, 600) then
            point.respawnTime = tmpTimer[0]
            saveSpawnPoints()
        end
        imgui.PopItemWidth()
        imgui.SameLine()
        local min = math.floor(point.respawnTime / 60)
        local sec = point.respawnTime % 60
        imgui.Text(string.format(u8"%d:%02d", min, sec))
        imgui.SameLine()
        if imgui.SmallButton(u8"Vydalyty##" .. i) then
            table.remove(spawnPoints, i)
            saveSpawnPoints()
            sampAddChatMessage("[Mine Helper] {FF0000}Tochku vydaleno!", 0xFF0000)
        end
        imgui.Separator()
    end
    imgui.EndChild()

    if imgui.Button(u8"Ochystyty vsi tochky", imgui.ImVec2(-1, 0)) then
        spawnPoints = {}
        saveSpawnPoints()
        sampAddChatMessage("[Mine Helper] {FF0000}Vsi tochky vydaleno!", 0xFF0000)
    end

    imgui.Separator()
    imgui.TextWrapped(u8"Instruktsiya:")
    imgui.TextWrapped(u8"• /addpoint - uvimknuty rezhym dodavannya")
    imgui.TextWrapped(u8"• Natysny Q bilya resursu - dodaty mitku")
    imgui.TextWrapped(u8"• Ctrl+Alt bilya zelenoyi - taymer")
    imgui.TextWrapped(u8"• Pry perezakhodi - vsi taymery 6:20")
    imgui.TextWrapped(u8"• Zelenyy = dostupno")
    imgui.TextWrapped(u8"• Zhovtyy = perezaryadka 9 sek")
    imgui.TextWrapped(u8"• Chervonyy = taymer")
    imgui.TextWrapped(u8"• Spovishennya za 19 sek do kintsya")

    imgui.End()
end).HideCursor = true