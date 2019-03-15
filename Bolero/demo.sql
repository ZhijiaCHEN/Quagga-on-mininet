DROP TABLE if EXISTS rib_in;
create TABLE rib_in(
    rid SERIAL PRIMARY KEY,
    prefix VARCHAR NOT NULL,
    local_preference INTEGER default 100,
    metric INTEGER,
    next_hop VARCHAR NOT NULL,
    as_path VARCHAR,
    router VARCHAR
);

DROP TABLE IF EXISTS rib_out;
CREATE TABLE rib_out(
    rid INTEGER,
    prefix VARCHAR NOT NULL,
    local_preference INTEGER default 100,
    metric INTEGER,
    next_hop VARCHAR NOT NULL,
    as_path VARCHAR,
    router VARCHAR
);

DROP TABLE IF EXISTS routers;
CREATE TABLE routers(
    id VARCHAR,
    api_address VARCHAR,
    api_port VARCHAR
);
INSERT INTO routers VALUES('103.0.0.1', '10.0.0.9', 8801), ('103.0.0.2', '10.0.0.13', 8801), ('103.0.0.3', '10.0.0.17', 8801);

CREATE FUNCTION announce_route ()
    RETURNS TRIGGER
AS $$
    import json
    import urllib.request
    import sys

    msg = {}
    msg['attr'] = {"1":0, "2":[[2, TD["new"]["as_path"]]], "3":TD["new"]["next_hop"]}
    msg['withdraw'] = []
    msg['afi_safi'] = ["ipv4"]
    msg['nlri'] = TD["new"]["prefix"]
    json_data = json.dumps(msg)
    plpy.notice("announce_route sends msg: %s".format(json_data))

    routerInfo = plpy.execute("SELECT * FROM routers WHERE id = %s".format(TD["new"]["router"]))
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
    plpy.notice("announcement returns: %s", res)
$$ LANGUAGE plpython3u;

CREATE TRIGGER announce_route AFTER INSERT ON rib_out
    FOR EACH ROW
    EXECUTE PROCEDURE announce_route();

CREATE FUNCTION withdraw_route ()
    RETURNS TRIGGER
AS $$
    import json
    import urllib.request
    import sys

    msg = {}
    msg['attr'] = {}
    msg['withdraw'] = [TD["new"]["prefix"]]
    msg['afi_safi'] = ["ipv4"]
    msg['nlri'] = []
    json_data = json.dumps(msg)
    plpy.notice("withdraw_route sends msg: %s".format(json_data))

    routerInfo = plpy.execute("SELECT * FROM routers WHERE id = %s".format(TD["new"]["router"]))
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
    plpy.notice("withdraw_route returns: %s", res)
$$ LANGUAGE plpython3u;

CREATE TRIGGER withdraw_route AFTER DELETE ON rib_out
    FOR EACH ROW
    EXECUTE PROCEDURE withdraw_route();

CREATE OR REPLACE FUNCTION miro() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    rec RECORD;
BEGIN
    IF (array_position(new.as_path::int[], 2) > 0) THEN
        FOR rec IN SELECT id FROM routers LOOP
            INSERT INTO rib_out VALUES (NEW.rid, NEW.prefix, 1, NEW.metric, NEW.next_hop, NEW.as_path, rec.id);
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS miro ON rib_in;
CREATE TRIGGER miro AFTER INSERT ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE miro();