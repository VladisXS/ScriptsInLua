script_name("MultiKeyBind")
script_author("Vladislavchik")

-- Таблиця з біндами: key = текст, який відправляється при натисканні key
local binds = {
    {key = "1", text = "/domkrat"},
    {key = "", text = ""},
    {key = "", text = ""},
    {key = "", text = ""},
    {key = "", text = ""},
}

function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("MultiKeyBind loaded! Press 1-5 to send messages.", -1)

    while true do
        wait(0)
        for _, bind in ipairs(binds) do
            if bind.key ~= "" and bind.text ~= "" and isKeyJustPressed(string.byte(bind.key:upper())) then
                sampSendChat(bind.text)
            end
        end
    end
end
