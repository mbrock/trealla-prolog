#!/bin/sh

# make/0 sees an edit made in the same second the file was loaded. It
# compared the file's mtime with the time of loading, to the second, so
# only a later second counted; now any change from the loaded mtime does.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

SRC=tmp_mss_src.pl
DRV=tmp_mss_drive.pl

trap "rm -f $SRC $DRV" EXIT

printf 'ss(old).\n' > $SRC
touch -t 202001010000 $SRC

cat > $DRV <<'EOF'
:- initialization(main).

main :-
	consult(tmp_mss_src),
	open('tmp_mss_src.pl', write, S), write(S, 'ss(new).\n'), close(S),
	make,
	findall(X, ss(X), Xs), write(Xs), nl,
	halt.
EOF

timeout 60 $TPL -q $DRV </dev/null 2>&1 | sed 's|^% .*[/\\]|% |'
