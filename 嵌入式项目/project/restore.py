import  cv2
import numpy as np
img=np.ones((500,500,3),dtype=np.int16)
red = list(range(250000))
green = list(range(250000))
blue = list(range(250000))
i = 0
for line in open("/home/nvidia/project/transport/red_decode.txt"):
    line = int(line, base=2)
    red[i]=int(line)
    i=i+1
i=0
for line in open("/home/nvidia/project/transport/green_decode.txt"):
    line = int(line, base=2)
    green[i]=int(line)
    i=i+1
i=0
for line in open("/home/nvidia/project/transport/blue_decode.txt"):
    line = int(line, base=2)
    blue[i]=int(line)
    i=i+1
i = 0
for row in range(500):
    for col in range(500):
        img[row, col, 0] = blue[i]
        i = i + 1

i = 0
for row in range(500):
    for col in range(500):
        img[row, col, 1] = green[i]
        i = i + 1

i = 0
for row in range(500):
    for col in range(500):
        img[row, col, 2] = red[i]
        i = i+1

img1=cv2.imread("/home/nvidia/project/image.jpg")

for x in range(3):
    for y in range(500):
        for z in range(500):
	    img1[y,z,x]=0
            img1[y, z, x]=img[y,z,x]


cv2.imshow('image', img1)
cv2.waitKey(0)
