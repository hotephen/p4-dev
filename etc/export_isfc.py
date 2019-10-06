#!/usr/bin/python

import sys
import os

if len(sys.argv)==1:
    print "Enter the filename you want to convert. Example: python test.py ~/mnc/rule.txt"
    exit(1)

in_f=open(sys.argv[1], 'r')
out_f=open('time_isfc_BA.txt', 'a')

lines = in_f.readlines()
sum_data = 0
max_data = 0
min_data = 999999999
for line in lines:
    item = line.split(" ")
    if "\'delay\'" in line:
        data = int(item[item.index("\'delay\'")+6])
        if max_data < data:
            max_data = data
        if min_data > data: 
            min_data = data
        sum_data = sum_data + data
        out_f.write(str(data)+'\n')

expectation = sum_data/1000     

print "%d" %(expectation)
print "%d" %(max_data)
print "%d" %(min_data)

in_f.close()
out_f.close()