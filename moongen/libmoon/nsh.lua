------------------------------------------------------------------------
--- @file nsh.lua
--- @brief (nsh) utility.
--- Utility functions for the nsh_header structs 
--- Includes:
--- - nsh constants
--- - nsh header utility
--- - Definition of nsh packets
------------------------------------------------------------------------

--[[
-- Use this file as template when implementing a new protocol (to implement all mandatory stuff)
-- Replace all occurrences of nsh with your protocol (e.g. sctp)
-- Remove unnecessary comments in this file (comments inbetween [[...]]
-- Necessary changes to other files:
-- - packet.lua: if the header has a length member, adapt packetSetLength; 
-- 				 if the packet has a checksum, adapt createStack (loop at end of function) and packetCalculateChecksums
-- - proto/proto.lua: add nsh.lua to the list so it gets loaded
--]]
local ffi = require "ffi"
require "proto.template"
local initHeader = initHeader

local ntoh, hton = ntoh, hton
local ntoh16, hton16 = ntoh16, hton16
local bor, band, bnot, rshift, lshift= bit.bor, bit.band, bit.bnot, bit.rshift, bit.lshift
local istype = ffi.istype
local format = string.format


---------------------------------------------------------------------------
---- nsh constants 
---------------------------------------------------------------------------

--- nsh protocol constants
local nsh = {}


---------------------------------------------------------------------------
---- nsh header
---------------------------------------------------------------------------

nsh.headerFormat = [[
	uint8_t			ver_oam_un1_ttl4;
	uint8_t			ttl2_len;
	uint8_t			un4_MDtype;
	uint16_t		Nextpro;
	uint8_t			spi[3];
	uint8_t			si;
]]

--- Variable sized member
nsh.headerVariableMember = nil

--- Module for nsh_address struct
local nshHeader = initHeader()
nshHeader.__index = nshHeader

--[[ for all members of the header with non-standard data type: set, get, getString 
-- for set also specify a suitable default value
--]]
--- Set the XYZ.
--- @param int XYZ of the nsh header as A bit integer.
function nshHeader:setVer(int)
	int = int or 0
	self.ver_oam_un1_ttl4 = hton(int)
end

--- Retrieve the XYZ.
--- @return XYZ as A bit integer.
function nshHeader:getVer()
	return hton(self.ver_oam_un1_ttl4)
end

--- Retrieve the XYZ as string.
--- @return XYZ as string.
function nshHeader:getVerString()
	return self.getVer()
end

function nshHeader:setTtl(int)
	int = int or 0
	self.ttl2_len = hton(int)
end

function nshHeader:getTtl()
	return hton(self.ttl2_len)
end

function nshHeader:getTtlString()
	return self.getTtl()
end

function nshHeader:setUn4(int)
	int = int or 0
	self.un4_MDtype = hton(int)
end

function nshHeader:getUn4()
	return hton(self.un4_MDtype)
end

function nshHeader:getUn4String()
	return self.getUn4()
end

function nshHeader:setNextpro(int)
	int = int or 0
	self.Nextpro = hton16(int)
end

function nshHeader:getNextpro()
	return hton16(self.Nextpro)
end

function nshHeader:getNextproString()
	return self.getNextpro()
end

function nshHeader:setSpi(int)
	int = int or 0
	self.spi[0] = rshift(band(int, 0xFF0000), 16)
	self.spi[1] = rshift(band(int, 0x00FF00), 8)
	self.spi[2] = band(int, 0x0000FF)
end

function nshHeader:getSpi()
	return bor(lshift(self.spi[0], 16), bor(lshift(self.spi[1], 8), self.spi[2]))
end

function nshHeader:getSpiString()
	return self.getSpi()
end

function nshHeader:setSi(int)
	int = int or 0
	self.si = hton(int)
end

function nshHeader:getSi()
	return hton(self.si)
end

function nshHeader:getSiString()
	return self.getSi()
end

--- Set all members of the nsh header.
--- Per default, all members are set to default values specified in the respective set function.
--- Optional named arguments can be used to set a member to a user-provided value.
--- @param args Table of named arguments. Available arguments: nshXYZ
--- @param pre prefix for namedArgs. Default 'nsh'.
--- @code
--- fill() -- only default values
--- fill{ nshXYZ=1 } -- all members are set to default values with the exception of nshXYZ, ...
--- @endcode
function nshHeader:fill(args, pre)
	args = args or {}
	pre = pre or "nsh"

	self:setVer(args[pre .. "Ver"])
	self:setTtl(args[pre .. "Ttl"])
	self:setUn4(args[pre .. "Un4"])
	self:setNextpro(args[pre .. "Nextpro"])
	self:setSpi(args[pre .. "Spi"])
	self:setSi(args[pre .. "Si"])
end

--- Retrieve the values of all members.
--- @param pre prefix for namedArgs. Default 'nsh'.
--- @return Table of named arguments. For a list of arguments see "See also".
--- @see nshHeader:fill
function nshHeader:get(pre)
	pre = pre or "nsh"

	local args = {}
	args[pre .. "Ver"] = self:getVer()
	args[pre .. "Ttl"] = self:getTtl()
	args[pre .. "Un4"] = self:getUn4()
	args[pre .. "Nextpro"] = self:getNextpro()
	args[pre .. "Spi"] = self:getSpi()
	args[pre .. "Si"] = self:getSi() 

	return args
end

--- Retrieve the values of all members.
--- @return Values in string format.
function nshHeader:getString()
	return "nsh ver " .. self:getVerString() .. " ttl " .. self:getTtlString() .. " un4 " .. self:getUn4String()
			.. " Nextpro " .. self:getNextproString() 
			.. " spi " .. self:getSpi() .. " si " .. self:getSi()
end

--- Resolve which header comes after this one (in a packet)
--- For instance: in tcp/udp based on the ports
--- This function must exist and is only used when get/dump is executed on 
--- an unknown (mbuf not yet casted to e.g. tcpv6 packet) packet (mbuf)
--- @return String next header (e.g. 'eth', 'ip4', nil)
function nshHeader:resolveNextHeader()
	return eth
end	

--- Change the default values for namedArguments (for fill/get)
--- This can be used to for instance calculate a length value based on the total packet length
--- See proto/ip4.setDefaultNamedArgs as an example
--- This function must exist and is only used by packet.fill
--- @param pre The prefix used for the namedArgs, e.g. 'nsh'
--- @param namedArgs Table of named arguments (see See more)
--- @param nextHeader The header following after this header in a packet
--- @param accumulatedLength The so far accumulated length for previous headers in a packet
--- @return Table of namedArgs
--- @see nshHeader:fill
function nshHeader:setDefaultNamedArgs(pre, namedArgs, nextHeader, accumulatedLength)
	return namedArgs
end


------------------------------------------------------------------------
---- Metatypes
------------------------------------------------------------------------

nsh.metatype = nshHeader


return nsh
