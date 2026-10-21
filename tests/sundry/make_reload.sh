#!/bin/sh

# make/0 reloads what changed, once: a reload left the file's load time
# stale, so every later make/0 reloaded it again. A module file reloaded
# into the module that loaded it, not the module it defines.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

TOP=tmp_make_top.pl
MOD=tmp_make_m.pl
INC=tmp_make_inc.pl
DRV=tmp_make_drive.pl

trap "rm -f $TOP $MOD $INC $DRV" EXIT

printf ':- use_module(tmp_make_m).\np(1).\n' > $TOP
printf ':- module(tmp_make_m, [w/1, i/1]).\n:- include(tmp_make_inc).\nw(a).\nw(b).\n' > $MOD
printf 'i(1).\n' > $INC

cat > $DRV <<'EOF'
:- initialization(main).

edit(F, Text) :- sleep(1.1), open(F, write, S), write(S, Text), close(S).

show(Step) :-
	findall(P, p(P), Ps), findall(W, tmp_make_m:w(W), Ws), findall(I, i(I), Is),
	write(Step-Ps-Ws-Is), nl.

main :-
	consult(tmp_make_top), show(loaded),
	make, show(unchanged),
	edit('tmp_make_m.pl', ':- module(tmp_make_m, [w/1, i/1]).\n:- include(tmp_make_inc).\nw(c).\n'),
	make, show(module_edited),
	make, show(again),
	edit('tmp_make_inc.pl', 'i(2).\n'),
	make, show(include_edited),
	edit('tmp_make_top.pl', ':- use_module(tmp_make_m).\np(2).\n'),
	make, show(top_edited),
	make, show(again),
	halt.
EOF

timeout 60 $TPL -q $DRV </dev/null 2>&1 | sed 's|^% .*/|% |'
