--dh --receive --txdump --rxdump
local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local arp    = require "proto.arp"
local dh	 = require "proto.dh"
local nsh    = require "proto.nsh"
local log    = require "log"
local eth    = require "proto.ethernet"
local tcp    = require "proto.tcp"
-- set addresses here
--local DST_MAC		= "00:00:00:00:00:02"
local SRC_IP_BASE	= "10.0.0.1" -- actual address will be SRC_IP_BASE + random(0, flows)
local DST_IP		= "10.0.2.1"
local SRC_PORT		= 1234
local DST_PORT		= 80

-- answer ARP requests for this IP on the rx port
-- change this if benchmarking something like a NAT device
local RX_IP		= DST_IP
-- used to resolve DST_MAC
local GW_IP		= DST_IP
-- used as source IP to resolve GW_IP to DST_MAC
local ARP_IP	= SRC_IP_BASE

function configure(parser)
	parser:description("Generates UDP traffic and measure latencies. Edit the source to modify constants like IPs.")
	parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
	parser:option("-f --flows", "Number of flows (randomized source IP)."):default(4):convert(tonumber)
	parser:option("-s --size", "Packet size."):default(60):convert(tonumber)
	parser:option("-d --dh", "DH."):default(1):convert(tonumber)
	parser:option("-receive --receive", "Receive."):default(1):convert(tonumber)
	parser:option("-txdump --txdump", "Tx Dump."):default(0):convert(tonumber)
	parser:option("-rxdump --rxdump", "Rx Dump."):default(0):convert(tonumber)
end

function master(args)
	txDev = device.config{port = args.txDev, rxQueues = 3, txQueues = 3}
	rxDev = device.config{port = args.rxDev, dropEnable = false}
	device.waitForLinks()
	-- max 1kpps timestamping traffic timestamping
	-- rate will be somewhat off for high-latency links at low rates
	if args.rate > 0 then
		txDev:getTxQueue(0):setRate(args.rate - (args.size + 4) * 8 / 1000)
	end
	mg.startTask("loadSlave", txDev:getTxQueue(0), rxDev, args.size, args.flows, args.dh, args.txdump)
	if args.receive == 1 then
		mg.startTask("dumpSlave", rxDev:getRxQueue(0), args.rxdump)
	end
--	arp.startArpTask{
		-- run ARP on both ports
--		{ rxQueue = rxDev:getRxQueue(2), txQueue = rxDev:getTxQueue(2), ips = RX_IP },
		-- we need an IP address to do ARP requests on this interface
--		{ rxQueue = txDev:getRxQueue(2), txQueue = txDev:getTxQueue(2), ips = ARP_IP }
--	}
	mg.waitForTasks()
end

local function fillDhPacket(buf, len)
	buf:getDhPacket():fill{
		len = 0,
		vdp_id = 0
	}
end

local function fillUdpPacket(buf, len)
	buf:getUdpPacket():fill{
		ethSrc = queue,
		ethDst = DST_MAC,
		ip4Src = SRC_IP,
		ip4Dst = DST_IP,
		udpSrc = SRC_PORT,
		udpDst = DST_PORT,
		pktLength = len
	}
end

function loadSlave(queue, rxDev, size, flows, dh, txdump)
	-- doArp()
	local mempool = memory.createMemPool(function(buf)
		fillDhPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	local count = 0
	local txCtr = stats:newDevTxCounter(queue, "plain")
	local rxCtr = stats:newDevRxCounter(rxDev, "plain")
	local srcIP = parseIPAddress("10.0.0.1")
	local dstIPl3fwd = parseIPAddress("10.0.2.1")
	local dstIPfw = parseIPAddress("10.0.3.1")
	-- local dstIP = parseIPAddress(DST_IP)
	while mg.running() do
		bufs:alloc(size)
		for i, buf in ipairs(bufs) do
			local pkt = buf:getDhPacket()
			pkt.dh.flag = 0x5
			pkt.dh.len = 0x3
			if dh == 1 then
				pkt.eth.dst:set(0x020000000000) --"00:00:00:00:00:02"
				pkt.eth.src:set(0x000000000000) --"00:00:00:00:00:00"
				pkt.dh.vdp_id = 0x0100 -- 0001
				queue:send(bufs)
			elseif dh == 2 then
				pkt.eth.dst:set(0x020000000000) --"00:00:00:00:00:02"
				pkt.eth.src:set(0x000000000000) --"00:00:00:00:00:00"
				pkt.ip4.src:set(srcIP)
				pkt.ip4.dst:set(dstIPl3fwd)
				pkt.dh.vdp_id = 0x0200 -- 0002
				queue:send(bufs)
			elseif dh == 3 then
				pkt.eth.dst:set(0x020000000000) --"00:00:00:00:00:02"
				pkt.eth.src:set(0x000000000000) --"00:00:00:00:00:00"
				pkt.dh.vdp_id = 0x0300 -- 0003
				pkt.ip4.src:set(srcIP)
				pkt.ip4.dst:set(dstIPfw)
				pkt.tcp:setSrc(1234)
				pkt.tcp:setDst(80)
				queue:send(bufs)
			end
		
			count = count + 1
			if count % 10000 == 0 then
				if txdump == 1 then
					buf:dump()
				end
				count = 0
			end
		end
		-- UDP checksums are optional, so using just IPv4 checksums would be sufficient here
		--queue:send(bufs)
		txCtr:update()
		rxCtr:update()
	end
	txCtr:finalize()
	rxCtr:finalize()
end

function dumpSlave(rxQueue, rxdump)
	local bufs = memory.bufArray()
	local pktCtr = stats:newPktRxCounter("Packets counted", "plain")
	local total_latency = 0
	local count = 0
	while mg.running() do
		local rx = rxQueue:tryRecv(bufs, 100)
		for i = 1, rx do
			local buf = bufs[i]
			local pkt = buf:getDhPacket()
			local srcmac = pkt.eth:getSrcString()
			local dstmac = pkt.eth:getDstString()
			src_pure = string.gsub(srcmac,":","") --src_pure = 1234567890AB
			dst_pure = string.gsub(dstmac,":","")
			sb = string.sub(src_pure,5) --sb = 67890AB
			db = string.sub(dst_pure,5)
			sint = tonumber(sb,16) -- 16->10진수로 변환
			dint = tonumber(db,16)
			latency = dint-sint
			total_latency = total_latency + latency
			count = count + 1
			pktCtr:countPacket(buf)
		end
		if rxdump == 1 then
			if count % 10000 == 0 then
				print(total_latency/count)
				count = 0
				total_latency = 0
			end
		end
		
		bufs:free(rx)
		pktCtr:update()
	end
	pktCtr:finalize()
end


--[[ function timerSlave(txQueue, rxQueue, size, flows)
	-- doArp()
	if size < 84 then
		log:warn("Packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
		size = 84
	end
	local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
	local hist = hist:new()
	mg.sleepMillis(1000) -- ensure that the load task is running
	local counter = 0
	local rateLimit = timer:new(0.001)
	while mg.running() do
		hist:update(timestamper:measureLatency(size, function(buf)
			fillNshPacket(buf, size)
            -- local pkt = buf:getUdpPacket()
--		local pkt = buf:getNshPacket()
--		buf:dump()
		--	counter = incAndWrap(counter, flows)
		end))
		rateLimit:wait()
		rateLimit:reset()
	end
	-- print the latency stats after all the other stuff


end ]]


