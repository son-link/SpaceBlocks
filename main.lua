--[[
	SpaceBlocks r4
	© 2016 - 2020 Alfonso Saavedra "Son Link"
	Under the GNU/GPL 3 license
	Source Code -> https://github.com/son-link/SpaceBlocks
	My blog (on Spanish) -> http://son-link.github.io
]]

gameState = 0 -- 0: Main screen, 1: playing, 2: paused, 3: lost live, 4: game over, 5: level up, 6: confirm exit
prevState = 0
local quit = true

math.randomseed(os.time())

blocksLines = {}
startX = 16
startY = 0

lostLiveY = 320
waitResetGame = 3
explosion_pos = nil
explosion_count = 0
exploDelay = 0.2

playerPos = 6

newLineAt = 5
level = 1
newLevelAt = 30
bigFontY = -80
nlPause = 2

scoreText = "SCORE"
score = 0
topScore = 0
cursorY = 0
ifNewGame = false

selectedShip = 0

if love.filesystem.getInfo('topscore.txt') then
	contents = love.filesystem.read('topscore.txt')
	topScore = tonumber(contents)
end
lives = 4

function love.load()
	-- Window config (only on Löve)
	love.window.setMode(320, 480, {resizable=false, centered=true})
	love.graphics.setBackgroundColor(0,0,0)
	
	love.window.setTitle('SpaceBlocks')
	love.window.setIcon(love.image.newImageData('SpaceBlocks.png'))
	
	love.keyboard.setKeyRepeat(true)
	-- set font
	font = love.graphics.newFont('PixelOperator8.ttf', 10)
	love.graphics.setFont(font)
	
	bigFont = love.graphics.newFont('PixelOperator8.ttf', 20)
	
	-- Asset
	asset = love.graphics.newImage('img/asset.png')
	info = love.graphics.newQuad(0, 0, 64, 16, asset:getDimensions())
	block = love.graphics.newQuad(64, 0, 16, 16, asset:getDimensions())
	player = love.graphics.newQuad(0, 16, 48, 32, asset:getDimensions())
	cursor = love.graphics.newQuad(80, 0, 16, 16, asset:getDimensions())
	
	hborder = love.graphics.newImage('img/hborder.png')
	hborder:setWrap('repeat', 'repeat')
	
	limit_line = love.graphics.newImage('img/limit_line.png')
	
	--Explosion sprites
	explosion_pos = love.graphics.newQuad(0, 64, 32, 32, asset:getDimensions())
	
	-- Sounds
	bgm = love.audio.newSource('sounds/bgm.ogg', 'static')
	bgm:setLooping(true)
	
	shotSound = love.audio.newSource('sounds/shot2.wav', 'static')
	exploSound = love.audio.newSource('sounds/explosion.wav', 'static')
	
	p1joystick = nil
end

function love.joystickadded(joystick)
	p1joystick = joystick
end

