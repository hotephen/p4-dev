import csv
import matplotlib.pyplot as plt

result10 = []
result100 = []
result500 = []

for i in range (1,11):
    
    f = open('host16-topk-10-%d.csv'%(i), 'r')
    rdr = csv.reader(f)
    for line in rdr:
        result10.append(100*(120-int(line[1]))/120)
    f.close()    
    
for i in range (1,11):
    
    f = open('host16-topk-100-%d.csv'%(i), 'r')
    rdr = csv.reader(f)
    for line in rdr:
        result100.append(100*(1200-int(line[1]))/1200)
    f.close()    
    
for i in range (1,11):
    
    f = open('host16-topk-500-%d.csv'%(i), 'r')
    rdr = csv.reader(f)
    for line in rdr:
        result500.append(100*(6000-int(line[1]))/6000)
    f.close()    
    
plt.boxplot((result10,result100,result500))
plt.rcParams['figure.figsize'] = [10, 10]
plt.ylabel('reduction ration(%)')
plt.xticks([1, 2, 3], ['10', '100', '500'])