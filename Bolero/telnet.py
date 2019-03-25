import getpass
import sys
import telnetlib
import os
from time import sleep
host = sys.argv[1]
port = 2605
timeout = 0.1
tn = telnetlib.Telnet(host=host, port=port)
print tn.read_until('Password: ', timeout)
tn.write("en\n")
print tn.read_until("> ", timeout)
tn.write("en\n")
print tn.read_until("Password: ", timeout)
tn.write("en\n")
print tn.read_until("# ", timeout)
#tn.write("configure terminal\n")
#print tn.read_until("# ", 0.05)
i = 0
out = ''
while (True):
    os.system("clear")
    print out
    sleep(0.5)
    tn.write("show ip bgp\n")
    out = tn.read_until("# ", timeout)
    #i += 1

tn.write("exit\n")
tn.close()