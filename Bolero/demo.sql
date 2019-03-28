DROP TABLE if EXISTS rib_in CASCADE;
CREATE TABLE rib_in(
    rid SERIAL PRIMARY KEY,
    prefix VARCHAR,
    local_preference INTEGER default 100,
    metric INTEGER DEFAULT 0,
    next_hop VARCHAR,
    as_path INTEGER[],
    local_router VARCHAR,
    remote_router VARCHAR
);

DROP TABLE IF EXISTS global_routing_information_base CASCADE;
CREATE TABLE global_routing_information_base(
    rid INTEGER,
    prefix VARCHAR,
    local_preference INTEGER,
    metric INTEGER,
    next_hop VARCHAR,
    as_path INTEGER[],
    igp_cost INTEGER,
    source_router VARCHAR,
    target_router VARCHAR,
    is_best BOOLEAN DEFAULT FALSE NOT NULL
);



DROP TABLE IF EXISTS igp_cost CASCADE;
CREATE TABLE igp_cost(
    source_router VARCHAR,
    destination_router VARCHAR,
    cost INTEGER,
    path VARCHAR[]
);
INSERT INTO igp_cost VALUES
('103.0.0.1', '103.0.0.2', 4, ARRAY['103.0.0.1', '103.0.0.6', '103.0.0.2']), ('103.0.0.2', '103.0.0.1', 4, ARRAY['103.0.0.2', '103.0.0.6', '103.0.0.1']), 
('103.0.0.1', '103.0.0.3', 5, ARRAY['103.0.0.1', '103.0.0.6', '103.0.0.3']), ('103.0.0.3', '103.0.0.1', 5, ARRAY['103.0.0.3', '103.0.0.6', '103.0.0.1']), 
('103.0.0.1', '103.0.0.4', 8, ARRAY['103.0.0.1', '103.0.0.6', '103.0.0.4']), ('103.0.0.4', '103.0.0.1', 8, ARRAY['103.0.0.4', '103.0.0.6', '103.0.0.1']), 
('103.0.0.1', '103.0.0.5', 15, ARRAY['103.0.0.1', '103.0.0.6', '103.0.0.5']), ('103.0.0.5', '103.0.0.1', 15, ARRAY['103.0.0.5', '103.0.0.6', '103.0.0.1']), 
('103.0.0.1', '103.0.0.6', 3, ARRAY['103.0.0.1', '103.0.0.6']), ('103.0.0.6', '103.0.0.1', 3, ARRAY['103.0.0.6', '103.0.0.1']), 

('103.0.0.2', '103.0.0.3', 3, ARRAY['103.0.0.2', '103.0.0.6', '103.0.0.3']), ('103.0.0.3', '103.0.0.2', 3, ARRAY['103.0.0.3', '103.0.0.6', '103.0.0.2']), 
('103.0.0.2', '103.0.0.4', 6, ARRAY['103.0.0.2', '103.0.0.6', '103.0.0.4']), ('103.0.0.4', '103.0.0.2', 6, ARRAY['103.0.0.4', '103.0.0.6', '103.0.0.2']), 
('103.0.0.2', '103.0.0.5', 13, ARRAY['103.0.0.2', '103.0.0.6', '103.0.0.5']), ('103.0.0.5', '103.0.0.2', 13, ARRAY['103.0.0.5', '103.0.0.6', '103.0.0.2']), 
('103.0.0.2', '103.0.0.6', 1, ARRAY['103.0.0.2', '103.0.0.6']), ('103.0.0.6', '103.0.0.2', 1, ARRAY['103.0.0.6', '103.0.0.2']), 

('103.0.0.3', '103.0.0.4', 7, ARRAY['103.0.0.3', '103.0.0.6', '103.0.0.4']), ('103.0.0.4', '103.0.0.3', 7, ARRAY['103.0.0.4', '103.0.0.6', '103.0.0.3']), 
('103.0.0.3', '103.0.0.5', 14, ARRAY['103.0.0.3', '103.0.0.6', '103.0.0.5']), ('103.0.0.5', '103.0.0.3', 14, ARRAY['103.0.0.5', '103.0.0.6', '103.0.0.3']), 
('103.0.0.3', '103.0.0.6', 2, ARRAY['103.0.0.3', '103.0.0.6']), ('103.0.0.6', '103.0.0.3', 2, ARRAY['103.0.0.6', '103.0.0.3']), 

