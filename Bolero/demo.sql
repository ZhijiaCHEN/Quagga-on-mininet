DROP TABLE if EXISTS rib_in CASCADE;
create TABLE rib_in(
    rid SERIAL PRIMARY KEY,
    prefix VARCHAR,
    local_preference INTEGER default 100,
    metric INTEGER,
    next_hop VARCHAR,
    as_path INTEGER[],
    local_router VARCHAR,
    remote_router VARCHAR,
    best BOOLEAN DEFAULT FALSE NOT NULL
);

DROP TABLE IF EXISTS rib_out CASCADE;
CREATE TABLE rib_out(
    rid INTEGER,
    prefix VARCHAR,
    local_preference INTEGER default 100,
    metric INTEGER,
    next_hop VARCHAR,
    as_path INTEGER[],
    target_router VARCHAR
);

DROP TABLE IF EXISTS routers CASCADE;
CREATE TABLE routers(
    id VARCHAR PRIMARY KEY,
    api_address VARCHAR,
    api_port VARCHAR
);
INSERT INTO routers VALUES ('103.0.0.1', '103.0.0.10', 8801), ('103.0.0.2', '103.0.0.14', 8801), ('103.0.0.3', '103.0.0.18', 8801);

DROP TABLE IF EXISTS links CASCADE;
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
BEGIN
    IF (array_position(NEW.as_path::int[], 2) > 0) THEN
        NEW.local_preference = 1;
        RETURN NEW;
    ELSE
        NEW.local_preference = 100;
        RETURN NEW;
    END IF;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS miro ON rib_in;
CREATE TRIGGER miro BEFORE INSERT ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE miro();

/* a naive bgp decison procession that only consider local perference and as path length */
CREATE OR REPLACE FUNCTION bgp_decision_process() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    newBest RECORD;
    oldBest RECORD;
    prefix VARCHAR;
    ret RECORD;
BEGIN
    CASE TG_OP /* check triggering event */
        WHEN 'INSERT' THEN
            prefix := NEW.prefix;
            ret := NEW;
        WHEN 'DELETE' THEN
            prefix := OLD.prefix;
            ret := OLD;
    END CASE;

    SELECT * INTO oldBest FROM rib_in WHERE rib_in.prefix = prefix AND best;
    SELECT * INTO newBest FROM rib_in WHERE rib_in.prefix = prefix ORDER BY local_preference DESC, array_length(as_path, 1) ASC LIMIT 1;
    /* warning: a row is null only if every column is null */
    CASE ARRAY[oldBest IS NULL, newBest IS NULL] /* check triggering event */
        WHEN ARRAY[TRUE, FALSE] THEN
            UPDATE rib_in SET best = TRUE WHERE rid = newBest.rid;
        WHEN ARRAY[TRUE, TRUE] THEN
            /* nothing do do */
        WHEN ARRAY[FALSE, FALSE] THEN
            IF (oldBest.rid != newBest.rid) THEN
                UPDATE rib_in SET best = FALSE WHERE rid = oldBest.rid;
                UPDATE rib_in SET best = TRUE WHERE rid = newBest.rid;
            END IF;
        /*WHEN ARRAY[FALSE, TRUE] THEN
            This case should not happen.*/
    END CASE;
    RETURN ret;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION process_withdraw() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
BEGIN
    DELETE FROM rib_out WHERE rid = OLD.rid;
    RETURN OLD;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION bgp_announce_prepare() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    rec RECORD;
    nextHop VARCHAR;
BEGIN
    FOR rec IN SELECT id FROM routers LOOP
        INSERT INTO rib_out VALUES (NEW.rid, NEW.prefix, NEW.local_preference, NEW.metric, NEW.next_hop, NEW.as_path, rec.id);
        /*IF (rec.id = NEW.local_router) THEN
            nextHop := NEW.next_hop;
        ELSE
            nextHop := (SELECT intf1 FROM links WHERE r1 = NEW.local_router AND r2 = rec.id);
        END IF;
        IF (nextHop IS NOT NULL) THEN
            INSERT INTO rib_out VALUES (NEW.rid, NEW.prefix, NEW.local_preference, NEW.metric, nextHop, NEW.as_path, rec.id);
        END IF;*/
    END LOOP;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION bgp_withdraw_prepare() RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM rib_out WHERE rid = OLD.rid;
    RETURN OLD;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS rib_insert ON rib_in;
CREATE TRIGGER rib_insert AFTER INSERT ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE bgp_decision_process();

DROP TRIGGER IF EXISTS rib_predelete ON rib_in;
CREATE TRIGGER rib_predelete BEFORE DELETE ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE process_withdraw();

DROP TRIGGER IF EXISTS rib_delete ON rib_in;
CREATE TRIGGER rib_delete AFTER DELETE ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE bgp_decision_process();

DROP TRIGGER IF EXISTS announce_trigger ON rib_in;
CREATE TRIGGER announce_trigger AFTER UPDATE ON rib_in
    FOR EACH ROW
    WHEN (NOT OLD.best AND NEW.best)
    EXECUTE PROCEDURE bgp_announce_prepare();

DROP TRIGGER IF EXISTS withdraw_trigger ON rib_in;
CREATE TRIGGER withdraw_trigger AFTER UPDATE ON rib_in
    FOR EACH ROW
    WHEN (OLD.best AND NOT NEW.best)
    EXECUTE PROCEDURE bgp_withdraw_prepare();