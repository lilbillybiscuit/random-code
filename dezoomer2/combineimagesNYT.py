import cv2
import numpy as np
import pickle
from tqdm import tqdm
import os
import numpy as np
height=22
width=1617
done=0
dbg=np.ones((height, width))
curx,cury=0,0
maxx,maxy=0,0
offset=65535

print("Calculating height...")
for i in tqdm(range(offset,offset-height,-1)):
    tmp=cv2.imread(f'/mnt/data/images/{offset}_{i}.png')
    maxy+=tmp.shape[0]
print("Calculating width...")
for i in tqdm(range(offset,offset+width)):
    tmp=cv2.imread(f'/mnt/data/images/{i}_{offset}.png')
    maxx+=tmp.shape[1]
print(f"Shape of image will be {maxx}, {maxy}")
with open('/mnt/data/imagearr.memmap', 'w') as fp:
    pass
newimage=np.memmap('/mnt/data/imagearr.memmap', dtype="uint8", mode="w+",shape=(maxy, maxx, 3))


for i in tqdm(range(offset, offset+width)):
    cury=0#(height-1)*256
    mintmpy=35203985239208984
    for j in range(offset, offset-height,-1):
        #Get filename
        row = str(i)
        col = str(j)
        fileurl= f'/mnt/data/images/{row}_{col}.png'

        done+=1
        if (done%100==0):
            hi=0
            #print("Progress:", str(int(round(done / (height * width), 2) * 100)) + "%")
        if done%10000==0:
            newimage.flush()
        im = cv2.imread(fileurl)
        shp = im.shape
        cury+=256 #im.shape[1]
        mintmpy=min(mintmpy,im.shape[0])

    curx+=256
with open('/mnt/data/cv2done.pickle', 'wb') as handle:
    pickle.dump(newimage, handle)

if cv2.imwrite("output.png", newimage):
    print("Saved")
else:
    print("Error while saving")
