local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local histogram   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local arp    = require "proto.arp"
local nsh    = require "proto.nsh"
local log    = require "log"
local eth    = require "proto.ethernet"
local tcp    = require "proto.tcp"

-- set addresses here
--local DST_MAC		= "00:00:00:00:00:02"
local SRC_IP		= "10.10.0.1" -- actual address will be SRC_IP_BASE + random(0, flows)
local DST_IP		= "10.10.0.2"
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
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(1000):convert(tonumber)
	parser:option("-f --flows", "Number of flows (randomized source IP)."):default(4):convert(tonumber)
	parser:option("-s --size", "Packet size."):default(90):convert(tonumber)
	parser:option("-spi --spi", "SPI."):default(1):convert(tonumber)
	parser:option("-l --latency_dump", "Latency Dump."):default(0):convert(tonumber)
	parser:option("-txdump --txdump", "Tx Dump."):default(0):convert(tonumber)
	parser:option("-rxdump --rxdump", "Rx Dump."):default(0):convert(tonumber)
	parser:option("-f --filename", "File name to save latency.")
end

function master(args)
	txDev = device.config{port = args.txDev, rxQueues = 3, txQueues = 3}
	rxDev = device.config{port = args.rxDev, dropEnable = false}
	device.waitForLinks()
	if args.rate > 0 then
		txDev:getTxQueue(0):setRate(args.rate - (args.size + 4) * 8 / 1000)
	end
	mg.startTask("loadSlave", txDev:getTxQueue(0), rxDev, args.size, args.flows, args.spi, args.txdump, args.number)
	mg.startTask("dumpSlave", rxDev:getRxQueue(0), args.rxdump, args.latency_dump, args.filename)
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

local function timerTask(txq, rxq, size)
	local timestamper = ts:newTimestamper(txq, rxq)
	local hist = histogram:nev()
	local rateLimiter = timer:new(0.01)
	while mg.running() do
		rateLimiter:reset()
		hist:update(timetsamper:measureLatency(size))
		rateLimiter:busyWait()
	end
	hist:print()
	hist:save("timestamp.csv")
end


function loadSlave(queue, rxDev, size, flows, spi, txdump, number)
	-- doArp()
	local mempool = memory.createMemPool(function(buf)
		fillNshPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	local count = 0
	local txCtr = stats:newDevTxCounter(queue, "plain")
	local rxCtr = stats:newDevRxCounter(rxDev, "plain")
	local srcIP = parseIPAddress(SRC_IP)
	local dstIP = parseIPAddress(DST_IP)

	local timer = timer:new(10)

	while mg.running() do
		if timer:expired() then
			break;
		end	
	--while count <= threshold do
		bufs:alloc(size)
		-- print(count) 
		for i, buf in ipairs(bufs) do
			local pkt = buf:getNshPacket()
				pkt.eth.dst:set(0x020000000000) --"00:00:00:00:00:02"
				pkt.eth.src:set(0x010000000000) --"00:00:00:00:00:01"
				pkt.eth.type = 0x4f89
				pkt.nsh.spi[0] = 0x00 -- 00 00 01
				pkt.nsh.spi[1] = 0x00
				pkt.nsh.spi[2] = spi
				pkt.nsh.Nextpro = 0x5865
				pkt.nsh.si = 0xff
				pkt.innerEth.type = 0x0008
				pkt.ip4.src:set(srcIP)
				pkt.ip4.dst:set(dstIP)
				pkt.ip4.protocol = 0x06
				pkt.tcp:setSrc(20)
				pkt.tcp:setDst(80)
				queue:send(bufs)
			count = count + 1
			if count % 10000 == 0 then
				if txdump == 1 then
					buf:dump()
				end
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

function dumpSlave(rxQueue, rxdump, latency_dump, filename)
	local bufs = memory.bufArray()
	local pktCtr = stats:newPktRxCounter("Packets counted", "plain")
	local total_latency = 0
	local count = 0
	local count_rx = 0
	
	if filename then
		local file = io.open(filename .. ".csv","w+")
	end

	while mg.running() do
		local rx = rxQueue:tryRecv(bufs, 100)
		for i = 1, rx do
			local buf = bufs[i]
			pktCtr:countPacket(buf)

			local pkt = buf:getNshPacket()
			local srcmac = pkt.innerEth:getSrcString()
			local dstmac = pkt.innerEth:getDstString()
			src_pure = string.gsub(srcmac,":","") --src_pure = 1234567890AB
			dst_pure = string.gsub(dstmac,":","")
			sb = string.sub(src_pure,5) --sb = 67890AB
			db = string.sub(dst_pure,5)
			sint = tonumber(sb,16) -- 16->10진수로 변환
			dint = tonumber(db,16)
			latency = dint-sint
			total_latency = total_latency + latency
			count = count + 1
			
			if latency_dump == 1 then
				if count % 10000 == 0 then
					--print(total_latency/count)
					if filename then
						file:write(total_latency/count)
						file:write("\n")
					end

					count = 0
					total_latency = 0
				end
			end
			if rxdump == 1 then
				buf:dump()
				
			end
		end
		
		bufs:free(rx)
		pktCtr:update()
	end
	
	if filename then
		file:close()
	end

	pktCtr:finalize()
end