import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np




# output_daiet = []
# result_topk = {}
# output_topk = []

# result_topk11 = {}
# output_topk11 = []
# result_topk12 = {}
# output_topk12 = []
# result_topk13 = {}
# output_topk13 = []

# result_daiet2  = {}
# result_topk2  = {}
# output_daiet2  = []
# output_topk2  = []

# result_daiet3  = {}
# result_topk3  = {}
# output_daiet3  = []
# output_topk3  = []

# xtick_l = []
# xtick_r = []
# k = -1

# ## Parameters
# p = '1.1'
# p2 = '2'
# num = 20000
# num_exp = 1

# for entry in [1000,2000,3000,4000,5000,6000,7000,8000,9000,10000]: #,5000]: # FIXME : modify just this line

#     k = k + 1
#     result_daiet[ str(entry) ] = []
#     result_topk[ str(entry) ] = []
#     result_daiet2[ str(entry) ] = []
#     result_topk2[ str(entry) ] = []
#     result_daiet3[ str(entry) ] = []
#     result_topk3[ str(entry) ] = []

#     result_topk11[ str(entry) ] = []
#     result_topk12[ str(entry) ] = []
#     result_topk13[ str(entry) ] = []

#     for i in range (1,num_exp+1):
#         dist = 'z'
#         t = 'daiet'
#         f = open('/ssd2/hc/p4-dev/topk/logs/mininet/daiet/daiet-fat_tree-{}-{}-{}-{}-{}.csv'.format(dist,p,num,entry,i), 'r') #daiet-fat_tree-z-1.1-1000-5000-1
#         opened_file = f.readlines()
#         a = opened_file[-1].split(',')[1]
#         result_daiet[str(entry)].append(1-int(a)/(12*num))
#         f.close()

#         # f = open('/ssd2/hc/p4-dev/topk/logs/mininet/daiet/daiet-fat_tree-{}-{}-{}-{}-{}.csv'.format(dist,p2,num,entry,i), 'r')
#         # opened_file = f.readlines()
#         # a = opened_file[-1].split(',')[1]
#         # result_daiet2[str(entry)].append(1-int(a)/(12*num))
        
#         # f.close()

#         # dist = 'u'
#         # f = open('/ssd2/hc/p4-dev/topk/logs/mininet/daiet/{}-{}-{}-{}.csv'.format(t,num,i,dist), 'r')
#         # opened_file = f.readlines()
#         # a = opened_file[-1].split(',')[1]
#         # result_daiet3[str(entry)].append(1-int(a)/(12*num))
        
#         # f.close()
# ############
#     for i in range (1,num_exp+1): 
#         dist = 'z'
#         t = 'topk'
#         f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk/topk-fat_tree-{}-{}-{}-{}-{}.csv'.format(dist,p,num,entry,i), 'r') #topk-fat_tree-z-1.1-1000-1000-1
#         opened_file = f.readlines()
#         a = opened_file[-1].split(',')[1]
#         result_topk[str(entry)].append(1-int(a)/(12*num))
#         f.close()

#     # for i in range (1,num_exp+1):
#     #     dist = 'z'
#     #     t = 'topk'
#     #     f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk/count1/topk-fat_tree-{}-{}-{}-{}-{}.csv'.format(dist,p,num,entry,i), 'r') #topk-fat_tree-z-1.1-1000-1000-1
#     #     opened_file = f.readlines()
#     #     a = opened_file[-1].split(',')[1]
#     #     result_topk11[str(entry)].append(1-int(a)/(12*num))
#     #     f.close()

#     # for i in range (1,num_exp+1):
#     #     dist = 'z'
#     #     t = 'topk'
#     #     f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk/count5/topk-fat_tree-{}-{}-{}-{}-{}.csv'.format(dist,p,num,entry,i), 'r') #topk-fat_tree-z-1.1-1000-1000-1
#     #     opened_file = f.readlines()
#     #     a = opened_file[-1].split(',')[1]
#     #     result_topk12[str(entry)].append(1-int(a)/(12*num))
#     #     f.close()
        
