from urllib import request
import wget
import os
import threading
import time

maxdownloadingthreads=40
# Second number is y axis 65514-65535 (lower is down)
# First number is x axis 65535-67151 (lower is left)
# https://tiles.nytimes.com/issue/2/c79ab250fc716e75f8427c60eb33a65a/1/tiles/17/66707/65522.png?Expires=1647574455&Signature=
downloaded=0
active=0

def getimages(i):
    global active, downloaded
    active+=1
    for j in range(65514, 65536):
        row=str(i)#.zfill(3)
        col=str(j)#.zfill(3)
        downloaded+=1
        print(downloaded,row,col)
        #url = "https://www.micro-pano.com/pearl/panos/STITCH_-_FULL_35x.tiles/l8/"+row+"/l8_"+row+"_"+col+".jpg"
        url= f"https://tiles.nytimes.com/issue/2/c79ab250fc716e75f8427c60eb33a65a/1/tiles/17/{row}/{col}.png[Cloudfront Parameters Here]"
        fileurl='/mnt/data/images/'+row+'_'+col+'.png'
        while True:
            try:
                #wget.download(url, fileurl)
                request.urlretrieve(url, fileurl)
                break
            except Exception as e:
                print(e)
                time.sleep(1)
                print("ERROR DOWNLOADING " + f"{row}_{col}.png")
        #request.urlretrieve(url, fileurl)
    active-=1

threads=[]
for i in range(65535, 67152):
    hi=threading.Thread(target=getimages, args=(i,))
    threads.append(hi)

for i in range(0,len(threads)):
    while (active>maxdownloadingthreads):
        time.sleep(1)
    threads[i].start()

for thread in threads:
    thread.join()
