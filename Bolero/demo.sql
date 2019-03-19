DROP TABLE if EXISTS rib_in;
create TABLE rib_in(
    rid SERIAL PRIMARY KEY,
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
    rid INTEGER,
    prefix VARCHAR,
    local_preference INTEGER default 100,
    metric INTEGER,
    next_hop VARCHAR,
    as_path INTEGER[],
    target_router VARCHAR
);

DROP TABLE IF EXISTS routers;
CREATE TABLE routers(
    id VARCHAR PRIMARY KEY,
    api_address VARCHAR,
    api_port VARCHAR
);

DROP TABLE IF EXISTS links;
CREATE TABLE links(
    r1 VARCHAR,
    intf1 VARCHAR,
    r2 VARCHAR,
    intf2 VARCHAR
);

INSERT INTO links VALUES('103.0.0.1', '103.0.0.1', '103.0.0.3', '103.0.0.2'), ('103.0.0.3', '103.0.0.2', '103.0.0.1', '103.0.0.1'), ('103.0.0.2', '103.0.0.5', '103.0.0.3', '103.0.0.6'), ('103.0.0.3', '103.0.0.6', '103.0.0.2', '103.0.0.5');

CREATE OR REPLACE FUNCTION announce_route ()
    RETURNS TRIGGER
AS $$
    import json
    import urllib.request
    import sys

    msg = {}
    msg['attr'] = {"1":0, "2":[[2, TD["new"]["as_path"]]], "3":TD["new"]["next_hop"], "5":TD["new"]["local_preference"]}
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

    BOLERO_WITHDRAW = "65535:65433"
    msg = {}
    msg['attr'] = {"1":0, "2":[[2, TD["old"]["as_path"]]], "3":TD["old"]["next_hop"], "5":TD["old"]["local_preference"], "8": [BOLERO_WITHDRAW]}
    msg['withdraw'] = []
    msg['afi_safi'] = "ipv4"
    msg['nlri'] = [TD["old"]["prefix"]]
    json_data = json.dumps(msg)
    plpy.notice("withdraw_route sends msg: {}".format(json_data))

    routerInfo = plpy.execute("SELECT * FROM routers WHERE id = '{}'".format(TD["old"]["target_router"]))
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
    nextHop VARCHAR;
BEGIN
    IF (array_position(NEW.as_path::int[], 2) > 0) THEN
        pref := 1;
    ELSE
        IF pref < 1 THEN
            pref := 100;
        END IF;
    END IF;
    FOR rec IN SELECT id FROM routers LOOP
        IF (rec.id = NEW.local_router) THEN
            nextHop := NEW.next_hop;
        ELSE
            nextHop := (SELECT intf1 FROM links WHERE r1 = NEW.local_router AND r2 = rec.id);
        END IF;
        IF (nextHop IS NOT NULL) THEN
            INSERT INTO rib_out VALUES (NEW.rid, NEW.prefix, pref, NEW.metric, nextHop, NEW.as_path, rec.id);
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS miro ON rib_in;
CREATE TRIGGER miro AFTER INSERT ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE miro();

CREATE OR REPLACE FUNCTION rib_del() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
BEGIN
    DELETE FROM rib_out WHERE rid = OLD.rid;
    RETURN OLD;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS rib_del ON rib_in;
CREATE TRIGGER rib_del AFTER DELETE ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE rib_del();