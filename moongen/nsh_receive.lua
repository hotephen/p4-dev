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
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
	parser:option("-f --flows", "Number of flows (randomized source IP)."):default(4):convert(tonumber)
	parser:option("-s --size", "Packet size."):default(90):convert(tonumber)
	parser:option("-spi --spi", "SPI."):default(1):convert(tonumber)
	parser:option("-l --latency_dump", "Latency Dump."):default(0):convert(tonumber)
	parser:option("-txdump --txdump", "Tx Dump."):default(0):convert(tonumber)
	parser:option("-rxdump --rxdump", "Rx Dump."):default(0):convert(tonumber)
	parser:option("-f --filename", "File name to save latency.")
end

function master(args)
	rxDev = device.config{port = args.rxDev, dropEnable = false}
	device.waitForLinks()
	mg.startTask("loadSlave", rxDev)
	mg.startTask("dumpSlave", rxDev:getRxQueue(0), args.latency_dump, args.rxdump, args.filename) 
	mg.waitForTasks()
end

function loadSlave(rxDev)
	-- doArp()
	local rxCtr = stats:newDevRxCounter(rxDev, "plain")
	while mg.running() do
		rxCtr:update()
	end
	rxCtr:finalize()
end

function dumpSlave(rxQueue, latency_dump, rxdump, filename) 
	local bufs = memory.bufArray()
	local pktCtr = stats:newPktRxCounter("Packets counted", "plain")
	local total_latency = 0
	local count = 0
	local count_rx = 0

	local file = io.open(filename .. ".csv","w+")

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
					file:write(total_latency/count)
					file:write("\n")

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

	file:close()

	pktCtr:finalize()
end