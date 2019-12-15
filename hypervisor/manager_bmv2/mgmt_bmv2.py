import curses
from curses.textpad import Textbox, rectangle
import time
import os

padding = 2
MAX_RESOURCE_NUM = 50
BAR_SIZE = 50
ratio = BAR_SIZE / MAX_RESOURCE_NUM
resourceNum = 0
resourceStatus = {'L2 Forwarding' : [0, 0, 0, 0, 0], 'L3 Forwarding' : [0, 0, 0, 0, 1], 'Firewall' : [0, 0, 0, 0, 2], 'ARP Proxy' : [0, 0, 0, 0, 3]}
pcnt = 0
cfgStatus = [0, 0, 0, 0]
l2fwd = {}
l3fwd = {}
fw = {}
arp = {}

def printResourceBar(screen):
  cfgStatus[0] = cfgStatus[1] = cfgStatus[2] = cfgStatus[3] = 0
  # stageN : 
  screen.addstr(padding + 2, padding + 0, 'CfgStage' + ' : ') # configuration stage
  for i in range(0, 4):
    screen.addstr(padding + 3 + i, padding + 0, 'Stage' + str(i) + '   : ')

  cnt = [0, 0, 0, 0]
  for reqName, resource in resourceStatus.items():
    # instance name
    req_id = -1
    reqPos = -1
    if reqName == 'L2 Forwarding': req_id = 0; reqPos = 0
    elif reqName == 'L3 Forwarding': req_id = 1; reqPos = 15
    elif reqName == 'Firewall': req_id = 2; reqPos = 30 
    elif reqName == 'ARP Proxy': req_id = 3; reqPos = 40 
    else: return
    screen.addstr(padding + 1, padding + reqPos, reqName, curses.color_pair(resource[4] + 1))

    # resource of instance
    for idx, val in enumerate(resource): 
      if idx == 4: break;
      if val != 0: cfgStatus[req_id] = 1
      for i in range(cnt[idx], cnt[idx] + val * ratio):
        screen.addstr(padding + idx + 3, padding + i + 11, '#', curses.color_pair(resource[4] + 1))
      cnt[idx] = cnt[idx] + val * ratio

  # each percent of cfg resource
  cfgcnt = 0
  for i in range(4):
    if cfgStatus[i] != 0:
      for j in range(5):
        screen.addstr(padding + 2, padding + cfgcnt + 11, '#', curses.color_pair(i + 1))
        cfgcnt += 1
  for i in range(cfgcnt, 20):
    screen.addstr(padding + 2, padding + i + 11, '#')
  screen.addstr(padding + 2, padding + BAR_SIZE + 12, '(' + str(int(cfgcnt / 20.0 * 100)) + '%/100%)')

  # each percent of resource 
  for i in range(4):
    for j in range(cnt[i], BAR_SIZE):
      screen.addstr(padding + i + 3, padding + j + 11, '#')
    screen.addstr(padding + 3 + i, padding + BAR_SIZE + 12, '(' + str(cnt[i] * 100 / MAX_RESOURCE_NUM) + '%/100%)')

