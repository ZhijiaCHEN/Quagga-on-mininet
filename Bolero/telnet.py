import getpass
import sys
import telnetlib
import os
from time import sleep
host = sys.argv[1]
port = 2605
tn = telnetlib.Telnet(host=host, port=port)
print tn.read_until('Password: ', 0.05)
tn.write("en\n")
print tn.read_until("> ", 0.05)
tn.write("en\n")
print tn.read_until("Password: ", 0.05)
tn.write("en\n")
print tn.read_until("# ", 0.05)
#tn.write("configure terminal\n")
#print tn.read_until("# ", 0.05)
i = 0
while (True):
    tn.write("show ip bgp\n")
    print tn.read_until("# ", 0.05)
    sleep(0.3)
    os.system("clear")
    #i += 1

tn.write("exit\n")
tn.close()