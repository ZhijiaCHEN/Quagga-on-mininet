#!/usr/bin/env python
import json
import os
from sys import stdin, stdout, argv
pyPath = os.path.dirname(os.path.abspath(__file__))
f = open(os.path.join(pyPath, 'log/{}'.format(argv[1])), 'w')

def message_parser(line):
    # Parse JSON string  to dictionary
    temp_message = json.loads(line)
 
    # Convert Unix timestamp to python datetime
    #timestamp = datetime.fromtimestamp(temp_message['time'])
 
    if temp_message['type'] == 'state':
        message = {
            'type': 'state',
            #'time': timestamp,
            'peer': temp_message['neighbor']['ip'],
            'state': temp_message['neighbor']['state'],
        }
 
        return message
 
    if temp_message['type'] == 'keepalive':
        message = {
            'type': 'keepalive',
            #'time': timestamp,
            'peer': temp_message['neighbor']['ip'],
        }
 
        return message
 
    # If message is a different type, ignore
    return None


counter = 0
while True:
    try:
        f.write('I am going to read a line...\n')
        f.flush()
        line = stdin.readline().strip()
        f.write('I got a line...\n')
        f.flush()
        
        # When the parent dies we are seeing continual newlines, so we only access so many before stopping
        if line == "":
            counter += 1
            if counter > 100:
                f.write('get too much newline, breaking out...\n')
                f.flush()
                break
            continue
        counter = 0
        
        # Parse message, and if it's the correct type, store in the database
        message = message_parser(line)
        if message:
            f.write(str(message))
        else:
            f.write('unrecognized message type: {}\n'.format(line))
        f.flush()
 
    except KeyboardInterrupt:
        f.write('close on KeyboardInterrupt\n')
        f.close()
    except IOError:
        # most likely a signal during readline
        f.write('close on IOError\n')
        f.close()
f.write('close on finishing the loop\n')
f.close()