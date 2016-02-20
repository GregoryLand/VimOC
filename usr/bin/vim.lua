-- general libraries
local component = require("component")
local fs = require("filesystem")
local shell = require("shell")
local term = require("term")

-- vim-specific libraries
local config = require("vim.config")
local global = require("vim.global")
local command = require("vim.command")
local screen = require("vim.screen")
local vimode = require("vim.vimode")
local file = require("vim.file")
local logger = require("vim.logger")

local gpu = component.gpu

-- start main
local args = {...}

local termX, termY = gpu.getResolution()
global.setVar("termX", termX)
global.setVar("termY", termY)


global.setVar("hasChanged", false)

-- TODO check if file is read only
if #args < 1 then
  error("please specify a file")
end

local sPath = shell.resolve( args[1] )
if fs.exists( sPath ) and fs.isDirectory( sPath ) then
  print( "Cannot edit a directory." )
  return
end
global.setVar("fileName", sPath)



-- what absolute line are selected
global.setVar("currentLine", 1)
global.setVar("currentColumn", 1)
global.setVar("topLine", 1)


local lines = file.read(global.getVar("fileName"))
global.setLines(lines)



screen.redraw()



if not fs.isDirectory("/.vimlog") then
  fs.makeDirectory("/.vimlog")
end
logger.init("/.vimlog/vimlog-"..os.date("%Y-%m-%d--%H-%M-%S"), config.get("logLevel"))
logger.info("log file created")


vimode.normalMode()

logger.stop()

term.setCursor(1, 1)
term.clear()