def translateRules(reqop, vals):
  # import rule template
  # make new p4 ruleset
  # make P4 ruleset file
  global pcnt

  f1 = open('rule_form_bmv2/' + vals[0], 'r')
  f2 = open('tmp', 'w')

  forms = []
  for line in f1:
    forms.append(line)  

  output = ''
  cfg = ''; dstMAC = ''; fwdport = ''; dstIP = ''
  tgtIP = ''; srcIP = ''; dstport = ''; opcode = ''
  # l2fwd [dstMAC] [fwdport] [seq_num]
  if vals[0] == 'l2fwd':
    if reqop == 'insert':
      if 'cfg' not in l2fwd:
        cfg += forms[1]  
        cfg += forms[2]  
        l2fwd['cfg'] = [cfg, pcnt]
        resourceStatus['L2 Forwarding'][pcnt] += 2 
      if 'dstMAC' + vals[1] + '/' + vals[3] not in l2fwd:
        macnum = vals[1].split(':')
        rule = forms[4] % (int(vals[3]), int(macnum[0], 16), int(macnum[1], 16), int(macnum[2], 16), int(macnum[3], 16), int(macnum[4], 16), int(macnum[5], 16))
        dstMAC += rule
        rule = forms[0] % (int(macnum[0], 16), int(macnum[1], 16), int(macnum[2], 16), int(macnum[3], 16), int(macnum[4], 16), int(macnum[5], 16))
        dstMAC += rule
        l2fwd['dstMAC' + vals[1] + '/' + vals[3]] = [dstMAC, pcnt]
        resourceStatus['L2 Forwarding'][pcnt] += 2 
      if 'fwdport' + vals[2] + '/' + vals[3] not in l2fwd:
        rule = forms[3] % (int(vals[3]), int(vals[2]))
        fwdport += rule
        l2fwd['fwdport' + vals[2] + '/' + vals[3]] = [fwdport, pcnt]
        resourceStatus['L2 Forwarding'][pcnt] += 1 
    else: # reqop == 'delete'
      if 'dstMAC' + vals[1] + '/' + vals[3] in l2fwd:
        resourceStatus['L2 Forwarding'][l2fwd['dstMAC' + vals[1] + '/' + vals[3]][1]] -= 1 
        del l2fwd['dstMAC' + vals[1] + '/' + vals[3]]
      if 'fwdport' + vals[2] + '/' + vals[3] in l2fwd:
        resourceStatus['L2 Forwarding'][l2fwd['fwdport' + vals[2] + '/' + vals[3]][1]] -= 1 
        del l2fwd['fwdport' + vals[2] + '/' + vals[3]]
      if len(l2fwd) == 1: # if all of the rules deleted
        resourceStatus['L2 Forwarding'][l2fwd['cfg'][1]] -= 3 
        del l2fwd['cfg']

  # l3fwd [dstIP] [fwdport]
  elif vals[0] == 'l3fwd':
    if 'cfg' not in l3fwd:
      cfg += forms[0]  
      cfg += forms[1]  
      cfg += forms[2]  
      l3fwd['cfg'] = cfg
      resourceStatus['L3 Forwarding'][pcnt] += 3
    if 'dstIP' + vals[1] not in l3fwd: 
      ipnum = vals[1].split('.')
      rule = forms[3] % (int(ipnum[0]), int(ipnum[1]), int(ipnum[2]), int(ipnum[3]))
      dstIP += rule
      l3fwd['dstIP' + vals[1]] = dstIP
      resourceStatus['L3 Forwarding'][pcnt] += 1
    if 'fwdport' + vals[2] not in l3fwd:
      rule = forms[4] % (int(vals[2]))
      fwdport += rule
      l3fwd['fwdport' + vals[2]] = fwdport
      resourceStatus['L3 Forwarding'][pcnt] += 1

  # fw [op] [srcIP] [dstport] [fwdport]
  elif vals[0] == 'fw':
    if vals[1] == 'drop':
      if vals[1] + 'cfg' not in fw:
        cfg += forms[2]
        fw[vals[1] + 'cfg'] = cfg
        resourceStatus['Firewall'][pcnt] += 1
      if vals[2] != 'N' and 'srcIP' + vals[2] not in fw:
	ipnum = vals[2].split('.')
        rule = forms[4] % (int(ipnum[0]), int(ipnum[1]), int(ipnum[2]), int(ipnum[3]))
        srcIP += rule
        fw['srcIP' + vals[2]] = srcIP
        resourceStatus['Firewall'][pcnt] += 1
      if vals[3] != 'N' and 'dstport' + vals[3] not in fw:
        rule = forms[6] % (int(vals[3]))
        dstport += rule
        fw['dstport' + vals[3]] = dstport
        resourceStatus['Firewall'][pcnt] += 1

    elif vals[1] == 'fwd':
      if vals[1] + 'cfg' not in fw:
        cfg += forms[0]
        cfg += forms[1]
        fw[vals[1] + 'cfg'] = cfg
        resourceStatus['Firewall'][pcnt] += 2
      if vals[2] != 'N' and 'srcIP' + vals[2] not in fw:
        ipnum = vals[2].split('.')
        rule = forms[3] % (int(ipnum[0]), int(ipnum[1]), int(ipnum[2]), int(ipnum[3]))
        srcIP += rule
        fw['srcIP' + vals[2]] = srcIP
        resourceStatus['Firewall'][pcnt] += 1
      if vals[3] != 'N' and 'dstport' + vals[3] not in fw:
        rule = forms[5] % (int(vals[3]))
        dstport += rule
        fw['dstport' + vals[3]] = dstport
        resourceStatus['Firewall'][pcnt] += 1
      if vals[4] != 'N' and 'fwdport' + vals[4] not in fw:
        rule = forms[7] % (int(vals[4]))
        fwdport += rule
        fw['fwdport' + vals[4]] = fwdport
        resourceStatus['Firewall'][pcnt] += 1

  # arp [opcode] [tgtIP] [dstMAC]
  elif vals[0] == 'arp':
    if 'cfg' not in arp:
      cfg += forms[1]  
      cfg += forms[2]  
      cfg += forms[3]  
      cfg += forms[4]  
      cfg += forms[6]  
      cfg += forms[8]  
      l3fwd['cfg'] = cfg
      resourceStatus['ARP Proxy'][pcnt] += 6
    if 'op' + vals[1] not in arp:
      rule = forms[0] % int(vals[1])
      opcode += rule
      arp['op' + vals[1]] = opcode
      resourceStatus['ARP Proxy'][pcnt] += 1
    if 'ip' + vals[2] + 'mac' + vals[3] not in arp:
      # tgtIP
      ipnum = vals[2].split('.')
      rule = forms[7] % (int(ipnum[0]), int(ipnum[1]), int(ipnum[2]), int(ipnum[3]))
      tgtIP += rule
      # dstMAC
      macnum = vals[3].split(':')
      rule = forms[5] % (int(macnum[0], 16), int(macnum[1], 16), int(macnum[2], 16), int(macnum[3], 16), int(macnum[4], 16), int(macnum[5], 16))
      dstMAC += rule
      arp['ip' + vals[2] + 'mac' + vals[3]] = tgtIP + dstMAC
      resourceStatus['ARP Proxy'][pcnt] += 2

  ruleset = cfg + opcode + dstMAC + srcIP + tgtIP + dstIP + fwdport + dstport
  f2.write(ruleset)

  if reqop == 'insert' and ruleset != '': pcnt = (pcnt + 1) % 4

  f2.close()
  f1.close()
  return

