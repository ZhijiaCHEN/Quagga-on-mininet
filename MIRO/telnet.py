import getpass
import sys
import telnetlib

host = "10.0.0.10"
port = 2605
tn = telnetlib.Telnet(host=host, port=port)
print tn.read_until('Password: ', 0.05)
tn.write("en\n")
print tn.read_until("> ", 0.05)
tn.write("en\n")
print tn.read_until("Password: ", 0.05)
tn.write("en\n")
print tn.read_until("# ", 0.05)
tn.write("configure terminal\n")
print tn.read_until("# ", 0.05)
tn.write("show running-config\n")
print tn.read_until("# ", 0.05)
tn.write("exit\n")
tn.close()