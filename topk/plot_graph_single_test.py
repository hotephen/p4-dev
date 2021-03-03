import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np


dist = 'z'
# t = 'daiet'


result_daiet = {}
result_topk = {}
output_daiet = []
output_topk = []

result_daiet2  = {}
result_topk2  = {}
output_daiet2  = []
output_topk2  = []

result_daiet3  = {}
result_topk3  = {}
output_daiet3  = []
output_topk3  = []

xtick_l = []
xtick_r = []
k = -1
p = '1.1'
p2 = '2'
for entry in [1000,3000,5000]: # FIXME : modify just this line
    num = 1000
    k = k + 1
    result_daiet[ str(entry) ] = []
    result_topk[ str(entry) ] = []
    result_daiet2[ str(entry) ] = []
    result_topk2[ str(entry) ] = []
    result_daiet3[ str(entry) ] = []
    result_topk3[ str(entry) ] = []

    t = 'daiet'
    for i in range (1,2):
        
        dist = 'z'
        f = open('/ssd2/hc/p4-dev/topk/logs/mininet/daiet/daiet-single-1000--{}-1.1-3.csv'.format(entry), 'r')
        opened_file = f.readlines()
        a = opened_file[-1].split(',')[1]
        result_daiet[str(entry)].append(1-int(a)/(num))
        f.close()

        f = open('/ssd2/hc/p4-dev/topk/logs/mininet/daiet/daiet-single-1000--{}-2-3.csv'.format(entry), 'r')
        opened_file = f.readlines()
        a = opened_file[-1].split(',')[1]
        result_daiet2[str(entry)].append(1-int(a)/(num))
        f.close()

        dist = 'u'
        # f = open('/ssd2/hc/p4-dev/topk/logs/mininet/{}-single-{}-{}-{}-{}.csv'.format(t,num,'',entry,i), 'r') 
        f = open('/ssd2/hc/p4-dev/topk/logs/mininet/daiet-single-1000-u-{}-{}.csv'.format(entry,i), 'r') 
        opened_file = f.readlines()
        a = opened_file[-1].split(',')[1]
        print(a)
        result_daiet3[str(entry)].append(1-int(a)/(num))
        f.close()

    t = 'topk'
    for i in range (1,2):
        
        dist = 'z'
        f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk/topk-single-1000--{}-1.1-3.csv'.format(entry), 'r')
        opened_file = f.readlines()
        a = opened_file[-1].split(',')[1]
        result_topk[str(entry)].append(1-int(a)/(num))
        f.close()

        f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk/topk-single-1000--{}-2-3.csv'.format(entry), 'r')
        opened_file = f.readlines()
        a = opened_file[-1].split(',')[1]
        result_topk2[str(entry)].append(1-int(a)/(num))
        f.close()

        dist = 'u'
        # f = open('/ssd2/hc/p4-dev/topk/logs/mininet/{}-single-{}-{}-{}-{}.csv'.format(t,num,'',entry,i), 'r')
        f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk-single-1000-u-{}-{}.csv'.format(entry,i), 'r') 
        opened_file = f.readlines()
        a = opened_file[-1].split(',')[1]
        print(a)
        result_topk3[str(entry)].append(1-int(a)/(num))
        f.close()

    output_daiet.append(result_daiet[str(entry)])
    output_topk.append(result_topk[str(entry)])
    output_daiet2.append(result_daiet2[str(entry)])
    output_topk2.append(result_topk2[str(entry)])
    output_daiet3.append(result_daiet3[str(entry)])
    output_topk3.append(result_topk3[str(entry)])


    xtick_l.append(k)
    print(xtick_l)
    xtick_r.append(str(entry))
    print(xtick_r)

print(output_daiet)
print(output_topk)
print(output_daiet2)
print(output_topk2)
print(output_daiet3)
print(output_topk3)

# plt.boxplot( output_daiet, 0, '',patch_artist=True)
# plt.boxplot( output_topk, 0, '',patch_artist=True)
plt.plot( output_daiet, label='DAIET (zipf: 1.1)', marker=".")
plt.plot( output_topk, label='AggHDR (zipf: 1.1)', marker="." )
plt.plot( output_daiet2, label='DAIET (zipf: 2.0)', marker=".")
plt.plot( output_topk2, label='AggHDR (zipf: 2.0)', marker="." )
plt.plot( output_daiet3, label='DAIET (uniform)', marker=".")
plt.plot( output_topk3, label='AggHDR (uniform)', marker="." )
plt.legend()
plt.rcParams['figure.figsize'] = [10, 10]
plt.ylabel('Reduction ratio')
plt.xlabel('The number of entry types (single_switch)')

# plt.xticks([1, 2, 3], ['10', '100', '500'])
plt.xticks( xtick_l , xtick_r )
plt.yticks(np.arange(0.1, 1.05, 0.1))

# plt.savefig('%s.png' %t)
plt.savefig('graph-single_.png')


# 파일명의 dist부분 공백으로 되어있음.