('103.0.0.4', '103.0.0.5', 17, ARRAY['103.0.0.4', '103.0.0.6', '103.0.0.5']), ('103.0.0.5', '103.0.0.4', 17, ARRAY['103.0.0.5', '103.0.0.6', '103.0.0.4']), 
('103.0.0.4', '103.0.0.6', 5, ARRAY['103.0.0.4', '103.0.0.6']), ('103.0.0.6', '103.0.0.4', 5, ARRAY['103.0.0.6', '103.0.0.4']), 

('103.0.0.5', '103.0.0.6', 12, ARRAY['103.0.0.5', '103.0.0.6']), ('103.0.0.6', '103.0.0.5', 12, ARRAY['103.0.0.6', '103.0.0.5']);

DROP TABLE IF EXISTS routers CASCADE;
CREATE TABLE routers(
    id VARCHAR PRIMARY KEY,
    api_address VARCHAR,
    api_port VARCHAR
);
INSERT INTO routers VALUES ('103.0.0.1', '103.0.0.10', 8801), ('103.0.0.2', '103.0.0.14', 8801), ('103.0.0.3', '103.0.0.18', 8801), ('103.0.0.4', '103.0.0.14', 8801), ('103.0.0.5', '103.0.0.18', 8801), ('103.0.0.6', '103.0.0.14', 8801);

DROP TABLE IF EXISTS border CASCADE;
CREATE TABLE border(
    router VARCHAR PRIMARY KEY
);
INSERT INTO border VALUES ('103.0.0.1'), ('103.0.0.2'), ('103.0.0.3'), ('103.0.0.4'), ('103.0.0.5');

DROP TABLE IF EXISTS links CASCADE;
CREATE TABLE links(
    r1 VARCHAR,
    intf1 VARCHAR,
    r2 VARCHAR,
    intf2 VARCHAR,
    cost INT
);

INSERT INTO links VALUES('103.0.0.1', '103.0.0.1', '103.0.0.6', '103.0.0.2', 3), ('103.0.0.6', '103.0.0.2', '103.0.0.1', '103.0.0.1', 3), ('103.0.0.2', '103.0.0.5', '103.0.0.6', '103.0.0.6', 1), ('103.0.0.6', '103.0.0.6', '103.0.0.2', '103.0.0.5', 1), ('103.0.0.3', '103.0.0.10', '103.0.0.6', '103.0.0.9', 2), ('103.0.0.6', '103.0.0.9', '103.0.0.3', '103.0.0.10', 2), ('103.0.0.4', '103.0.0.14', '103.0.0.6', '103.0.0.13', 5), ('103.0.0.6', '103.0.0.13', '103.0.0.4', '103.0.0.14', 5), ('103.0.0.5', '103.0.0.18', '103.0.0.6', '103.0.0.17', 12), ('103.0.0.6', '103.0.0.17', '103.0.0.5', '103.0.0.18', 12);

DROP TABLE IF EXISTS wiser CASCADE;
CREATE TABLE wiser(
    rid INTEGER REFERENCES rib_in(rid) ON DELETE CASCADE,
    peering_router VARCHAR,
    cost INTEGER,
    path VARCHAR[]
);

DROP TABLE IF EXISTS advertise;
CREATE TABLE advertise(
    peering_router VARCHAR,
    cost INT
);
INSERT INTO advertise VALUES ('103.0.0.3', 40), ('103.0.0.4', 20), ('103.0.0.5', 10);

DROP TABLE IF EXISTS best_join_cost;
CREATE TABLE best_join_cost(
    rid INTEGER REFERENCES rib_in(rid) ON DELETE CASCADE,
    prefix VARCHAR,
    cost INTEGER,
    path VARCHAR[]
);

DROP TABLE IF EXISTS policy;
CREATE TABLE policy(
    execution_order INTEGER,
    policy_function VARCHAR
);

DROP TABLE IF EXISTS min_traverse_cost CASCADE;
CREATE TABLE min_traverse_cost(
    source_router VARCHAR,
    path VARCHAR[],
    cost INTEGER
);
INSERT INTO min_traverse_cost SELECT source_router, path, cost FROM igp_cost WHERE source_router IN (SELECT router FROM border) AND destination_router IN (SELECT router FROM border) AND (source_router != destination_router) ORDER BY source_router, cost ASC;
DELETE FROM min_traverse_cost tmp1 WHERE cost > (SELECT min(cost) FROM min_traverse_cost WHERE min_traverse_cost.source_router = tmp1.source_router);

