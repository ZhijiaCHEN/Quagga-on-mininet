from sys import stdout, stdin, argv
from time import sleep

# Print the command to STDIN so ExaBGP can execute
stdout.write('announce route 200.10.10.0/24 next-hop {} local-preference 65000 community [100:100]\n'.format(argv[1]))
stdout.flush()

#Keep the script running so ExaBGP doesn't stop running and tear down the BGP peering
while True:
    sleep(10)