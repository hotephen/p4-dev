import random
import scipy.stats as ss
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import argparse

parser = argparse.ArgumentParser(description='send entry packet')
parser.add_argument('--dist', required=False, default='u', help='distribution')
parser.add_argument('--parameter', required=False, default='', help='parameter')
parser.add_argument('--num_of_data', required=False, default=10000, help='num_of_data')
parser.add_argument('--sort', required=False, type=int, default=0, help='num_of_data')
parser.add_argument('--index', required=False, type=str, default='', help='file_name index')
parser.add_argument('--entry', required=False, type=int, default=0, help='entry number')

args = parser.parse_args()


# dist = 'u'
# dist = input('[u]niform or [z]ipf? : ')
# d_max = input('d_max? : ')
# d_max = int(d_max)

# d_max = 1000
# num_of_data = 10000
# if dist = 'z'
# dist = 'z'

dist = args.dist
p = args.parameter
d_min = 1
sort = args.sort # sort : 1,2,3
count = {}

for d_max in [args.entry]: #, 10000,15000,20000,25000,30000]:
    num_of_data = int(args.num_of_data)

    if dist == 'u':
        x = np.arange(d_min, d_max + 1) 
        prob = 1 / d_max 
        n = np.random.choice(x, size = num_of_data)
        if args.sort == 1:
            # n = np.sort(n)
            for i in d_max:
                count[i] = n.count(i) #
                
            new_list = sorted(count.items(), reverse=True, key=lambda count:count[1])
            print(new_list)
            # 


        with open('/ssd2/hc/p4-dev/topk/packets/dataset/{}_dist_{}_{}'.format(dist,str(d_max),num_of_data), 'w') as f:
            for i in range(0,num_of_data,10):
                keys = str(n[i]) + ' ' + str(n[i + 1]) + ' ' + str(n[i + 2]) + ' ' + str(n[i + 3]) + ' ' + str(n[i + 4]) + ' ' 
                keys += str(n[i + 5]) + ' ' + str(n[i + 6]) + ' ' + str(n[i + 7]) + ' ' + str(n[i + 8]) + ' ' + str(n[i + 9]) + '\n'
                f.write(keys)                


    if dist == 'z':
        # p = input('parameter: ')
        x = np.arange(d_min, d_max + 1) 
        prob = ss.zipf.cdf(x, float(p))
        prob = prob / prob.sum() 
        n_ = np.random.choice(x, size = num_of_data, p = prob)
        n_ = n_.tolist()
        # print(n_)
        if args.sort == 1:
            n = np.sort(n_)
            for i in range(d_max+1):
                count[i] = n_.count(i) #
                
            # print(count)
            sorted_count = sorted(count.items(), reverse=True, key=lambda count:count[1])
            # print(sorted_count)
            
            n= []
            for tuple in sorted_count:
                for i in range(tuple[1]):
                    n.append(tuple[0])
            # print(len(n))
            # print(n[0])
            # print(n[1])
            if args.index != '':
                f = open('/ssd2/hc/p4-dev/topk/packets/dataset/{}_dist_{}_{}_{}_{}'.format(dist,p,str(d_max),num_of_data, args.index) , 'w')
            else:
                f = open('/ssd2/hc/p4-dev/topk/packets/dataset/{}_dist_{}_{}_{}'.format(dist,p,str(d_max),num_of_data) , 'w')
            for i in range(0,num_of_data,10):
                keys = str(n[i]) + ' ' + str(n[i + 1]) + ' ' + str(n[i + 2]) + ' ' + str(n[i + 3]) + ' ' + str(n[i + 4]) + ' ' 
                keys += str(n[i + 5]) + ' ' + str(n[i + 6]) + ' ' + str(n[i + 7]) + ' ' + str(n[i + 8]) + ' ' + str(n[i + 9]) + '\n'
                f.write(keys)
            f.close()          

        else:
            n = n_
            if args.index != '':
                f = open('/ssd2/hc/p4-dev/topk/packets/dataset/{}_dist_{}_{}_{}_{}'.format(dist,p,str(d_max),num_of_data, args.index) , 'w')
            else:
                f = open('/ssd2/hc/p4-dev/topk/packets/dataset/{}_dist_{}_{}_{}'.format(dist,p,str(d_max),num_of_data) , 'w')
            for i in range(0,num_of_data,10):
                keys = str(n[i]) + ' ' + str(n[i + 1]) + ' ' + str(n[i + 2]) + ' ' + str(n[i + 3]) + ' ' + str(n[i + 4]) + ' ' 
                keys += str(n[i + 5]) + ' ' + str(n[i + 6]) + ' ' + str(n[i + 7]) + ' ' + str(n[i + 8]) + ' ' + str(n[i + 9]) + '\n'
                f.write(keys) 
            f. close

    # print("make entry : %s, numbers : %s, index: %s" %(args.entry) %(args.num_of_data) %(args.index))

    # plt.plot(prob)
    # plt.savefig('z_dist%s.png' %p)



# with open(dist + '_dist_%s' %p, 'w') as f:
#     for i in range(0, num_of_data, 10):
#         keys = str(n[i]) + ' ' + str(n[i + 1]) + ' ' + str(n[i + 2]) + ' ' + str(n[i + 3]) + ' ' + str(n[i + 4]) + ' ' 
#         keys += str(n[i + 5]) + ' ' + str(n[i + 6]) + ' ' + str(n[i + 7]) + ' ' + str(n[i + 8]) + ' ' + str(n[i + 9]) + '\n'
#         f.write(keys)

#python make_dataset_hw.py --dist z --parameter 1.1 --num_of_data 10000 --sort 1 --index 1

