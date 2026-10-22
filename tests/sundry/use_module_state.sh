#!/bin/sh

# Importing a module file already loaded, by its path from another module,
# read it again as a reconsult and so dropped what had been asserted into
# it (#1176). Only consult/1 and make/0 should read it again.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

MOD=tmp_ums_state.pl
OTHER=tmp_ums_other.pl
DRV=tmp_ums_drive.pl

trap "rm -f $MOD $OTHER $DRV" EXIT

printf ':- module(tmp_ums, [state/1, version/1]).\n:- dynamic(state/1).\nversion(1).\n' > $MOD
printf ':- module(tmp_ums_o, []).\n:- use_module(tmp_ums_state).\n' > $OTHER

cat > $DRV <<'EOF'
:- initialization(main).

show(Label) :-
	findall(X, tmp_ums:state(X), Xs),
	findall(V, tmp_ums:version(V), Vs),
	format("~w ~w ~w~n", [Label, Xs, Vs]).

main :-
	use_module(tmp_ums_state),
	assertz(tmp_ums:state(kept)),
	consult(tmp_ums_other), show(other_file),
	absolute_file_name('tmp_ums_state.pl', Path, []),
	format(atom(T1), ':- use_module(~q).', [Path]),
	load_text(T1, [module(tmp_ums_a)]), show(load_text),
	format(atom(T2), ':- use_module(~q, [state/1]).', [Path]),
	load_text(T2, [module(tmp_ums_b)]), show(selective),
	format(atom(T3), ':- ensure_loaded(~q).', [Path]),
	load_text(T3, [module(tmp_ums_c)]), show(ensure_loaded),
	open('tmp_ums_state.pl', write, S),
	write(S, ':- module(tmp_ums, [state/1, version/1]).\n:- dynamic(state/1).\nversion(2).\n'),
	close(S),
	load_text(T1, [module(tmp_ums_d)]), show(changed),
	consult(tmp_ums_state), findall(V, tmp_ums:version(V), Vs), write(consult(Vs)), nl,
	halt.
EOF

timeout 60 $TPL -q $DRV </dev/null 2>&1
