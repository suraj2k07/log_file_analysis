import sys
import matplotlib.pyplot as plt
import numpy as np
data=sys.argv[1]
count=sys.argv[2]
count=count.split(',')
data=data.split(',')
data.pop()
count.pop()
count = [int(x) for x in count]
pidata=sys.argv[3]
picount=sys.argv[4]
picount=picount.split(',')
pidata=pidata.split(',')
pidata.pop()
picount.pop()
picount = [int(x) for x in picount]
badata=sys.argv[5]
bacount=sys.argv[6]
bacount=bacount.split(',')
badata=badata.split(',')
badata.pop()
bacount.pop()
bacount = [int(x) for x in bacount]

desired_order = ['E1', 'E2', 'E3', 'E4', 'E5', 'E6']
new_badata = []
new_bacount = []

for event in desired_order:
    found = False
    for i in range(len(badata)):
        if (badata[i] == event):
            new_badata.append(event)
            new_bacount.append(bacount[i])
            found = True
            break
    if not found:
        new_badata.append(event)
        new_bacount.append(0)

badata = new_badata
bacount = new_bacount

n = len(data)
step = max(n // 30, 1)  # To avoid step=0 if n < 30
tick_indices = np.arange(0, n, step) # to didplay only fixed number instead of displaying all on x-axis
plt.plot(data, count)
plt.title( "EVENTS LOGGED VS TIME ")
plt.xticks(tick_indices, [data[i] for i in tick_indices], rotation=90, fontsize=6)
plt.tight_layout()
plt.savefig('static/line.png')
plt.savefig('static/line.jpeg')
plt.close()

bars = plt.bar(badata, bacount)
plt.title("LEVEL STATE DISTRIBUTION")
plt.tight_layout()
plt.bar_label(bars, padding=3)  # Show values on top of bars
plt.savefig('static/bar.png')
plt.savefig('static/bar.jpeg')
plt.close()

    
plt.pie(picount,labels=pidata,autopct='%1.1f%%')
plt.title("EVENT CODE DISTRIBUTION")
plt.tight_layout()
plt.savefig('static/pie.png')
plt.savefig('static/pie.jpeg')
plt.close()
