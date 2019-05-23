from sys import stdout, stdin, argv
from time import sleep

# Print the command to STDIN so ExaBGP can execute
stdout.write('announce route {} next-hop {} community [100:300] as-path [100 200 300] path-information 0.0.0.3\n'.format(argv[1], argv[2]))
stdout.flush()
sleep(5)
stdout.write('announce route {} next-hop {} community [100:400] as-path [100 200 400] path-information 0.0.0.4\n'.format(argv[1], argv[2]))
stdout.flush()

#Keep the script running so ExaBGP doesn't stop running and tear down the BGP peering
while True:
    sleep(10)