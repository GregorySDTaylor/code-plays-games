import os
import base64
import sys

data = ""

for x in range(1,32,1):
    data += base64.b64encode(os.urandom(10000000)).decode() # 10mb
    print(f'{sys.getsizeof(data)/1048576} mb')