insert into rib_in values(default, '106.0.0.0/16', 0, 0, '10.0.0.2', array[1, 5, 6], '103.0.0.1', '10.0.0.2');
insert into rib_in values(default, '106.0.0.0/16', 0, 0, '10.0.0.10', array[1, 5, 6], '103.0.0.2', '10.0.0.10');
insert into rib_in values(default, '106.0.0.0/16', 0, 0, '10.0.0.6', array[2, 6], '103.0.0.1', '10.0.0.6');
insert into rib_in values(default, '106.0.0.0/16', 0, 0, '10.0.0.14', array[2, 6], '103.0.0.2', '10.0.0.14');
delete from policy;
insert into policy values(1, 'apply_miro');
delete from policy;
insert into policy values(1, 'apply_wiser');
delete from policy;
insert into policy values(1, 'apply_miro_wiser');
select * from policy;
select * from rib_in;
delete from rib_in;
select * from global_routing_information_base order by target_router asc;
select * from local_wiser;
select * from remote_wiser;
select * from peer;
select * from wiser;
select * from igp_cost;
select * from routers;
delete from routers;


