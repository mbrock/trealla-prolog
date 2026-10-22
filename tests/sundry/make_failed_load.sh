#!/bin/sh

# make/0 reloads a file whose load failed, once it is fixed. It skipped
# every file not loaded at the time, and a failed load leaves its file so.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

SRC=tmp_mfl_src.pl
DRV=tmp_mfl_drive.pl

trap "rm -f $SRC $DRV" EXIT

printf 'cf(broken.\ncf(two).\n' > $SRC

cat > $DRV <<'EOF'
:- initialization(main).

main :-
	catch(consult(tmp_mfl_src), _, true),
	sleep(1.1),
	open('tmp_mfl_src.pl', write, S), write(S, 'cf(fixed).\n'), close(S),
	make,
	( catch(cf(X), _, fail) -> true ; X = not_loaded ),
	write(cf(X)), nl,
	halt.
EOF

# The syntax error's own message names the file by its full path, so it is left out.

timeout 60 $TPL -q $DRV </dev/null 2>&1 | grep -v '^Error:' | sed 's|^% .*[/\\]|% |'
