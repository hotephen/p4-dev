import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np


data = []
data.append(155) #1
data.append(166) #2
data.append(175) #3
data.append(193) #4
data.append(209) #5
data.append(216) #6
data.append(229) #7
data.append(245) #8
data.append(256) #9
data.append(268) #10



plt.plot(data)

plt.xticks( [0,1,2,3,4,5,6,7,8,9], [1,2,3,4,5,6,7,8,9,10] )  

plt.ylabel('Elapsed time for reaching 30 rounds (s)')
plt.xlabel('Worker threshold K')
plt.title('Delay : uniform distribution (5s~10s)')

plt.savefig('deadline_delay_test[5-10_uniform].png')
