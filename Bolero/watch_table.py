import sys
import os
from time import sleep
import subprocess
table = sys.argv[1]
sql = "select * from {}".format(table)
os.environ['PGPASSWORD'] = 'bolero'
out = ""
while (True):
    os.system("clear")
    os.system('echo "{}"'.format(out))
    sleep(0.5)
    out = subprocess.check_output([
        'psql', '-P', 'pager', '-a', '-U', 'bolero', '--host=localhost', '-c',
        sql
    ])
    #os.system(
    #    'PGPASSWORD=bolero psql -P pager --echo-all -U bolero --host=localhost -c "{}"'
    #    .format(sql))

    #i += 1