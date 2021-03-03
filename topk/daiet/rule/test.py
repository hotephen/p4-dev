import fileinput
import os



rule_file = open('commands.txt', 'r+')
dest_file = open('test', 'w+')

# data = rule_file.read()
# dest_file.write(data)

# line = rule_file.readline()
port_mapping = {'A' : 1}
print(str(port_mapping['A']))

dest_file = open('test', 'w+')
for line in rule_file:
    
    line = line.replace("XX", str(port_mapping['A']))
    dest_file.write(line)
dest_file.close()

rule_file.close()










