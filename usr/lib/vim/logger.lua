-- general libraries
local fs = require("filesystem")

local lib = {}

local filename
local file
local logLevel = {
  NONE = 0,
  WARNINGS = 5,
  ALL = 10,
}
local level

lib.logLevel = logLevel

function lib.init( path, llevel )
  level = logLevel[llevel]
  if level > 0 then
    filename = path
    file = fs.open(filename, "a")
  end
end

function lib.info( message )
  if level > 0 then
    file:write("INFO:"..message.."\n")
    file:flush()
  end
end

function lib.warning( message )
  if level > 5 then
    file:write("WARN:"..message.."\n")
    file:flush()
  end
end

function lib.stop()
  file:close()
end

return lib
