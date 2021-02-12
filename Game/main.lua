-- local OrigRequire = require
-- require = function(string)
--     local path = "lib."
--     return OrigRequire(path .. string)
-- end

math.randomseed(os.time())
local Timer = require("lib.timer")

local Resolution = {
    x = love.graphics.getWidth(),
    y = love.graphics.getHeight()
}

local GameSettings = {
    ComplexityII = 24,
    PlayingIIint = 1,
    StartSpeed = 1.5,
    padXWidtch = 15,
    PadYwidtch = Resolution.y / 5
}

local Ball = {
    x = 0,
    y = 0,
    width = 30,
    vector = {
        x = 10,
        y = 10
    }
}

local PlayerTab = {
    player1 = {
        score = 0,
        x = 10,
        y = Resolution.y / 2 - 60
    },
    player2 = {
        score = 0,
        x = Resolution.x - (10 + GameSettings.padXWidtch),
        y = Resolution.y / 2 - 60
    }
}

local Particl = {
    Pad = {
        x = 0,
        y = 0
    },
    Ball = {
        x = 0,
        y = 0
    }
}
local Ray = {}

local ScoreFont = love.graphics.newFont(40)
local Font = love.graphics.newFont(30)
local FpsFont = love.graphics.newFont(12)
local afterTime = 0
local isStart = false

local SoundBack = love.audio.newSource("resource/BackSound.mp3", "stream")
local SoundBounce = love.audio.newSource("resource/Bounce.mp3", "static")
local SoundGoal = love.audio.newSource("resource/Goal.mp3", "static")
SoundGoal:setVolume(0.3)

local ParticlePong = love.graphics.newImage('resource/PongPart.png')
local ParticleBall = love.graphics.newImage('resource/BallPart.png')
local TextureBackGround = love.graphics.newImage("resource/BackGround.jpg")

function love.load()
    timer = Timer()

    World = love.physics.newWorld()
    local Body = love.physics.newBody(World, 0, 0, "static")
    -- Стнека лево
	local x1, y1 = 0, 0
	local x2, y2 = 0, Resolution.y
	local Shape = love.physics.newEdgeShape(x1, y1, x2, y2)
	local Fixture = love.physics.newFixture(Body, Shape)

    local x1, y1 = Resolution.x, 0
	local x2, y2 = Resolution.x, Resolution.y
	local Shape = love.physics.newEdgeShape(x1, y1, x2, y2)
	local Fixture = love.physics.newFixture(Body, Shape)

    --SoundBack:play()
    
    SetBallStart()
    isStart = true
    StartGameTime = os.time()
    
    -- timer:after(1, function()
    --     afterTime = 3
    --     timer:after(1, function()
    --         afterTime = 2
    --         timer:after(1, function()
    --             afterTime = 1
    --             timer:after(1, function()
    --                 afterTime = 0
    --                 StartGameTime = os.time()
    --                 SetBallStart()
    --                 isStart = true
    --             end)
    --         end)
    --     end)
    -- end)
 
	PongPr = love.graphics.newParticleSystem(ParticlePong, 4)
	PongPr:setParticleLifetime(0.3, 0.3) -- Particles live at least 2s and at most 5s.
	PongPr:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to black.

    BallPr = love.graphics.newParticleSystem(ParticleBall, 5)
	BallPr:setParticleLifetime(1, 2) -- Particles live at least 2s and at most 5s.
	BallPr:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to black.
end

function love.draw()

    -- Фон
    love.graphics.draw( TextureBackGround, 0, 0, 0, 1, 1, 0, 0 )

    if not isStart then
        --Остаток до начала игры
        love.graphics.setFont(Font)
        love.graphics.print(afterTime, Resolution.x / 2, Resolution.y / 2)
    else
        --Скорость 
        -- love.graphics.setFont(Font)
        -- love.graphics.print(("Speed: %.1f"):format(GameSettings.StartSpeed), 5, Resolution.y - 40)

        -- Очки игроков
        love.graphics.setFont(ScoreFont)
        local text = PlayerTab.player1.score .. " I " .. PlayerTab.player2.score
        love.graphics.print(text, (Resolution.x / 2) - text:len() * 8, 10)

        -- М¤ч
        love.graphics.circle('fill', Ball.x, Ball.y, Ball.width)

        -- ФПС
        love.graphics.setFont(FpsFont)
        love.graphics.print("FPS: "..love.timer.getFPS(), 1, 1)
    end
    
    -- Пады
    love.graphics.setColor(0, 0, 0, 100)
    love.graphics.rectangle('fill', PlayerTab.player1.x, PlayerTab.player1.y, GameSettings.padXWidtch, GameSettings.PadYwidtch)
    love.graphics.rectangle('fill', PlayerTab.player2.x, PlayerTab.player2.y, GameSettings.padXWidtch, GameSettings.PadYwidtch)

    -- Обводка
    love.graphics.setColor(196, 0, 255, 10)
    love.graphics.rectangle('line', PlayerTab.player1.x, PlayerTab.player1.y, GameSettings.padXWidtch, GameSettings.PadYwidtch)
    love.graphics.rectangle('line', PlayerTab.player2.x, PlayerTab.player2.y, GameSettings.padXWidtch, GameSettings.PadYwidtch)

    --Откат
    love.graphics.setColor(255, 255, 255, 255)

    -- Партикл пада
    love.graphics.draw(PongPr, Particl.Pad.x, Particl.Pad.y)

    love.graphics.draw(BallPr, Particl.Ball.x, Particl.Ball.y)
