import cv2
img = cv2.imread("/home/nvidia/project/image.jpg")
height = img.shape[0]
width = img.shape[1]
size = height*width
i = 0
red = list(range(size))
green = list(range(size))
blue = list(range(size))
for row in range(height):
    for col in range(width):
        red[i] = img[row, col, 2]
        i = i+1
i = 0
for row in range(height):
    for col in range(width):
        green[i] = img[row, col, 1]
        i = i + 1
i = 0
for row in range(height):
    for col in range(width):
        blue[i] = img[row, col, 0]
        i = i + 1

for x in range(size):
    red[x] = '{:08b}'.format(red[x])
for x in range(size):
    green[x] = '{:08b}'.format(green[x])
for x in range(size):
    blue[x] = '{:08b}'.format(blue[x])
file = open('/home/nvidia/project/red_data.txt', 'w')
for ele in red:
    file.write(ele+"\n")
file.close()
file = open('/home/nvidia/project/green_data.txt', 'w')
for ele in green:
    file.write(ele+"\n")
file.close()
file = open('/home/nvidia/project/blue_data.txt', 'w')
for ele in blue:
    file.write(ele+"\n")
file.close()
file = open('/home/nvidia/project/size.txt', 'w')
file.write(str(size))
file.close()