function love.update(dt)
	if ifNewGame then
		score = 0
		resetGame()
		lives = 4
		newLineAt = 5
		ifNewGame = false
	end
	if lives == 0 and gameState == 1 then
		gameState = 4
	end
	if gameState == 1 then
		if not bgm:isPlaying() then
			bgm:play()
		end
		
		if #blocksLines <= 25 then
			if newLineAt < 0 then
				newLine()
				newLineAt = 5 / level
			else
				newLineAt = newLineAt - dt
			end
		else
			gameState = 3
			newLineAt = 5 - 0.4
		end
	elseif gameState == 3 then
		bgm:stop()
		if explosion_count <= 7 then
			if explosion_count == 0 then
				exploSound:play()
			end
			if exploDelay > 0 then
				exploDelay = exploDelay - dt
			else
				exploDelay = 0.2
				l = 32 * explosion_count
				explosion_pos = love.graphics.newQuad(l, 64, 32, 32, asset:getDimensions())
				explosion_count = explosion_count + 1
			end		
		else
			explosion_count = 0
			resetGame()
			lives = lives - 1
		end
	elseif gameState == 4 then
		moveBigText(dt)
		if score > topScore then
			topScore = score
			love.filesystem.write('topscore.txt', score)
		end
		
	elseif gameState == 6 or gameState == 2 then
		if bgm:isPlaying() then
			bgm:stop()
		end
	end
	if score > topScore then
		scoreText = 'HI-SCORE'
	end
	if newLevelAt == 0 and level < 10 then
		gameState = 5
		moveBigText(dt)
	end
	--[[]if p1joystick ~=nil then
		anyDown = p1joystick:isGamepadDown( 'dpleft' )
		print(anyDown)
	end]]
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	if gameState == 1 or gameState == 2 then
		for i=#blocksLines, 1 ,-1 do
			line = blocksLines[i]
			for n=1,12 do
				if line[n] == 1 then
					love.graphics.draw(asset, block, startX, startY)
					love.graphics.draw(asset, cursor, (playerPos * 16), cursorY)
				end
				startX = startX + 16
			end
			startY = startY + 16
			startX = 16
		end
		startY = 0
		love.graphics.draw(asset, player, (playerPos * 16) - 16, 432)
	end
	
	-- Lateral game borders
	bgQuad = love.graphics.newQuad(0, 0, 2, 384 , 2, 16)
	love.graphics.draw(hborder, bgQuad, 13, 2)
	love.graphics.draw(hborder, bgQuad, 209, 2)
	
	-- Limit line
	love.graphics.draw(limit_line, 0, 397)
	
	
	--for rigt border
	love.graphics.setColor(164, 100, 34)
	love.graphics.rectangle('fill', 224, 0, 98, 480)
	love.graphics.setColor(235, 137, 49)
	love.graphics.rectangle('fill', 232, 8, 80, 464)
	
	-- draw info blocks for score, lives and level
	love.graphics.draw(asset, info, 240, 32)
	love.graphics.draw(asset, info, 240, 72)
	love.graphics.draw(asset, info, 240, 112)
	love.graphics.draw(asset, info, 240, 152)
	
	-- Score, etc
	love.graphics.setColor(0, 0, 0)
	love.graphics.printf(scoreText, 0, 16, 304, 'right')
	love.graphics.printf(score, 0, 35, 300, 'right')
	
	love.graphics.printf("LIVES", 0, 56, 304, 'right')
	love.graphics.printf(lives, 0, 75, 300, 'right')
	
	love.graphics.printf("LEVEL", 0, 96, 304, 'right')
	love.graphics.printf(level - 1, 0, 115, 300, 'right')
	
	love.graphics.printf("UP LEVEL", 0, 136, 304, 'right')
	love.graphics.printf(newLevelAt, 0, 155, 300, 'right')
	
	if gameState == 0 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(bigFont)
		love.graphics.printf('SpaceBlocks', 0, 144, 224, 'center')
		love.graphics.setFont(font)
		love.graphics.printf('Select ship with left and right arrow keys and press FIRE to start', 16, 192, 192, 'center')
		love.graphics.draw(asset, player, (playerPos * 16) - 16, 432)
	elseif gameState == 2 then
		--love.graphics.setColor(0, 0, 255)
		love.graphics.printf('PAUSE', 0, 176, 304, 'right')
	elseif gameState == 3 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(asset, explosion_pos, (playerPos * 16) - 8, 432)
	elseif gameState == 4 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(bigFont)
		love.graphics.printf('GAME\nOVER', 0, bigFontY, 224, 'center')
		love.graphics.setFont(font)
	elseif gameState == 5 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(bigFont)
		love.graphics.printf('LEVEL\nCOMPLETE', 0, bigFontY, 224, 'center')
		love.graphics.setFont(font)
	elseif gameState == 6 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(bigFont)
		love.graphics.printf('Are yoy sure?\nYes/No', 16, 192, 192, 'center')
		love.graphics.setFont(font)
	end
end

function love.joystickpressed(joystick,button)
	anyDown = joystick:isGamepadDown( 'dpleft' )
end