def populateRulesetToDP():
  # rule population command (P4Runtime)
  os.system('sudo /home/ubuntu4/p4/behavioral-model/tools/runtime_CLI.py --thrift-port 9090 < tmp')
  pass
 
def main(screen):
  while True:
    screen.clear()

    # command help
    screen.addstr(padding + 14, padding + 0, '* Commands')
    screen.addstr(padding + 15, padding + 0, 'Ctrl-G or Enter : send request / Ctrl-C : exit')

    # current resource usage
    screen.addstr(padding + 0, padding + 0, '* Current resource usage of P4 Hypervisor')
    printResourceBar(screen)

    # input request
    screen.addstr(padding + 9, padding + 0, '* Enter the request ')
    edit_win = curses.newwin(1, BAR_SIZE, 11 + padding, 1 + padding)
    rectangle(screen, padding + 10, padding + 0, padding + 1 + 10 + 1, padding + 1 + BAR_SIZE + 1)
    screen.refresh()
    box = Textbox(edit_win)
    box.edit()
    input_text = box.gather()

    if input_text != '':
      vals = input_text.split()
      reqop = vals[0]; del vals[0]
      translateRules(reqop, vals)
      populateRulesetToDP() # if translation succeed


# init
curses.initscr()

curses.start_color()
curses.init_pair(1, curses.COLOR_WHITE, curses.COLOR_BLUE)
curses.init_pair(2, curses.COLOR_WHITE, curses.COLOR_YELLOW)
curses.init_pair(3, curses.COLOR_WHITE, curses.COLOR_GREEN)
curses.init_pair(4, curses.COLOR_WHITE, curses.COLOR_MAGENTA)
curses.init_pair(5, curses.COLOR_WHITE, curses.COLOR_CYAN)

curses.wrapper(main)
