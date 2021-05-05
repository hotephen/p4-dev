local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local dh	 = require "proto.dh"
local eth    = require "proto.ethernet"
local arp    = require "proto.arp"
local log    = require "log"

-- set addresses here
local DST_MAC		= nil -- resolved via ARP on GW_IP or DST_IP, can be overriden with a string here
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
end

function master(args)
	txDev = device.config{port = args.txDev, rxQueues = 3, txQueues = 3}
	rxDev = device.config{port = args.rxDev, rxQueues = 3, txQueues = 3}
	device.waitForLinks()
	-- max 1kpps timestamping traffic timestamping
	-- rate will be somewhat off for high-latency links at low rates
	if args.rate > 0 then
		txDev:getTxQueue(0):setRate(args.rate - (args.size + 4) * 8 / 1000)
	end
	mg.startTask("loadSlave", txDev:getTxQueue(0), rxDev, args.size, args.flows)
	mg.startTask("timerSlave", txDev:getTxQueue(1), rxDev:getRxQueue(1), args.size, args.flows)
	arp.startArpTask{
		-- run ARP on both ports
		{ rxQueue = rxDev:getRxQueue(2), txQueue = rxDev:getTxQueue(2), ips = RX_IP },
		-- we need an IP address to do ARP requests on this interface
		{ rxQueue = txDev:getRxQueue(2), txQueue = txDev:getTxQueue(2), ips = ARP_IP }
	}
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

-- 수정해야할 헤더 : dh, ethernet, ip, tcp
function loadSlave(queue, rxDev, size, flows)
	local mempool = memory.createMemPool(function(buf)
		fillDhPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	local counter = 0
	local txCtr = stats:newDevTxCounter(queue, "plain")
	local rxCtr = stats:newDevRxCounter(rxDev, "plain")
	local srcIP = parseIPAddress(SRC_IP_BASE)
	local dstIP = parseIPAddress(DST_IP)
	while mg.running() do
		bufs:alloc(size)
		for i, buf in ipairs(bufs) do
			local pkt = buf:getDhPacket()
			--if i % 3 == 0 then -- l2 fwd
				pkt.dh.flag = 0x5
				pkt.dh.len = 0x3
				pkt.dh.vdp_id = 0x0200 -- 0002
				pkt.eth:setSrc(0x000000000000) -- 0000 0000 0000
				pkt.eth:setDst(0x010000000000) -- 0000 0000 0001
				
			--elseif i % 3 == 1 then -- ipv4 fwd
			--else -- tcp fw
			--end
			pkt.ip4.src:set(srcIP)
			pkt.ip4.dst:set(dstIP)
			buf:dump()
			-- counter = incAndWrap(counter, flows) -- Increment a wrapping counter, i.e. (val + 1) % max
		end
		-- UDP checksums are optional, so using just IPv4 checksums would be sufficient here
		-- bufs:offloadUdpChecksums()
		queue:send(bufs)
		txCtr:update()
		rxCtr:update()
	end
	txCtr:finalize()
	rxCtr:finalize()
end

function timerSlave(txQueue, rxQueue, size, flows)
	if size < 84 then
		log:warn("Packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
		size = 84
	end
	local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
	local hist = hist:new()
	mg.sleepMillis(1000) -- ensure that the load task is running
	local counter = 0
	local rateLimit = timer:new(0.001)
	local srcIP = parseIPAddress(SRC_IP_BASE)
	local dstIP = parseIPAddress(DST_IP)
	while mg.running() do
		hist:update(timestamper:measureLatency(size, function(buf)
			fillDhPacket(buf, size)
			local pkt = buf:getDhPacket()
				pkt.dh.flag = 0x5
				pkt.dh.len = 0x3
			--	pkt.dh.padding = 0x0
				pkt.dh.vdp_id = 0x0200
				pkt.eth:setSrc(0x000000000000) -- little endian
				pkt.eth:setDst(0x010000000000)
			pkt.ip4.src:set(srcIP)
			pkt.ip4.dst:set(dstIP)
			--buf:dump()
			-- counter = incAndWrap(counter, flows)
		end))
		rateLimit:wait()
		rateLimit:reset()
	end
	-- print the latency stats after all the other stuff
	mg.sleepMillis(300)
	hist:print()
	hist:save("histogram.csv")
end
