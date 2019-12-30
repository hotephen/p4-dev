--MoonGen/libmoon/lua/proto/nsh.lua
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
	uint16_t		ver;
	uint16_t		oam;
	uint16_t		un1;
	uint16_t		ttl;
	uint16_t		len;
	uint16_t		un4;
	uint16_t		MDtype;
	uint16_t		Nextpro;
	uint16_t		spi;
	uint16_t		si;
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
	self.ver = hton16(int)
end

--- Retrieve the XYZ.
--- @return XYZ as A bit integer.
function nshHeader:getVer()
	return hton16(self.ver)
end

--- Retrieve the XYZ as string.
--- @return XYZ as string.
function nshHeader:getVerString()
	return self.getVer()
end

function nshHeader:setOam(int)
	int = int or 0
	self.oam = hton16(int)
end

function nshHeader:getOam()
	return hton16(self.oam)
end

function nshHeader:getOamString()
	return self.getOam()
end

function nshHeader:setUn1(int)
	int = int or 0
	self.un1 = hton16(int)
end

function nshHeader:getUn1()
	return hton16(self.un1)
end

function nshHeader:getUn1String()
	return self.getUn1()
end

function nshHeader:setTtl(int)
	int = int or 0
	self.ttl = hton16(int)
end

function nshHeader:getTtl()
	return hton16(self.ttl)
end

function nshHeader:getTtlString()
	return self.getTtl()
end

function nshHeader:setLen(int)
	int = int or 0
	self.len = hton16(int)
end

function nshHeader:getLen()
	return hton16(self.len)
end

function nshHeader:getLenString()
	return self.getLen()
end

function nshHeader:setUn4(int)
	int = int or 0
	self.un4 = hton16(int)
end

function nshHeader:getUn4()
	return hton16(self.un4)
end

function nshHeader:getUn4String()
	return self.getUn4()
end

function nshHeader:setMDtype(int)
	int = int or 0
	self.MDtype = hton16(int)
end

function nshHeader:getMDType()
	return hton16(self.MDtype)
end

function nshHeader:getMDTypeString()
	return self.getMDType()
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
	self.spi = hton16(int)
end

function nshHeader:getSpi()
	return hton16(self.spi)
end

function nshHeader:getSpiString()
	return self.getSpi()
end

function nshHeader:setSi(int)
	int = int or 0
	self.si = hton16(int)
end

function nshHeader:getSi()
	return hton16(self.si)
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
	self:setOam(args[pre .. "Oam"])
	self:setUn1(args[pre .. "Un1"])
	self:setTtl(args[pre .. "Ttl"])
	self:setLen(args[pre .. "Len"])
	self:setUn4(args[pre .. "Un4"])
	self:setMDtype(args[pre .. "MDtype"])
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
	args[pre .. "Oam"] = self:getOam()
	args[pre .. "Un1"] = self:getUn1()
	args[pre .. "Ttl"] = self:getTtl()
	args[pre .. "Len"] = self:getLen()
	args[pre .. "Un4"] = self:getUn4()
	args[pre .. "MDtype"] = self:getMDType()
	args[pre .. "Nextpro"] = self:getNextpro()
	args[pre .. "Spi"] = self:getSpi()
	args[pre .. "Si"] = self:getSi() 

	return args
end

--- Retrieve the values of all members.
--- @return Values in string format.
function nshHeader:getString()
	return "nsh ver " .. self:getVerString() .. " oam " .. self:getOamString() .. " un1 " .. self:getUn1String()
			.. " ttl " .. self:getTtlString() .. " len " .. self:getLenString() .. " un4 " .. self:getUn4String()
			.. " MDtype " .. self:getMDTypeString() .. " Nextpro " .. self:getNextproString() 
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
