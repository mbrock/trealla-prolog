#!/bin/sh

# make/0 reloading a module file keeps what was asserted into the module
# since, as reloading a user file does, and imports what it newly exports.
# The module's filename stayed its file after loading, so a predicate
# created at runtime counted as from the file and went with the reload.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

MOD=tmp_mms_mod.pl
DRV=tmp_mms_drive.pl

trap "rm -f $MOD $DRV" EXIT

printf ':- module(tmp_mms, [bp/1]).\n:- dynamic(bp/1).\nbp(1).\n' > $MOD

cat > $DRV <<'EOF'
:- initialization(main).

main :-
	use_module(tmp_mms_mod),
	assertz(tmp_mms:extra(1)),
	sleep(1.1),
	open('tmp_mms_mod.pl', write, S),
	write(S, ':- module(tmp_mms, [bp/1, nw/1]).\n:- dynamic(bp/1).\nbp(2).\nnw(new).\n'),
	close(S),
	make,
	findall(X, tmp_mms:bp(X), Xs), write(bp(Xs)), nl,
	( catch(tmp_mms:extra(E), _, fail) -> true ; E = gone ), write(extra(E)), nl,
	G = nw(N), ( catch(G, _, fail) -> true ; N = not_imported ), write(nw(N)), nl,
	halt.
EOF

timeout 60 $TPL -q $DRV </dev/null 2>&1 | sed 's|^% .*[/\\]|% |'
