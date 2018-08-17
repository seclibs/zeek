# @TEST-SERIALIZE: comm
#
# @TEST-EXEC: btest-bg-run manager-1 BROPATH=$BROPATH:.. CLUSTER_NODE=manager-1 bro %INPUT
# @TEST-EXEC: btest-bg-run worker-1  BROPATH=$BROPATH:.. CLUSTER_NODE=worker-1 bro %INPUT
# @TEST-EXEC: btest-bg-run worker-2  BROPATH=$BROPATH:.. CLUSTER_NODE=worker-2 bro %INPUT
# @TEST-EXEC: btest-bg-wait 15

# @TEST-EXEC: btest-diff manager-1/.stdout
#

@TEST-START-FILE cluster-layout.bro
redef Cluster::nodes = {
	["manager-1"] = [$node_type=Cluster::MANAGER, $ip=127.0.0.1, $p=37757/tcp],
	["worker-1"]  = [$node_type=Cluster::WORKER,  $ip=127.0.0.1, $p=37760/tcp, $manager="manager-1", $interface="eth0"],
	["worker-2"]  = [$node_type=Cluster::WORKER,  $ip=127.0.0.1, $p=37761/tcp, $manager="manager-1", $interface="eth1"],
};
@TEST-END-FILE

redef Log::default_rotation_interval = 0secs;

global n = 0;

event bro_init() &priority=5
	{
	local r1 = SumStats::Reducer($stream="test", $apply=set(SumStats::SUM, SumStats::MIN, SumStats::MAX, SumStats::AVERAGE, SumStats::STD_DEV, SumStats::VARIANCE, SumStats::UNIQUE));
	SumStats::create([$name="test sumstat",
	                  $epoch=1hr,
	                  $reducers=set(r1)]);
	}

event Broker::peer_lost(endpoint: Broker::EndpointInfo, msg: string)
	{
	terminate();
	}

global ready_for_data: event();

event bro_init()
	{
	Broker::auto_publish(Cluster::worker_topic, ready_for_data);
	}

event on_demand()
	{
	local host = 7.2.1.5;
	when ( local result = SumStats::request_key("test sumstat", [$host=host]) )
		{
		print "SumStat key request";
		if ( "test" in result )
			print fmt("    Host: %s -> %.0f", host, result["test"]$sum);

		if ( Cluster::node == "manager-1" )
		  terminate();
		}
	}

event ready_for_data()
	{
	if ( Cluster::node == "worker-1" )
		{
		SumStats::observe("test", [$host=1.2.3.4], [$num=34]);
		SumStats::observe("test", [$host=1.2.3.4], [$num=30]);
		SumStats::observe("test", [$host=6.5.4.3], [$num=1]);
		SumStats::observe("test", [$host=7.2.1.5], [$num=54]);
		}
	if ( Cluster::node == "worker-2" )
		{
		SumStats::observe("test", [$host=1.2.3.4], [$num=75]);
		SumStats::observe("test", [$host=1.2.3.4], [$num=30]);
		SumStats::observe("test", [$host=7.2.1.5], [$num=91]);
		SumStats::observe("test", [$host=10.10.10.10], [$num=5]);
		}

	schedule 1sec { on_demand() };
	}

global peer_count = 0;
event Broker::peer_added(endpoint: Broker::EndpointInfo, msg: string)
	{
	if ( Cluster::node != "manager-1" )
		return;

	++peer_count;
	if ( peer_count == 2 )
		{
		event ready_for_data();
		}
	}