DROP TABLE IF EXISTS hot_potato_path CASCADE;
CREATE TABLE hot_potato_path(
    rid INTEGER REFERENCES rib_in(rid) ON DELETE CASCADE,
    prefix VARCHAR,
    source_router VARCHAR,
    path VARCHAR[],
    cost INTEGER
);

DROP FUNCTION IF EXISTS clear_rib();
CREATE FUNCTION clear_rib() RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM rib_in;
    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS change_policy ON policy;
CREATE TRIGGER change_policy AFTER INSERT OR DELETE OR UPDATE ON policy
    FOR EACH ROW
    EXECUTE PROCEDURE clear_rib();

DROP FUNCTION IF EXISTS distribute_route(NEW rib_in);
CREATE FUNCTION distribute_route(NEW rib_in) RETURNS rib_in AS
$$
#variable_conflict use_variable
DECLARE
    router VARCHAR;
    cost INTEGER;
BEGIN
    /* FIX ME use join to improve performance */
    FOR router IN SELECT id FROM routers LOOP
        cost := (SELECT igp_cost.cost FROM igp_cost WHERE source_router = router AND destination_router = NEW.local_router);
        IF cost IS NULL THEN
            cost := 0;
        END IF;

        IF (NEW.local_preference = 0) OR (NEW.local_preference IS NULL) THEN
            NEW.local_preference = 100;
        END IF;
        INSERT INTO global_routing_information_base(source_router, target_router, rid, prefix, local_preference, metric, next_hop, as_path, igp_cost) VALUES (NEW.local_router, router, NEW.rid, NEW.prefix, NEW.local_preference, NEW.metric, NEW.next_hop, NEW.as_path, cost);
    END LOOP;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS prepare_route();
CREATE FUNCTION prepare_route() RETURNS TRIGGER AS
$$
BEGIN
    RETURN distribute_route(NEW);
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS insert_route ON rib_in;
CREATE TRIGGER insert_route AFTER INSERT OR UPDATE ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE prepare_route();

DROP FUNCTION IF EXISTS remove_route();
CREATE FUNCTION remove_route() RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM global_routing_information_base WHERE rid = OLD.rid;
    RETURN OLD;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS delete_route ON rib_in;
CREATE TRIGGER delete_route AFTER DELETE ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE remove_route();

DROP FUNCTION IF EXISTS prepare_wiser();
CREATE FUNCTION prepare_wiser () RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT source_router AS ingress, destination_router AS egress, cost, path FROM igp_cost WHERE source_router = NEW.local_router AND destination_router IN (SELECT peering_router FROM advertise) LOOP
        INSERT INTO wiser(rid, peering_router, cost, path) VALUES (NEW.rid, rec.egress, rec.cost, rec.path);
    END LOOP;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS a_prepare_wiser ON rib_in;
CREATE TRIGGER a_prepare_wiser AFTER INSERT ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE prepare_wiser();

DROP FUNCTION IF EXISTS apply_miro(NEW global_routing_information_base);
CREATE FUNCTION apply_miro(NEW global_routing_information_base) RETURNS global_routing_information_base AS
$$
BEGIN
    IF (array_position(NEW.as_path::int[], 2) > 0) THEN
        raise notice 'miro return NULL';
        RETURN NULL;
        /* NEW.local_preference = 1; */
    END IF;
    raise notice 'miro return %', NEW;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS prepare_hot_potato();
CREATE FUNCTION prepare_hot_potato() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    currentMin INTEGER;
    newMIN INTEGER;
    rec RECORD;
BEGIN
    SELECT min(cost) INTO newMIN FROM min_traverse_cost WHERE source_router = NEW.source_router LIMIT 1;
    SELECT cost into currentMin FROM hot_potato_path WHERE prefix = NEW.prefix LIMIT 1;
    IF (newMIN <= currentMin) THEN
        IF (newMIN < currentMin) THEN
            DELETE FROM hot_potato_path WHERE prefix = NEW.prefix;
        END IF;
        FOR rec IN SELECT path, cost FROM min_traverse_cost WHERE source_router = NEW.source_router AND cost <= newMIN LOOP
            INSERT INTO hot_potato_path VALUES(NEW.rid, NEW.prefix, NEW.source_router, rec.path, rec.cost);
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS a_prepare_hot_potato ON rib_in;
CREATE TRIGGER a_prepare_hot_potato AFTER INSERT ON rib_in
    FOR EACH ROW
    EXECUTE PROCEDURE prepare_hot_potato();


