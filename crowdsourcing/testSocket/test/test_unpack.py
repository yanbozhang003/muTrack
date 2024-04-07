from struct import *

with open("test_timestamp.txt", mode='rb') as file: # b is important -> binary
    fileContent = file.read()

print('\n')