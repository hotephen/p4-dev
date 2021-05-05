#!/usr/bin/python


import fileinput
import os

rule_file = open('./rule_file.txt', 'r+')
data = rule_file.read()

port_mapping = {}
port_mapping['edge1'] = 1
port_mapping['edge2'] = 1
port_mapping['edge3'] = 1
port_mapping['edge4'] = 1
port_mapping['edge5'] = 2
port_mapping['edge6'] = 2
port_mapping['edge7'] = 1
port_mapping['edge8'] = 4

port_mapping['aggr1'] = 1
port_mapping['aggr2'] = 0
port_mapping['aggr3'] = 2
port_mapping['aggr4'] = 0
port_mapping['aggr5'] = 0
port_mapping['aggr6'] = 2
port_mapping['aggr7'] = 4
port_mapping['aggr8'] = 4

port_mapping['core1'] = 4
port_mapping['core2'] = 4
port_mapping['core3'] = 0
port_mapping['core4'] = 4

set_ip = {}
set_ip['edge1'] = '10.0.1.1'
set_ip['edge2'] = '10.0.1.2'
set_ip['edge3'] = '10.0.1.3'
set_ip['edge4'] = '10.0.1.4'
set_ip['edge5'] = '10.0.1.5'
set_ip['edge6'] = '10.0.1.6'
set_ip['edge7'] = '10.0.1.7'
set_ip['edge8'] = '10.0.1.8'

set_ip['aggr1'] = '10.0.2.1'
set_ip['aggr2'] = '10.0.2.2'
set_ip['aggr3'] = '10.0.2.3'
set_ip['aggr4'] = '10.0.2.4'
set_ip['aggr5'] = '10.0.2.5'
set_ip['aggr6'] = '10.0.2.6'
set_ip['aggr7'] = '10.0.2.7'
set_ip['aggr8'] = '10.0.2.8'

set_ip['core1'] = '10.0.3.1'
set_ip['core2'] = '10.0.3.2'
set_ip['core3'] = '10.0.3.3'
set_ip['core4'] = '10.0.3.4'

print(str(port_mapping['edge%s' %str(1)])) 

for i in range(8):
    i=i+1
    
    rule_file = open('./rule_file.txt', 'r+')
    dest_file = open('edge/edge%s' %str(i), 'w+')

    for line in rule_file:
        line = line.replace("XX", str(port_mapping['edge%s' %str(i)])) 
        line = line.replace("YY", set_ip['edge%s' %str(i)]) 
        print(set_ip['edge%s' %str(i)])
        dest_file.write(line)
    dest_file.close()

for i in range(8):
    i=i+1

    rule_file = open('./rule_file.txt', 'r+')
    dest_file = open('aggr/aggr%s' %str(i), 'w+')

    for line in rule_file:
        line = line.replace("XX", str(port_mapping['aggr%s' %str(i)])) 
        line = line.replace("YY", set_ip['aggr%s' %str(i)]) 
        dest_file.write(line)
    dest_file.close()

for i in range(4):
    i=i+1

    rule_file = open('./rule_file.txt', 'r+')
    dest_file = open('core/core%s' %str(i), 'w+')
    
    for line in rule_file:
        line = line.replace("XX", str(port_mapping['core%s' %str(i)])) 
        line = line.replace("YY", set_ip['core%s' %str(i)]) 
        dest_file.write(line)
    dest_file.close()

rule_file.close()