DROP FUNCTION IF EXISTS apply_hot_potato(NEW global_routing_information_base);
CREATE FUNCTION apply_hot_potato(NEW global_routing_information_base) RETURNS global_routing_information_base AS
$$
#variable_conflict use_variable
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT source_router, path FROM hot_potato_path WHERE prefix = NEW.prefix LOOP
        IF (NEW.source_router != rec.source_router) OR (array_position(rec.path::VARCHAR[], NEW.target_router) IS NULL) THEN
            RETURN NULL;
        ELSE
            RETURN NEW;
        END IF;
    END LOOP;
END;
$$
LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS apply_hot_potato_delete();
CREATE FUNCTION apply_hot_potato() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    rec RECORD;
    ri RECORD;
BEGIN
    FOR ri IN SELECT source_router, cost FROM min_traverse_cost LOOP
        SELECT * INTO rec FROM rib_in WHERE prefix = OLD.prefix AND source_router = ri.source_router;
        IF (rec IS NOT NULL) THEN
            UPDATE rib_in SET rid = rid WHERE rid = rec.rid;
            BREAK;
        END IF;
    END LOOP;
    RETURN OLD;
END;
$$
LANGUAGE PLPGSQL;

/*
DROP TRIGGER IF EXISTS fire_miro ON global_routing_information_base;
CREATE TRIGGER fire_miro BEFORE INSERT ON global_routing_information_base
    FOR EACH ROW
    EXECUTE PROCEDURE apply_miro();
*/

DROP FUNCTION IF EXISTS apply_wiser(NEW global_routing_information_base);
CREATE FUNCTION apply_wiser(NEW global_routing_information_base) RETURNS global_routing_information_base AS
$$
#variable_conflict use_variable
DECLARE
    min_cost_route RECORD;
    ret global_routing_information_base%ROWTYPE;
    i RECORD;
BEGIN
    /* first check if the target is in the minimum wiser cost + avertise cost path */
    WITH join_cost AS (SELECT rid, (wiser.cost + advertise.cost) AS cost, path FROM wiser JOIN advertise ON wiser.peering_router = advertise.peering_router ORDER BY cost ASC) SELECT * INTO min_cost_route FROM join_cost LIMIT 1;
    IF (NEW.rid != min_cost_route.rid) OR (array_position(min_cost_route.path::VARCHAR[], NEW.target_router::VARCHAR) IS NULL) THEN
        ret = NULL;
    ELSE
        INSERT INTO best_join_cost(rid, prefix, cost, path) VALUES (min_cost_route.rid, NEW.prefix, min_cost_route.cost, min_cost_route.path);
        ret = NEW;
    END IF;

    /* The new route may invalidate an old route that has the target route in the path */
    FOR i IN SELECT * FROM best_join_cost WHERE prefix = NEW.prefix LOOP
        IF (i.cost > min_cost_route.cost) THEN
            DELETE FROM global_routing_information_base WHERE rid = i.rid;
        END IF;
    END LOOP;

    RETURN ret;
END;
$$
LANGUAGE PLPGSQL;

/*
DROP TRIGGER IF EXISTS fire_wiser ON global_routing_information_base;
CREATE TRIGGER fire_wiser BEFORE INSERT ON global_routing_information_base
    FOR EACH ROW
    EXECUTE PROCEDURE apply_wiser();
*/

DROP FUNCTION IF EXISTS apply_policy();
CREATE FUNCTION apply_policy() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    pf VARCHAR;
    ret RECORD;
BEGIN
    ret := NEW;
    FOR pf IN SELECT policy_function FROM policy ORDER BY execution_order ASC LOOP
        EXECUTE format('SELECT * FROM %s($1)', pf) USING NEW INTO ret;
        IF ret IS NULL THEN
            RETURN NULL; /* Somehow the ret cannot halt the trigger even if it is NULL */ 
        END IF;
    END LOOP;
    RETURN ret;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS fire_policy ON global_routing_information_base;
