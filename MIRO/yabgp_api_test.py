import json
import urllib.request


url = "http://{bind_host}:{bind_port}/v1/peer/{peer_ip}/send/update".format(
    bind_host="10.0.0.13", bind_port=8801, peer_ip="10.0.0.14"
)
# data = {'nlri': ['107.1.0.0/16'], 'attr': {'1': 0, '2': [[2, [7]]], '3': '10.0.0.34/30'}}
data = {
    "attr": {"1": 0, "2": [(2, [7])], "3": "10.0.0.13"},
    "withdraw": [],
    "nlri": ["101.2.0.0/16"],
    "afi_safi": "ipv4",
}
# {"t": 1551311398.3989794, "seq": 8, "type": 2, "msg": {"attr": {"1": 0, "2": [], "3": "10.0.2.2", "4": 0, "5": 100}, "nlri": ["107.1.0.0/16"], "withdraw": [], "afi_safi": "ipv4"}}
data = json.dumps(data)
postdata = bytes(data, "utf8")
request = urllib.request.Request(url, postdata)
request.add_header("Content-Type", "application/json")
request.method = "POST"
passwdmgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
passwdmgr.add_password(None, url, "admin", "admin")
handler = urllib.request.HTTPBasicAuthHandler(passwdmgr)
opener = urllib.request.build_opener(handler)
res = json.loads(opener.open(request).read())
print(res)
