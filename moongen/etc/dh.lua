------------------------------------------------------------------------
--- @file dh.lua
--- @brief (dh) utility.
--- Utility functions for the dh_header structs 
--- Includes:
--- - dh constants
--- - dh header utility
--- - Definition of dh packets
------------------------------------------------------------------------

--[[
-- Use this file as template when implementing a new protocol (to implement all mandatory stuff)
-- Replace all occurrences of dh with your protocol (e.g. sctp)
-- Remove unnecessary comments in this file (comments inbetween [[...]]
-- Necessary changes to other files:
-- - packet.lua: if the header has a length member, adapt packetSetLength; 
-- 				 if the packet has a checksum, adapt createStack (loop at end of function) and packetCalculateChecksums
-- - proto/proto.lua: add dh.lua to the list so it gets loaded
--]]
local ffi = require "ffi"
require "proto.template"
local initHeader = initHeader


---------------------------------------------------------------------------
---- dh constants 
---------------------------------------------------------------------------

--- dh protocol constants
local dh = {}


---------------------------------------------------------------------------
---- dh header
---------------------------------------------------------------------------

dh.headerFormat = [[
	uint8_t		flag;
	uint8_t		len;
	uint16_t	vdp_id;
]]

--- Variable sized member
dh.headerVariableMember = nil

--- Module for dh_address struct
local dhHeader = initHeader()
dhHeader.__index = dhHeader

--[[ for all members of the header with non-standard data type: set, get, getString 
-- for set also specify a suitable default value
--]]
--- Set the XYZ.
--- @param int XYZ of the dh header as A bit integer.
function dhHeader:setFlag(int)
	int = int or 0
	self.flag = hton16(int)
end

--- Retrieve the XYZ.
--- @return XYZ as A bit integer.
function dhHeader:getFlag()
	return hton16(self.flag)
end

function dhHeader:getFlagString()
	return self.getFlag
end

function dhHeader:setLen(int)
	int = int or 0
	self.len = hton16(int)
end

function dhHeader:getLen()
	return hton16(self.len)
end

function dhHeader:getLenString()
	return self.getLen
end

function dhHeader:setVdp_id(int)
	int = int or 0
	self.vdp_id = hton16(int)
end

function dhHeader:getVdp_id()
	return hton16(self.vdp_id)
end

function dhHeader:getVdp_idString()
	return self.getVdp_id
end

--- Set all members of the dh header.
--- Per default, all members are set to default values specified in the respective set function.
--- Optional named arguments can be used to set a member to a user-provided value.
--- @param args Table of named arguments. Available arguments: dhXYZ
--- @param pre prefix for namedArgs. Default 'dh'.
--- @code
--- fill() -- only default values
--- fill{ dhXYZ=1 } -- all members are set to default values with the exception of dhXYZ, ...
--- @endcode
function dhHeader:fill(args, pre)
	args = args or {}
	pre = pre or "dh"

	self:setFlag(args[pre .. "Flag"])
	self:setLen(args[pre .. "Len"])
	self:setVdp_id(args[pre .. "Vdp_id"])
end

--- Retrieve the values of all members.
--- @param pre prefix for namedArgs. Default 'dh'.
--- @return Table of named arguments. For a list of arguments see "See also".
--- @see dhHeader:fill
function dhHeader:get(pre)
	pre = pre or "dh"

	local args = {}
	args[pre .. "Flag"] = self:getFlag()
	args[pre .. "Len"] = self:getLen()
	args[pre .. "Vdp_id"] = self:getVdp_id() 

	return args
end

--- Retrieve the values of all members.
--- @return Values in string format.
function dhHeader:getString()
	return "dh flag " .. self:getFlagString() .. " len " .. self:getLenString() .. " vdp_id " .. self:getVdp_idString()
end

--- Resolve which header comes after this one (in a packet)
--- For instance: in tcp/udp based on the ports
--- This function must exist and is only used when get/dump is executed on 
--- an unknown (mbuf not yet casted to e.g. tcpv6 packet) packet (mbuf)
--- @return String next header (e.g. 'eth', 'ip4', nil)
function dhHeader:resolveNextHeader()
	return eth
end	

--- Change the default values for namedArguments (for fill/get)
--- This can be used to for instance calculate a length value based on the total packet length
--- See proto/ip4.setDefaultNamedArgs as an example
--- This function must exist and is only used by packet.fill
--- @param pre The prefix used for the namedArgs, e.g. 'dh'
--- @param namedArgs Table of named arguments (see See more)
--- @param nextHeader The header following after this header in a packet
--- @param accumulatedLength The so far accumulated length for previous headers in a packet
--- @return Table of namedArgs
--- @see dhHeader:fill
function dhHeader:setDefaultNamedArgs(pre, namedArgs, nextHeader, accumulatedLength)
	return namedArgs
end


------------------------------------------------------------------------
---- Metatypes
------------------------------------------------------------------------

dh.metatype = dhHeader


return dh

