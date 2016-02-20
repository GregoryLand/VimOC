-- general libraries
local component = require("component")
local event = require("event")
local term = require("term")

-- vim-specific libraries
local global = require("vim.global")

local gpu = component.gpu

local lib = {}

local function blit(text, foreground, background)
  local back, front = gpu.getBackground(), gpu.getForeground()
  gpu.setBackground(background)
  gpu.setForeground(foreground)
  term.write(text)
  gpu.setBackground(back)
  gpu.setForeground(front)
end

local function redraw()
	--term.clear()
	term.setCursor(1, 1)

	local topLine = global.getVar("topLine")
	local lineskip = 0

	-- TODO maybe this should, like the real vim, have that when a line is
	-- to long to render instead an '@' shows up indicating that there is more
	-- TODO also, then a line as longer than the number of characters on the screen,
	-- displaying lines before the lines breaks down
	--
	-- This is a while loop to be able to do the check is go around
	local i=topLine
	while i <= topLine + global.getVar("termY") - 2 - lineskip do
		term.clearLine()
		local tLine = global.getLine(i)
		if tLine ~= nil then
			for l=1, string.len(tLine) do
				if i == global.getVar("currentLine") and
				   l == global.getVar("currentColumn") then
					blit(tLine:sub(l,l), 0x191919, 0xF0F0F0)
				else
					term.write(tLine:sub(l,l))
				end
				if l % global.getVar("termX") == 0 then
					lineskip = lineskip + 1
					io.write("\n")
					term.clearLine()
				end
			end
			-- if inputing data at the end of the line
			if global.getVar("currentColumn") == string.len(tLine) + 1 and
			   global.getVar("currentLine") == i then
				blit(" ", 0x191919, 0xF0F0F0)
			end
		else
			io.write("~")
		end
		io.write("\n")
		i = i + 1
	end
end

-- for error messages shown at the bottom of the screen
local function echoerr( message )
	term.setCursor(1, global.getVar("termY"))
  local back = gpu.getBackground()
	gpu.setBackground( 0xCC4C4C )
	term.write( message )
	gpu.setBackground( back )
end

-- for other messages to be shown at the bottom of the screen
local function echo( message )
	term.setCursor(1, global.getVar("termY"))
	term.write( message )
end

-- returns false if line couldn't be redrawn
local function redrawLine( lineNo )
	local topLine = global.getVar("topLine")
	local line = global.getLine( lineNo )

	if lineNo < topLine then
		return false
	end
	if lineNo >= topLine + global.getVar("termX") then
		return false
	end

	local positionOnScreen = lineNo - topLine
	for i=topLine, lineNo do
	end
end

local function drawLine( lineNo )
	local tLine = global.getLine( lineNo )
	for l=1, string.len(tLine) do
		if i == global.getVar("currentLine") and
		   l == global.getVar("currentColumn") then
			blit(tLine:sub(l,l), 0x191919, 0xF0F0F0)
		else
			term.write(tLine:sub(l,l))
		end
		if l % global.getVar("termX") == 0 then
			lineskip = lineskip + 1
			io.write("\n")
		end
	end
end

local function debug( message )
	term.setCursor(global.getVar("termX") - string.len(message) + 1,
	                  global.getVar("termY"))
	if message==nil then
		term.write("nil")
	else
		term.write(message)
	end
	event.pull("key_down")
end

lib.redraw = redraw
lib.echoerr = echoerr
lib.echo = echo
lib.redrawLine = redrawLine
lib.drawLine = drawLine
lib.debug = debug

return lib
