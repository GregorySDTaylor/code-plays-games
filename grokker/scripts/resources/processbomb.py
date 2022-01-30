from multiprocessing import Process
import os
import time

def execute_for_process(index):
    print("created process id", os.getpid())
    time.sleep(2)

if __name__ == '__main__':
    print("Start!")
    for i in range(1, 200):
        proc = Process(target=execute_for_process, args=(i,))
        proc.start()
        time.sleep(0.02)