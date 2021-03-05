import os
import sys
import random

#Half precision:
max_exp = 15
min_exp = -14

#Single precision:
#max_exp = 127
#min_exp = -126

#Double precision:
#max_exp = 1023
#min_exp = -1022

num = int(sys.argv[1])
file = open("./scripts/rndm_nums.csv","w")

if "-pair" in sys.argv:
    for i in range(0, num):
        m = random.uniform(1,2)
        e = random.randrange(min_exp,max_exp,1)
        sign = random.choice([-1,1])
        x = sign * 2**(e) * m
        m = random.uniform(1,2)
        e = random.randrange(min_exp,max_exp,1)
        sign = random.choice([-1,1])
        y = sign * 2**(e) * m
        file.write(str(x)+","+str(y)+"\n")
else:
    for i in range(0, num):
        m = random.uniform(1,2)
        e = random.randrange(min_exp,max_exp,1)
        sign = random.choice([-1,1])
        x = sign * 2**(e) * m

        file.write(str(x)+"\n")

file.close()