end

function love.update(dt)
    timer:update(dt)
    World:update(dt)
    PongPr:update(dt)

    if isStart then
        -- Ускорение скорости каждую секунду
        if os.time() - StartGameTime >= 1 then
            GameSettings.StartSpeed = GameSettings.StartSpeed + 0.05
            StartGameTime = os.time()
        end

        -- Остановка координат м¤чу
        Ball.x = Ball.x + (Ball.vector.x * GameSettings.StartSpeed) * dt
        Ball.y = Ball.y + (Ball.vector.y * GameSettings.StartSpeed) * dt
        
        local BallYMinusOffset = Ball.y - Ball.width
        local BallYPlusOffset = Ball.y + Ball.width
        local BallXMinusOffset = Ball.x - Ball.width
        local BallXPlusOffset = Ball.x + Ball.width

        local table = {
            "player1",
            "player2"
        }
        for i = 1, #table do
            local PlayerString = table[i]
            local bool
            local integer
            
            if i == 1 then
                integer = 1
                bool = BallXMinusOffset <= PlayerTab.player1.x + GameSettings.padXWidtch
            else
                integer = -1
                bool = BallXPlusOffset >= PlayerTab.player2.x
            end

            if bool then
                if BallYPlusOffset >= PlayerTab[PlayerString].y and BallYMinusOffset <= PlayerTab[PlayerString].y + GameSettings.PadYwidtch then
                    -- Отскок от пада
                    BallBounced(3 * integer, "x", true)

                    Particl.Pad.x, Particl.Pad.y = (i == 1 and Ball.x - Ball.width + 10 or Ball.x + Ball.width - 10), Ball.y
                    PongPr:setLinearAcceleration(0, 0, 50 * integer, 0)
                    PongPr:emit(1)
                else
                    -- Возврат мяча на старт
                    PlayerTab[PlayerString].score = PlayerTab[PlayerString].score + 1
                    SetBallStart(true)
                end
            end
        end

        -- Если м¤ч улетел за поле вниз
        if BallYPlusOffset >= Resolution.y then
            BallBounced(-3, "y")
        elseif BallYMinusOffset <= 0 then -- Если м¤ч улетел за поле вверх
            BallBounced(3, "y")
        end

        if love.keyboard.isDown("up") then
            MovePad("player2", true, dt)
        elseif love.keyboard.isDown("down") then
            MovePad("player2", false, dt)
        end

        -- ИИ играет
        IIPlay(dt)
    end
end

function BallBounced(int, tab, isChangeVector)
    Ball[tab] = Ball[tab] + int
    Ball.vector[tab] = Ball.vector[tab] * -1
    SoundBounce:play()

    if isChangeVector then
        Ball.vector.y = math.random(-Resolution.y / 5, Resolution.y / 5)
    end
end

function SetBallStart(goal)
    Ball.x = Resolution.x / 2
    Ball.y = Resolution.y / 2

    local int = {
        [0] = -1,
        [1] = 1
    }
    Ball.vector.x = 300 * int[math.random(0, 1)]
    Ball.vector.y = math.random(Resolution.y / 8, Resolution.y / 8)

    if goal then
        SoundGoal:play()
        local speed = GameSettings.StartSpeed
        GameSettings.StartSpeed = 0
        timer:tween(2, GameSettings, {StartSpeed = speed}, 'in-out-cubic')
    end
end

function MovePad(tab, isPlusMove, dt)
    if isPlusMove then
        if PlayerTab[tab].y >= 10 then
            PlayerTab[tab].y = PlayerTab[tab].y - 500 * dt
        end
    else
        if PlayerTab[tab].y <= Resolution.y - GameSettings.PadYwidtch - 12 then
            PlayerTab[tab].y = PlayerTab[tab].y + 500 * dt
        end
    end
end

function IIPlay(dt)
    local tab = {
        [0] = {},
        [1] = {"player1"},
        [2] = {"player1", "player2"},
    }
    local table = tab[GameSettings.PlayingIIint]
    
    local x, y = Ball.x + Ball.vector.x * GameSettings.ComplexityII, Ball.y + Ball.vector.y * GameSettings.ComplexityII
    World:rayCast(Ball.x, Ball.y, x, y, function (fixture, x, y, xn, yn, fraction)    
        Ray.x, Ray.y = x, y
        return 1
    end)

    for i = 1, #table do
        local tab = table[i]
        local PadMid = PlayerTab[tab].y + GameSettings.PadYwidtch / 2

        if Ray.y then 
            if PadMid - 20 > Ray.y or PadMid + 20 < Ray.y then
                local bool
                if i == 1 then
                    bool = (Ball.vector.x < 0)
                else
                    bool = (Ball.vector.x > 0)
                end

                if bool then
                    MovePad(tab, PadMid > Ray.y, dt)
                end
            end
        end
    end
    Ray = {}
end