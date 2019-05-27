from sys import stdout, stdin, argv
from time import sleep

# Print the command to STDIN so ExaBGP can execute
stdout.write('announce route {0} next-hop {1} as-path [100 200 400 50{2}] path-information 0.0.0.{2}\n'.format(argv[1], argv[2], argv[3]))
stdout.flush()
sleep(10*int(argv[3]))
stdout.write('withdraw route {0} next-hop {1} as-path [100 200 400 50{2}] path-information 0.0.0.{2}\n'.format(argv[1], argv[2], argv[3]))
stdout.flush()
#stdout.write('announce route {} next-hop {} as-path [100 200 300]\n'.format(argv[1], argv[2]))
#stdout.flush()

#Keep the script running so ExaBGP doesn't stop running and tear down the BGP peering
while True:
    sleep(10)