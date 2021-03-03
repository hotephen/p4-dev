import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np


fig = plt.boxplot( ([0.817, 0.793, 0.742], [0.985, 0.938, 0.933], [0.621, 0.570, 0.48] , [0.798, 0.694, 0.615], ), autorange=True, patch_artist=True)

plt.xticks([1,2,3,4] , ['DAIET\n(entry:1000)','AggHDR\n(entry:1000)', 'DAIET\n(entry:2000)','AggHDR\n(entry:2000)'] ) 
plt.ylabel('Reduction ratio')
# plt.xlabel('The number of packets : 2000')
plt.yticks(np.arange(0.4, 0.95, 0.1))
plt.rcParams['figure.figsize'] = [10, 10]
plt.grid(b=True, which='major', axis='y')
plt.savefig('graph-single_manual.png')




plt.subplot(121)
plt.boxplot( ([0.817, 0.793, 0.742], [0.985, 0.938, 0.933]), autorange=True, patch_artist=True  )
plt.xticks([1, 2] , ['DAIET','AggHDR'] ) 
plt.xlabel('The number of entry types : 1000')
plt.ylabel('Reduction ratio')
plt.yticks(np.arange(0.75, 1.01, 0.05))
plt.grid(b=True, which='major', axis='y')


plt.subplot(122)
plt.boxplot( ([0.621, 0.570, 0.48] , [0.798, 0.694, 0.615]), autorange=True, patch_artist=True )
plt.xlabel('The number of entry types : 2000')
plt.xticks([1, 2] , ['DAIET','AggHDR'] ) 

plt.yticks(np.arange(0.5, 0.8, 0.05))
plt.grid(b=True, which='major', axis='y')


# plt.legend()
plt.rcParams['figure.figsize'] = [10, 10]
plt.savefig('graph-single_manual_2.png')