#!/bin/sh

# make/0 leaves a file unload_files/1 took out alone, as SWI's make/0
# does, and follows it again once it is consulted again. It reloaded any
# file changed since its last load, unloaded or not.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

SRC=tmp_mau_src.pl
DRV=tmp_mau_drive.pl

trap "rm -f $SRC $DRV" EXIT

printf 'uf(1).\n' > $SRC

cat > $DRV <<'EOF'
:- initialization(main).

edit(Text) :- sleep(1.1), open('tmp_mau_src.pl', write, S), write(S, Text), close(S).

show(Step) :- findall(X, catch(uf(X), _, fail), Xs), write(Step-Xs), nl.

main :-
	consult(tmp_mau_src), show(loaded),
	unload_files(tmp_mau_src), show(unloaded),
	edit('uf(2).\n'), make, show(make_after_unload),
	consult(tmp_mau_src), show(consulted_again),
	edit('uf(3).\n'), make, show(make_after_consult),
	halt.
EOF

timeout 60 $TPL -q $DRV </dev/null 2>&1 | sed 's|^% .*[/\\]|% |'
