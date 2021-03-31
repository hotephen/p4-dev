from multiprocessing import Process, Semaphore, shared_memory
import numpy as np
import time


# def worker(id, number, a, shm, serm):
#     num = 0 
#     for i in range(number):
#         num += 1
        
#     serm.acquire() 
#     exst_shm = shared_memory.SharedMemory(name=shm)
#     b = np.ndarray(a.shape, dtype=a.dtype, buffer=exst_shm.buf)
#     b[0] += num
    
#     serm.release()


if __name__ == "__main__":
    # serm = Semaphore(1)
    # start_time = time.time()

    # a = np.array([0])
    # shm = shared_memory.SharedMemory(name='aa', create=True, size=a.nbytes)
    # print(shm.name)
    # c = np.ndarray(a.shape, dtype=a.dtype, buffer=shm.buf)
    # th1 = Process(target=worker, args=(1, 50000000, a, shm.name, serm))
    
    # th1.start()
    # th1.join()

    # print(c[0])

    # while True:         # Don't terminate main thread 
    #     time.sleep(1)
    #     c = np.ndarray(a.shape, dtype=a.dtype, buffer=shm.buf)
    #     print(c[0])
    #     if c[0]==100000000:
    #         break

    # th1.close()
    # shm.close()
    # shm.unlink()
    for i in range(10):
        shm = shared_memory.SharedMemory(name='abcd', create=True, size=10)
        shm.buf[0] = i
        
        while(True):
            time.sleep(1)
            print(shm.buf[0])
            if(shm.buf[0]) == 200:
                print(shm.buf[0])
                break
            
    
    # shm.close()
    # shm.unlink()
    print('a')