function love.keypressed(key)
	if key == "p" then
		if gameState == 1 then
			gameState = 2
		elseif gameState == 2 then
			gameState = 1
		end
	elseif key == "escape" then
		prevState = gameState
		gameState = 6
		--love.event.quit()
	elseif key == 'space' then
		if gameState == 0 then
			gameState = 1
			ifNewGame = true
		elseif gameState == 1 then
			shot()
		end
	elseif key == 'left' then 
		if gameState == 1 and playerPos > 1 then
			playerPos = playerPos - 1
		elseif gameState == 0 then
			if selectedShip == 0 then
				selectedShip = 3
			else
				selectedShip = selectedShip - 1
			end
		end
	elseif key == 'right' then
		if gameState == 1 and playerPos < 12 then
			playerPos = playerPos + 1
		elseif gameState == 0 then
			if selectedShip == 3 then
				selectedShip = 0
			else
				selectedShip = selectedShip + 1
			end
		end
	end
	if gameState == 6 then
		if key == 'y' then
			quit = false
			love.event.quit()
		elseif key == 'n' then
			gameState = prevState
			quit = true
		end
	end
	player = love.graphics.newQuad(48 * selectedShip, 16, 48, 32, asset:getDimensions())
	setCursorPos()
end

function love.quit()
	print (quit)
	if quit then
		gameState = 6
		quit = false
	else
		return quit
	end
	return true
end

function moveBigText(dt)
	bgm:stop()
	if bigFontY < 176 then
		bigFontY = bigFontY + (dt * 50)
	else
		if nlPause > 0 then
			nlPause = nlPause -dt
		else
			if gameState == 4 then
				gameState = 0
				bigFontY = -80
				nlPause = 2
			elseif gameState == 5 then
				level = level + 1
				newLevelAt = 30 + (10 * level)
				bigFontY = -80
				nlPause = 2
				resetGame()
			end
		end
	end
end

function shuffle(t)
	-- Shuflle the table indicated on the parameter
    local rand = math.random 
    assert(t, "table.shuffle() expected a table, got nil")
    local iterations = #t
    local j
    
    for i = iterations, 2, -1 do
        j = rand(i)
        t[i], t[j] = t[j], t[i]
    end
end

function newLine()
	total = math.random(1, 8)
	line = {}
	for i=1,12 do
		if i <= total then
			line[i] = 1;
		else
			line[i] = 0;
		end
	end
	shuffle(line)
	table.insert(blocksLines, line)
	setCursorPos()
end

function checkPosition()
	local v = false
	for i=1 , #blocksLines do
		line = blocksLines[i]
		if blocksLines[i+1] == nil and line[playerPos] == 0 then
			v = i
			break
		elseif line[playerPos] == 0 and blocksLines[i+1][playerPos] == 1 then
			v = i
			break
		elseif i == 1 and line[playerPos] == 1 or #blocksLines == 0 then
			v = false
			break
		end
	end
	return v
end

function setCursorPos()
	cp = checkPosition()
	if cp then
		if cp == #blocksLines then
			cursorY = 0
		else
			cursorY = (#blocksLines - cp) * 16
		end
	else
		cursorY = #blocksLines * 16
	end
end

function shot()
	shotSound:stop()
	shotSound:play()
	if #blocksLines > 0 then
		local cp = checkPosition()
		if cp then
			if cp == 0 then
				cp = 1
			end
			blocksLines[cp][playerPos] = 1
		else
			tempLine = {}
			tempTable = {}
			for i=1,12 do
				if i == playerPos then
					tempLine[i] = 1
				else
					tempLine[i] = 0
				end
			end
			tempTable[1] = tempLine 
			for i=1 , #blocksLines do
				tempTable[i+1] = blocksLines[i]
			end
			blocksLines = tempTable
		end
	else
		tempLine = {}
		tempTable = {}
		for i=1,12 do
			if i == playerPos then
				tempLine[i] = 1
			else
				tempLine[i] = 0
			end
		end
		blocksLines[1] = tempLine
	end 
	score = score + 10
	checkLines()
	setCursorPos()
end

function checkLines()
	for i=1 , #blocksLines do
		cont = 0
		line = blocksLines[i]
		for i,v in ipairs(line) do
			if v == 1 then
				cont = cont +1
			end
		end
		if cont == 12 then
			newLevelAt = newLevelAt - 1
			table.remove(blocksLines, i)
			setCursorPos()
			break
		end
	end
end

function resetGame()
	playerPos = 6
	blocksLines = {}
	gameState = 1
	moveLostAt = 0.1
	lostLiveY = 320
	setCursorPos()
	newLineAt = 5 - ((level - 1) * 0.4)
	nlPause = 5
end
