DROP TABLE if EXISTS rib_in;
create TABLE rib_in(
    prefix VARCHAR,
    local_preference INTEGER default 100,
    metric INTEGER,
    next_hop VARCHAR,
    as_path INTEGER[],
    local_router VARCHAR,
    remote_router VARCHAR
);

DROP TABLE IF EXISTS rib_out;
CREATE TABLE rib_out(
    prefix VARCHAR,
    local_preference INTEGER default 100,
    metric INTEGER,
    next_hop VARCHAR,
    as_path INTEGER[],
    target_router VARCHAR
);

DROP TABLE IF EXISTS routers;
CREATE TABLE routers(
    id VARCHAR,
    api_address VARCHAR,
    api_port VARCHAR
);
INSERT INTO routers VALUES('103.0.0.1', '10.0.0.9', 8801), ('103.0.0.2', '10.0.0.13', 8801), ('103.0.0.3', '10.0.0.17', 8801);

CREATE OR REPLACE FUNCTION announce_route ()
    RETURNS TRIGGER
AS $$
    import json
    import urllib.request
    import sys

    msg = {}
    msg['attr'] = {"1":0, "2":[[2, TD["new"]["as_path"]]], "3":TD["new"]["next_hop"], "5":100}
    msg['withdraw'] = []
    msg['afi_safi'] = "ipv4"
    msg['nlri'] = [TD["new"]["prefix"]]
    json_data = json.dumps(msg)
    plpy.notice("announce_route sends msg: {}".format(json_data))

    routerInfo = plpy.execute("SELECT * FROM routers WHERE id = '{}'".format(TD["new"]["target_router"]))
    routerInfo = routerInfo[0]
    url = "http://{bind_host}:{bind_port}/v1/peer/{peer_ip}/send/update".format(
        bind_host=routerInfo["api_address"], bind_port=routerInfo["api_port"], peer_ip=routerInfo["id"]
    )
    data = json.dumps(msg)
    postdata = bytes(data, "utf8")
    request = urllib.request.Request(url, postdata)
    request.add_header("Content-Type", "application/json")
    request.method = "POST"
    passwdmgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
    passwdmgr.add_password(None, url, "admin", "admin")
    handler = urllib.request.HTTPBasicAuthHandler(passwdmgr)
    opener = urllib.request.build_opener(handler)
    res = json.loads(opener.open(request).read())
    plpy.notice("announcement returns: {}".format(res))
$$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS announce_route ON rib_out;
CREATE TRIGGER announce_route AFTER INSERT ON rib_out
    FOR EACH ROW
    EXECUTE PROCEDURE announce_route();

CREATE OR REPLACE FUNCTION withdraw_route ()
    RETURNS TRIGGER
AS $$
    import json
    import urllib.request
    import sys

    msg = {}
    msg['attr'] = {}
    msg['withdraw'] = [TD["new"]["prefix"]]
    msg['afi_safi'] = "ipv4"
    msg['nlri'] = []
    json_data = json.dumps(msg)
    plpy.notice("withdraw_route sends msg: {}".format(json_data))

    routerInfo = plpy.execute("SELECT * FROM routers WHERE id = '{}'".format(TD["new"]["target_router"]))
    routerInfo = routerInfo[0]
    url = "http://{bind_host}:{bind_port}/v1/peer/{peer_ip}/send/update".format(
        bind_host=routerInfo["api_address"], bind_port=routerInfo["api_port"], peer_ip=routerInfo["id"]
    )
    data = json.dumps(msg)
    postdata = bytes(data, "utf8")
    request = urllib.request.Request(url, postdata)
    request.add_header("Content-Type", "application/json")
    request.method = "POST"
    passwdmgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
    passwdmgr.add_password(None, url, "admin", "admin")
    handler = urllib.request.HTTPBasicAuthHandler(passwdmgr)
    opener = urllib.request.build_opener(handler)
    res = json.loads(opener.open(request).read())
    plpy.notice("withdraw_route returns: {}".format(res))
$$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS withdraw_route ON rib_out;
CREATE TRIGGER withdraw_route AFTER DELETE ON rib_out
    FOR EACH ROW
    EXECUTE PROCEDURE withdraw_route();

CREATE OR REPLACE FUNCTION miro() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    rec RECORD;
    pref INT := NEW.local_preference;
BEGIN
    IF (array_position(NEW.as_path::int[], 2) > 0) THEN
        pref := 1;
    END IF;
    FOR rec IN SELECT id FROM routers LOOP
        INSERT INTO rib_out VALUES (NEW.prefix, pref, NEW.metric, NEW.next_hop, NEW.as_path, rec.id);
    END LOOP;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS miro ON rib_in;
CREATE TRIGGER miro AFTER INSERT ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE miro();