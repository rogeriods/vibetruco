function love.conf(t)
    t.identity = "truco"
    t.version = "11.5"
    t.title = "Truco"
    t.author = "truco"

    -- retrato, pensado pra celular
    t.window.width = 540
    t.window.height = 960
    t.window.resizable = true
    t.window.highdpi = true
    t.window.vsync = 1
    t.window.msaa = 4

    t.modules.touch = true
    t.modules.audio = true
end
