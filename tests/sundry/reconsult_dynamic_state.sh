#!/bin/sh

# consult/1 and make/0 reloading a file dropped what had been asserted into
# a dynamic predicate the file declares. As in SWI it stays, after the
# file's clauses, while those are read again, retracted ones included.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

MOD=tmp_rds_mod.pl
USR=tmp_rds_user.pl
DRV=tmp_rds_drive.pl

trap "rm -f $MOD $USR $DRV" EXIT

printf ':- module(tmp_rds, [s/1]).\n:- dynamic(s/1).\n:- assertz(s(dir)).\ns(file).\ns(two).\n' > $MOD
printf ':- dynamic(u/1).\nu(file).\n' > $USR

cat > $DRV <<'EOF'
:- initialization(main).

show(Label) :- findall(X, tmp_rds:s(X), Xs), write(Label-Xs), nl.

main :-
	use_module(tmp_rds_mod),
	retract(tmp_rds:s(two)),
	assertz(tmp_rds:s(kept)),
	consult(tmp_rds_mod), show(consult),
	consult(tmp_rds_mod), show(again),
	forall(tmp_rds:s(X), (X == file -> consult(tmp_rds_mod) ; true)), show(inside),
	consult(tmp_rds_user), assertz(u(kept)), consult(tmp_rds_user),
	findall(U, u(U), Us), write(user-Us), nl,
	sleep(1.1),
	open('tmp_rds_mod.pl', write, S),
	write(S, ':- module(tmp_rds, [s/1]).\n:- dynamic(s/1).\ns(new).\n'),
	close(S),
	make, show(make),
	halt.
EOF

timeout 60 $TPL -q $DRV </dev/null 2>&1 | sed 's|^% .*[/\\]|% |'
