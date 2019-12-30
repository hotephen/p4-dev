local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local stats	 = require "stats"
local log    = require "log"

function configure(parser)
	parser:argument("rxDev", "The device to receive from"):convert(tonumber)
end

function master(args)
	local rxDev = device.config{port = args.rxDev, dropEnable = false}
	device.waitForLinks()
	mg.startTask("dumpSlave", rxDev:getRxQueue(0))
	mg.waitForTasks()
end


function dumpSlave(queue)
	local bufs = memory.bufArray()
	local pktCtr = stats:newPktRxCounter("Packets counted", "plain")
	local total_latency = 0
	while mg.running() do
		local rx = queue:tryRecv(bufs, 100)
		for i = 1, rx do
			local buf = bufs[i]
			-- buf:dump()
			local pkt = buf:getEthernetPacket()
			print(pkt)
			local srcmac = pkt.eth:getSrcString()
			local dstmac = pkt.eth:getDstString()
			print(srcmac)
			print(dstmac)
			-- s = srcmac.tohex(srcmac)
			-- d = dstmac.tohex(dstmac)
			sb = string.gsub(srcmac,":","")
			db = string.gsub(dstmac,":","")
			print(sb)
			print(db)
			sint = tonumber(sb,16)
			dint = tonumber(db,16)
			latency = dint-sint
			total_latency = total_latency + latency
			if i % 100000 == 0 then
				print(total_latency/i)
			end
			pktCtr:countPacket(buf)
		end
		bufs:free(rx)
		pktCtr:update()
	end
	pktCtr:finalize()
end

function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end
