#
# @TEST-EXEC: bro %INPUT >out
# @TEST-EXEC: btest-diff out
#
# only difference from predicate.bro is, that this one uses a stream source.
# the reason is, that the code-paths are quite different, because then the ascii reader uses the put and not the sendevent interface

@TEST-START-FILE input.log
#separator \x09
#path	ssh
#fields	i	b	
#types	int	bool
1	T
2	T
3	F
4	F
5	F
6	F
7	T
@TEST-END-FILE

redef InputAscii::empty_field = "EMPTY";

module A;

type Idx: record {
	i: int;
};

type Val: record {
	b: bool;
};

global servers: table[int] of Val = table();
global ct: int;

event line(description: Input::TableDescription, tpe: Input::Event, left: Idx, right: bool) {
	ct = ct + 1;
	if ( ct < 3 ) {
		return;
	}
	if ( ct > 3 ) {
		print "Too many events";
		return;
	}

	if ( 1 in servers ) {
		print "VALID";
	}
	if ( 2 in servers ) {
		print "VALID";
	}
	if ( !(3 in servers) ) {
		print "VALID";
	}
	if ( !(4 in servers) ) {
		print "VALID";
	}
	if ( !(5 in servers) ) {
		print "VALID";
	}
	if ( !(6 in servers) ) {
		print "VALID";
	}
	if ( 7 in servers ) {
		print "VALID";
	}
}

event bro_init()
{
	ct = 0;
	# first read in the old stuff into the table...
	Input::add_table([$source="input.log", $mode=Input::STREAM, $name="input", $idx=Idx, $val=Val, $destination=servers, $want_record=F, $ev=line,
				$pred(typ: Input::Event, left: Idx, right: bool) = { return right; }
				]);
	Input::remove("input");

}

