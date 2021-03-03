import time
import threading


delay = 5

def function():
    print("Hi")
    print(time.time())

print(time.time())
threading.Timer(2, function).start()
print('hi')

