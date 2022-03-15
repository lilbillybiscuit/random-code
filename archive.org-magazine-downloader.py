from urllib import request
import wget
import os
import threading
import time
import sys
import math
import hashlib
from tqdm import tqdm
maxdownloadingthreads=40
magazine_name="sim_interview_2001-07_31_7" # sys.argv[1]
downloaded=0
active=0
threadfailures=0
failedsha="c94b9a75e0b9d80dcce1a668c56d1172ac6c5e3279be2e62fc25bd01cf261c82"

# "https://ia902306.us.archive.org/BookReader/BookReaderPreview.php?id=sim_interview_2001-07_31_7&subPrefix=sim_interview_2001-07_31_7&itemPath=/12/items/sim_interview_2001-07_31_7&server=ia902306.us.archive.org&page=leaf2&fail=preview&&scale=2&rotate=0"

def check(id):
    global url
    url = f"https://ia802306.us.archive.org/BookReader/BookReaderPreview.php?id={magazine_name}&subPrefix={magazine_name}&itemPath=/12/items/{magazine_name}&server=ia802306.us.archive.org&page=leaf{id}&fail=preview&&scale=1&rotate=0"
    attempts=0
    while True:
        if attempts>3:
            #print(id, "failed")
            return False
        try:
            request.urlretrieve(url, 'tempfile.jpeg')
            sha256=hashlib.sha256()
            with open("tempfile.jpeg","rb") as f:
                for byte_block in iter(lambda: f.read(4096),b""):
                    sha256.update(byte_block)
            if (str(sha256.hexdigest()) == failedsha):
                #print(id, "missing page")
                return False
            #print(id, "success")
            return True
        except Exception as e:
            time.sleep(0.5)
        attempts+=1
    return None
def binary_search(a,b):
    print("Binary searching for the last page...")
    l, r=a,b
    maxsearches = int(math.log(b-a,2)+2)
    for i in tqdm(range(maxsearches)):
        mid=int((l+r)/2)
        time.sleep(0.5)
        if (check(mid)):
            l=mid
        else:
            r=mid-1
    print("Last page is",l)
    return l+1     
f"https://ia802306.us.archive.org/BookReader/BookReaderImages.php?zip=/12/items/{magazine_name}/{magazine_name}_jp2.zip&file={magazine_name}_jp2/{magazine_name}_0084.jp2&id={magazine_name}&scale=8&rotate=0"
def getimages(i):
    global active, downloaded, magazine_name
    active+=1
    url = f"https://ia802306.us.archive.org/BookReader/BookReaderPreview.php?id={magazine_name}&subPrefix={magazine_name}&itemPath=/12/items/{magazine_name}&server=ia802306.us.archive.org&page=leaf{i}&fail=preview&&scale=1&rotate=0"
    fileurl='images/leaf'+str(i)+'.jpeg'
    downloaded+=1
    attempts=0
    while True:
        if attempts>3:
            threadfailures+=1
            return
        try:
            request.urlretrieve(url, fileurl)
            break
        except Exception as e:
            print(e)
            time.sleep(1)
            print("Error downloading" + f"leaf{i}.jpeg (might be end of sequence)")
        attempts+=1
    active-=1

threads=[]
for i in range(0, binary_search(0,20000)):
    hi=threading.Thread(target=getimages, args=(i,))
    threads.append(hi)

for i in tqdm(range(0,len(threads))):
    while (active>maxdownloadingthreads and threadfailures < maxdownloadingthreads):
        time.sleep(1)
    threads[i].start()

for thread in threads:
    thread.join()
