local fs = require("filesystem")
local package = require("package")

local userPath = "~/.vimrc"

local lib = {}

local defaultPath, msg = package.searchpath("vim.vimrcDefault", package.path)
if not defaultPath then
  error( "Sucks to be you, the vimrcDefault is missing (or possibly just broken). Error: " .. msg)
end

local cfg = {}

local function loadCfg(path)
  local cfgenv = {}
  setmetatable(cfgenv, {__index = _G})
  local cfgfunc = loadfile(path, nil, cfgenv)
  local success
  if cfgfunc then
    success = pcall(cfgfunc)
  end
  if cfgfunc and success then
    for k,v in pairs(cfgenv) do
      cfg[k] = v
    end
  end
end

loadCfg(defaultPath)

if fs.exists(userPath) then
  loadCfg(userPath)
end

function lib.get( key )
  return cfg[key]
end

return lib
