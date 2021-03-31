from multiprocessing import Process, Semaphore, shared_memory
import numpy as np
import time


# def worker(id, number, shm_name, serm):
#     num = 0 
#     for i in range(number):
#         num += 1
        
#     serm.acquire() 
#     exst_shm = shared_memory.SharedMemory(name=shm_name)
#     b = np.ndarray(a.shape, dtype=a.dtype, buffer=exst_shm.buf)
#     b[0] += num
    
#     serm.release()

#     print(b[0])
    
#     exst_shm.close()
#     # exst_shm.unlink()




if __name__ == "__main__":
    # serm = Semaphore(1)
    # start_time = time.time()

    # a = np.array([0])
    # shm_name = 'aa'
    # # shm = shared_memory.SharedMemory(create=True, size=a.nbytes)
    # # c = np.ndarray(a.shape, dtype=a.dtype, buffer=shm.buf)
    
    # th2 = Process(target=worker, args=(2, 50000000, shm_name, serm))

    # th2.start()
    # th2.join()

    # th2.close()

    shm = shared_memory.SharedMemory(name='abcd')
    
    print(shm.buf[0])
    
    shm.buf[0] = 200
    print(shm.buf[0])
    print("Save global gradient")

    shm.close()
    # shm.unlink()




