import socket, time
s = socket.create_connection(("127.0.0.1", 6969))
test = b'*1\r\n$4\r\nPING\r\n'
for b in test: 
    s.send(bytes([b]))
    time.sleep(0.5)
print(s.recv(1024).decode())
s.close()