CREATE TRIGGER fire_policy BEFORE INSERT ON global_routing_information_base
    FOR EACH ROW
    EXECUTE PROCEDURE apply_policy();

/* a naive bgp decison procession that only consider local perference, AS path length, metric and IGP cost */
DROP FUNCTION IF EXISTS bgp_decision_process();
CREATE FUNCTION bgp_decision_process() RETURNS TRIGGER AS
$$
#variable_conflict use_variable
DECLARE
    newBest RECORD;
    oldBest RECORD;
    rec RECORD;
BEGIN
    CASE TG_OP /* check triggering event */
        WHEN 'INSERT' THEN
            rec := NEW;
        WHEN 'DELETE' THEN
            rec := OLD;
    END CASE;

    SELECT * INTO oldBest FROM global_routing_information_base WHERE target_router = rec.target_router AND prefix = rec.prefix AND is_best;
    SELECT * INTO newBest FROM global_routing_information_base WHERE target_router = rec.target_router AND prefix = rec.prefix ORDER BY local_preference DESC, array_length(as_path, 1) ASC, metric ASC, igp_cost ASC LIMIT 1;
    /* warning: a row is null only if every column is null */
    CASE ARRAY[oldBest IS NULL, newBest IS NULL] /* check triggering event */
        WHEN ARRAY[TRUE, FALSE] THEN
            UPDATE global_routing_information_base SET is_best = TRUE WHERE target_router = rec.target_router AND rid = newBest.rid;
        WHEN ARRAY[TRUE, TRUE] THEN
            /* nothing do do */
        WHEN ARRAY[FALSE, FALSE] THEN
            IF (oldBest.rid != newBest.rid) THEN
                UPDATE global_routing_information_base SET is_best = FALSE WHERE target_router = rec.target_router AND rid = oldBest.rid;
                UPDATE global_routing_information_base SET is_best = TRUE WHERE target_router = rec.target_router AND rid = newBest.rid;
            END IF;
        /*WHEN ARRAY[FALSE, TRUE] THEN
            This case should not happen.*/
    END CASE;
    RETURN rec;
END;
$$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS add_route ON global_routing_information_base;
CREATE TRIGGER add_route AFTER INSERT ON global_routing_information_base
    FOR EACH ROW
    EXECUTE PROCEDURE bgp_decision_process();

DROP TRIGGER IF EXISTS remove_route ON global_routing_information_base;
CREATE TRIGGER remove_route AFTER DELETE ON global_routing_information_base
    FOR EACH ROW
    EXECUTE PROCEDURE bgp_decision_process();

DROP FUNCTION IF EXISTS announce_route();
CREATE FUNCTION announce_route ()
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
    try:
        res = json.loads(opener.open(request, timeout=1).read())
        plpy.notice("announcement returns: {}".format(res))
    except Exception as e:
        plpy.notice("Announcement prefix {} to router {} failed: {}".format(TD["new"]["prefix"], TD["new"]["target_router"], str(e)))
$$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS new_best ON global_routing_information_base;
CREATE TRIGGER new_best AFTER UPDATE ON global_routing_information_base
    FOR EACH ROW
    WHEN (NOT OLD.is_best AND NEW.is_best)
    EXECUTE PROCEDURE announce_route();

DROP FUNCTION IF EXISTS withdraw_route();
CREATE FUNCTION withdraw_route ()
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
    try:
        res = json.loads(opener.open(request, timeout=1).read())
        plpy.notice("withdraw_route returns: {}".format(res))
    except Exception as e:
        plpy.notice("Withdraw prefix {} from router {} failed: {}".format(TD["old"]["prefix"], TD["old"]["target_router"], str(e)))
$$ LANGUAGE plpython3u;

DROP TRIGGER IF EXISTS old_best ON global_routing_information_base;
CREATE TRIGGER old_best AFTER UPDATE ON global_routing_information_base
    FOR EACH ROW
    WHEN (OLD.is_best AND NOT NEW.is_best)
    EXECUTE PROCEDURE withdraw_route();

DROP TRIGGER IF EXISTS withdraw_route ON global_routing_information_base;
CREATE TRIGGER withdraw_route AFTER DELETE ON global_routing_information_base
    FOR EACH ROW
    EXECUTE PROCEDURE withdraw_route();