import curses
from curses.textpad import Textbox, rectangle
import time
import os

padding = 3
MAX_RESOURCE_NUM = 50
BAR_SIZE = 100 
ratio = BAR_SIZE / MAX_RESOURCE_NUM
resourceNum = 0
resourceStatus = {'L2 Forwarding' : [0, 0, 0, 0, 0], 'L3 Forwarding' : [0, 0, 0, 0, 1], 'Firewall' : [0, 0, 0, 0, 2], 'ARP Proxy' : [0, 0, 0, 0, 3]}

def printResourceBar(screen):
  # stageN : 
  for i in range(0, 4):
    screen.addstr(padding + 3 + i, padding + 0, 'Stage' + str(i) + ' : ')

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
      for i in range(cnt[idx], cnt[idx] + val * ratio):
        screen.addstr(padding + idx + 3, padding + i + 9, '#', curses.color_pair(resource[4] + 1))
      cnt[idx] = cnt[idx] + val * ratio

  # each percent of resource 
  for i in range(4):
    for j in range(cnt[i], BAR_SIZE):
      screen.addstr(padding + i + 3, padding + j + 9, '#')
    screen.addstr(padding + 3 + i, padding + BAR_SIZE + 10, '(' + str(cnt[i]) + '%/100%)')

l2fwd = {}
l3fwd = {}
fw = {}
def translateRules(input_text):
  # import rule template
  # make new p4 ruleset
  # make P4 ruleset file
  vals = input_text.split()

  f1 = open('rule_form/' + vals[0], 'r')
  f2 = open('tmp', 'w')

  forms = []
  for line in f1:
    forms.append(line)  

  output = ''
  cfg = ''; dstMAC = ''; fwdport = ''; dstIP = ''
  srcIP = ''; dstport = ''
  # l2fwd [dstMAC] [fwdport]
  if vals[0] == 'l2fwd':
    if 'cfg' not in l2fwd:
      cfg += forms[0]  
      cfg += forms[1]  
      cfg += forms[2]  
      l2fwd['cfg'] = cfg
      resourceStatus['L2 Forwarding'][0] += 3 
    if 'dstMAC' + vals[1] not in l2fwd:
      macnum = vals[1].split(':')
      rule = forms[4] % (int(macnum[0], 16), int(macnum[1], 16), int(macnum[2], 16), int(macnum[3], 16), int(macnum[4], 16), int(macnum[5], 16))
      dstMAC += rule
      l2fwd['dstMAC' + vals[1]] = dstMAC
      resourceStatus['L2 Forwarding'][0] += 1 
    if 'fwdport' + vals[2] not in l2fwd:
      rule = forms[3] % (int(vals[2]))
      fwdport += rule
      l2fwd['fwdport' + vals[2]] = fwdport
      resourceStatus['L2 Forwarding'][0] += 1 

  # l3fwd [dstIP] [fwdport]
  elif vals[0] == 'l3fwd':
    if 'cfg' not in l3fwd:
      cfg += forms[0]  
      cfg += forms[1]  
      cfg += forms[2]  
      l3fwd['cfg'] = cfg
      resourceStatus['L3 Forwarding'][1] += 3
    if 'dstIP' not in l3fwd:
      ipnum = vals[1].split('.')
      rule = forms[3] % (int(ipnum[0]), int(ipnum[1]), int(ipnum[2]), int(ipnum[3]))
      dstIP += rule
      l3fwd['dstIP' + vals[1]] = dstIP
      resourceStatus['L3 Forwarding'][1] += 1
    if 'fwdport' not in l3fwd:
      rule = forms[4] % (int(vals[2]))
      fwdport += rule
      l3fwd['fwdport' + vals[2]] = fwdport
      resourceStatus['L3 Forwarding'][1] += 1

  # fw [op] [srcIP] [dstport] [fwdport]
  elif vals[0] == 'fw':
    if vals[1] == 'drop':
      if vals[1] + 'cfg' not in fw:
        cfg += forms[2]
        fw[vals[1] + 'cfg'] = cfg
        resourceStatus['Firewall'][2] += 1
      if vals[2] != 'N' and 'srcIP' + vals[2] not in fw:
	ipnum = vals[2].split('.')
        rule = forms[4] % (int(ipnum[0]), int(ipnum[1]), int(ipnum[2]), int(ipnum[3]))
        srcIP += rule
        fw['srcIP' + vals[2]] = srcIP
        resourceStatus['Firewall'][2] += 1
      if vals[3] != 'N' and 'dstport' + vals[3] not in fw:
        rule = forms[6] % (int(vals[3]))
        dstport += rule
        fw['dstport' + vals[3]] = dstport
        resourceStatus['Firewall'][2] += 1

    elif vals[1] == 'fwd':
      if vals[1] + 'cfg' not in fw:
        cfg += forms[0]
        cfg += forms[1]
        fw[vals[1] + 'cfg'] = cfg
        resourceStatus['Firewall'][2] += 2
      if vals[2] != 'N' and 'srcIP' + vals[2] not in fw:
        ipnum = vals[2].split('.')
        rule = forms[3] % (int(ipnum[0]), int(ipnum[1]), int(ipnum[2]), int(ipnum[3]))
        srcIP += rule
        fw['srcIP' + vals[2]] = srcIP
        resourceStatus['Firewall'][2] += 1
      if vals[3] != 'N' and 'dstport' + vals[3] not in fw:
        rule = forms[5] % (int(vals[3]))
        dstport += rule
        fw['dstport' + vals[3]] = dstport
        resourceStatus['Firewall'][2] += 1
      if vals[4] != 'N' and 'fwdport' + vals[4] not in fw:
        rule = forms[7] % (int(vals[4]))
        fwdport += rule
        fw['fwdport' + vals[4]] = fwdport
        resourceStatus['Firewall'][2] += 1

  f2.write(cfg + srcIP + dstMAC + dstIP + fwdport + dstport)

  f2.close()
  f1.close()
  return

def populateRulesetToDP():
  # rule population command (P4Runtime)
  # $SDE/run_bfshell.sh -f tmp
  os.system('$SDE/run_bfshell.sh -f tmp')
 
def main(screen):
  while True:
    screen.clear()

    # command help
    screen.addstr(padding + 14, padding + 0, '* Commands')
    screen.addstr(padding + 15, padding + 0, 'Ctrl-G or Enter : send request / Ctrl-C : exit')

    # current resource usage
    screen.addstr(padding + 0, padding + 0, '* Current Usage of Entries')
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
      translateRules(input_text)
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
