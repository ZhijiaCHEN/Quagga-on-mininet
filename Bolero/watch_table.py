import sys
import os
from time import sleep
table = sys.argv[1]
sql = "select * from {}".format(table)
while (True):
    os.system(
        'PGPASSWORD=bolero psql -P pager --echo-all -U bolero --host=localhost -c "{}"'
        .format(sql))
    sleep(0.5)
    os.system("clear")
    #i += 1