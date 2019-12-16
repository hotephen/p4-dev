local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local arp    = require "proto.arp"
local nsh    = require "proto.nsh"
local log    = require "log"
local eth    = require "proto.ethernet"
local tcp    = require "proto.tcp"
-- set addresses here
local DST_MAC		= nil -- resolved via ARP on GW_IP or DST_IP, can be overriden with a string here
local SRC_IP		= "10.10.1.1" -- actual address will be SRC_IP_BASE + random(0, flows)
local DST_IP		= "10.10.1.2"
local SRC_PORT		= 1234
local DST_PORT		= 80
local SPI		= 1
local SI 		= 255
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
	parser:option("-s --size", "Packet size."):default(90):convert(tonumber)
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
--	arp.startArpTask{
		-- run ARP on both ports
--		{ rxQueue = rxDev:getRxQueue(2), txQueue = rxDev:getTxQueue(2), ips = RX_IP },
		-- we need an IP address to do ARP requests on this interface
--		{ rxQueue = txDev:getRxQueue(2), txQueue = txDev:getTxQueue(2), ips = ARP_IP }
--	}
	mg.waitForTasks()
end

local function fillNshPacket(buf, len)
    buf:getNshPacket():fill{
        ver = 0,
        oam = 0,
        un1 = 0,
        ttl = 0,
        len = 0,
        un4 = 0,
        MDtype = 0,
        Nextpro = 0,
        spi = 0,
        si = 0
    }
end

local function fillTcpPacket(buf, len)
    buf:getTcpPacket():fill{
	src = 0,
	dst = 0,
	seq = 1,
	ack = 1,
	offset = 0,
	flags = 0,
	window = 0,
	cs = 0,
	urg = 0,
	options = 0

    }
end


function loadSlave(queue, rxDev, size, flows)
	-- doArp()
	local mempool = memory.createMemPool(function(buf)
		fillNshPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	local counter = 0
	local txCtr = stats:newDevTxCounter(queue, "plain")
	local rxCtr = stats:newDevRxCounter(rxDev, "plain")
	local srcIP = parseIPAddress(SRC_IP)
	local dstIP = parseIPAddress(DST_IP)
	while mg.running() do
		bufs:alloc(size)
		for i, buf in ipairs(bufs) do
			local pkt = buf:getNshPacket()
				pkt.eth.type = 0x4f89
				pkt.nsh.spi[0] = 0x00 -- 00 00 01
				pkt.nsh.spi[1] = 0x00
				pkt.nsh.spi[2] = 0x01
				pkt.nsh.Nextpro = 0x5865
				pkt.nsh.si = 0xff
				pkt.innerEth.type = 0x0008
				pkt.ip4.src:set(srcIP)
				pkt.ip4.dst:set(dstIP)
				pkt.ip4.protocol = 0x06
				pkt.tcp:setSrc(20)
				pkt.tcp:setDst(80)
				queue:send(bufs)
		end
		-- UDP checksums are optional, so using just IPv4 checksums would be sufficient here
		--queue:send(bufs)
		txCtr:update()
		rxCtr:update()
	end
	txCtr:finalize()
	rxCtr:finalize()
end

function timerSlave(txQueue, rxQueue, size, flows)
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


end