#     # for i in range (1,num_exp+1):
#     #     dist = 'z'
#     #     t = 'topk'
#     #     f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk/count10/topk-fat_tree-{}-{}-{}-{}-{}.csv'.format(dist,p,num,entry,i), 'r') #topk-fat_tree-z-1.1-1000-1000-1
#     #     opened_file = f.readlines()
#     #     a = opened_file[-1].split(',')[1]
#     #     result_topk13[str(entry)].append(1-int(a)/(12*num))
#     #     f.close()

#         # f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk/topk-fat_tree-{}-{}-{}-{}-{}.csv'.format(dist,p2,num,entry,i), 'r')
#         # opened_file = f.readlines()
#         # a = opened_file[-1].split(',')[1]
#         # result_topk2[str(entry)].append(1-int(a)/(12*num))
#         # f.close()

#         # dist = 'u'
#         # f = open('/ssd2/hc/p4-dev/topk/logs/mininet/topk/{}-{}-{}-{}.csv'.format(t,num,i,dist), 'r')
#         # opened_file = f.readlines()
#         # a = opened_file[-1].split(',')[1]
#         # result_topk3[str(entry)].append(1-int(a)/(12*num))
#         # f.close()

#     output_daiet.append(result_daiet[str(entry)])
#     output_topk.append(result_topk[str(entry)])
#     # output_daiet2.append(result_daiet2[str(entry)])
#     # output_topk2.append(result_topk2[str(entry)])
#     # output_daiet3.append(result_daiet3[str(entry)])
#     # output_topk3.append(result_topk3[str(entry)])
#     # output_topk11.append(result_topk11[str(entry)])
#     # output_topk12.append(result_topk12[str(entry)])
#     # output_topk13.append(result_topk13[str(entry)])

#     xtick_l.append(k)
#     print(xtick_l)
#     xtick_r.append(str(entry))
#     print(xtick_r)

# print(output_daiet)
# print(output_topk)
# # print(output_daiet2)
# # print(output_topk2)

# # plt.boxplot( output_daiet, 0, '',patch_artist=True)
# # plt.boxplot( output_topk, 0, '',patch_artist=True)
# plt.plot( output_daiet, label='DAIET (zipf, a= 1.1)', marker=".")
# plt.plot( output_topk, label='AggHDR (zipf, a= 1.1)', marker="." )
# # plt.plot( output_daiet2, label='DAIET (zipf: 2.0)', marker=".")
# # plt.plot( output_topk2, label='AggHDR (zipf: 2.0)', marker="." )
# # plt.plot( output_daiet3, label='DAIET (uniform)', marker=".")
# # plt.plot( output_topk3, label='AggHDR (uniform)', marker="." )
# # plt.plot( output_topk11, label='AggHDR (count = 1)', marker="." )
# # plt.plot( output_topk12, label='AggHDR (count = 5)', marker="." )
# # plt.plot( output_topk13, label='AggHDR (count = 10)', marker="." )



# # plt.legend()
# # plt.rcParams['figure.figsize'] = [10, 10]
# # plt.ylabel('Y')
# # plt.xlabel('X')
# # plt.xticks([1, 2, 3], ['10', '100', '500'])
# # plt.xticks( xtick_l , xtick_r )
# # plt.yticks(np.arange(0.1,1.05,0.1))


y = []

f = open('bf_result.txt', 'r')
y = f.readlines()
y = map(int, y)
f.close()

print(len(y))
# print(y)

plt.rcParams['figure.figsize'] = (80, 10)
plt.plot(y, label='')
# plt.figure(figsize=(50,10))
plt.legend()


plt.ylabel('The number of active flows')
plt.xlabel('Packet seqeunce number')
# plt.xticks(range(len(y)))
# plt.yticks()
plt.savefig('num_active_flow.png')
