-- general libraries
local event = require("event")
local keyboard = require("keyboard")
local term = require("term")
local unicode = require("unicode")

-- vim-specific libraries
local config = require("vim.config")
local global = require("vim.global")
local screen = require("vim.screen")

local keys = keyboard.keys

local lib = {}

local function noControlChar(char)
  if not pcall(string.char, char) then
    return 2
  elseif string.find(string.char(char), "[%g%s]+") then
    return 1
  else
    return string.char(char) ~= nil
  end
end

local function commandMode()
  local command = ""
  local pos = 1
  term.setCursor(1, global.getVar("termY"))
  term.clearLine()
  term.write(":")

  -- TODO find better way to 'eat' event
  os.sleep(0.1)


  local running = true
  local _, _, char, code = event.pull("key_down")
  while running do
    if code then
      if code == keys.enter then
        term.clearLine()
        running = false
        return command
      end

      if code == keys[config.get("escBtn")] then
        term.clearLine()
        running = false
      end

      if code == keys.back then
        term.setCursor(pos, global.getVar("termY"))

        command = string.sub(command, 1, string.len(command) - 1)
        pos = pos - 1
        if pos < 1 then
          pos = 1
        end
      end
    end

    if char and noControlChar(char) == 1 then
      char = string.char(char)
      --command[pos] = char
      command = command..char
      pos = pos + 1
      term.setCursor(pos, global.getVar("termY"))
      term.write(char)
    end
    _, _, char, code = event.pull("key_down")
  end
end

local function insertText( pos, text )
  global.setVar( "hasChanged", true )
  local line, column

  if pos == "newline"    or
     pos == "prevline" then
     line = global.getVar("currentLine") + 1
     global.insertLine( line, text )
  else
    line = global.getVar("currentLine")
    if pos == "here" then
      column = global.getVar("currentColumn")
    elseif pos == "after" then
      column = global.getVar("currentColumn") + 1
    elseif pos == "beginning" then
      column = string.len(string.match(global.getLine(line), "%s*"))
      column = column + 1
    elseif pos == "0" then
      column = 1
    elseif pos == "end" then
      column = string.len(global.getLine(line))
    end
    strBefore = string.sub(global.getLine( line ), 1, column - 1)
    strAfter  = string.sub(global.getLine( line ), column )

    global.setLine( line, strBefore .. text .. strAfter )
  end


end

-- pos: where should insert mode be entered in realtion to the cursor
local function insertMode( pos )
  -- TODO find better way to eat event
  os.sleep(0.1)

  local strBefore
  local strAfter

  local strChange = ""

  global.setVar("hasChanged", true)

  if pos == "here" then
  elseif pos == "after" then
    global.setVar("currentColumn", global.getVar("currentColumn") + 1)
  elseif pos == "beginning" then
    global.setVar("currentColumn", string.len(string.match(global.getCurLine(), "%s*")) + 1)
  elseif pos == "0" then
    global.setVar("currentColumn", 1)
  elseif pos == "end" then
    global.setVar("currentColumn", string.len(global.getCurLine()) + 1)
  elseif pos == "newline" then
    global.setVar("hasChanged", true)
    global.setVar("currentLine", global.getVar("currentLine") + 1)
    global.insertLine(global.getVar("currentLine"), "")
    global.setVar("currentColumn", 1)
  elseif pos == "prevline" then
    global.setVar("hasChanged", true)
    global.insertLine(global.getVar("currentLine") + 1, global.getCurLine())
    global.setLine(global.getVar("currentLine"), "")
    global.setVar("currentColumn", 1)
  end

  strBefore = string.sub(global.getCurLine(), 1, global.getVar("currentColumn") - 1)
  strAfter = string.sub(global.getCurLine(), global.getVar("currentColumn"))

  -- TODO the cursor should blink while in insert mode

  screen.redraw()

  local _, _, char, code = event.pull("key_down")
  while true do
    if code then

      if code == keys[config.get("escBtn")] then
        -- the cursor can be one step to far to the right
        -- this happens when appending text to a line
        local strLen = string.len(global.getCurLine())
        if global.getVar("currentColumn") > strLen then
          global.setVar("currentColumn", strLen)
        end

        break
      end

      -- TODO You currently can backspace past the screen
      if code == keys.back then
        strBefore = string.sub(strBefore, 1, string.len(strBefore) - 1)
        global.setVar("currentColumn", global.getVar("currentColumn") - 1)
        global.setLine(global.getVar("currentLine"), strBefore..strAfter)

        strChange = string.sub( strChange, 1, string.len(strChange) - 1 )

        --term.setCursorPos(column, line)
      end

      if code == keys.delete then
        strAfter = string.sub(strAfter, 2)
        global.setLine(global.getVar("currentLine"), strBefore..strAfter)

        --term.setCursorPos(column, line)
      end

      -- TODO this sholud be better
      if code == keys.enter then
        global.setVar("hasChanged", true)

        global.setLine(global.getVar("currentLine"), strBefore)

        global.setVar("currentLine", global.getVar("currentLine") + 1)
        global.setVar("currentColumn", 1)
        global.insertLine(global.getVar("currentLine"), strAfter)
        strBefore = ""

        strChange = strChange .. "\n"

        --screen.redraw()
      end

      screen.redraw()
    end

    -- text entry
    if char and noControlChar(char) then
      char = unicode.char(char)
      global.setVar("hasChanged", true)
      global.setVar("currentColumn", global.getVar("currentColumn") + 1)

      strBefore = strBefore..char
      strChange = strChange .. char

      global.setLine(global.getVar("currentLine"), strBefore..strAfter)

      screen.redraw()
    end

    -- pull next event
    _, _, char, code = event.pull("key_down")
  end

  return strChange
end

local function normalMode()
  -- This is here to prevent a dependency cycle.
  local command = require("vim.command")

  term.setCursorBlink(false)


  local keyPresses = {}

  global.setVar("running", true)
  while global.getVar("running") do
    local _, _, char, code = event.pull("key_down")

    if code then
      if code == keys[config.get("escBtn")] then
        keyPresses = {}
      end
    end
    if char and noControlChar(char) then
      char = unicode.char(char)
      if char == ":" then
        local cmd = commandMode() or ""
        command.runExCommand( cmd )
        keyPresses = {}
      end

      keyPresses[#keyPresses + 1] = char

      local triggered = command.runViCommand( keyPresses )

      if triggered then
        keyPresses = {}
      end
    end
  end
end

lib.noControlChar = noControlChar
lib.commandMode = commandMode
lib.insertText = insertText
lib.insertMode = insertMode
lib.normalMode = normalMode

return lib
