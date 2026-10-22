#!/bin/sh

# consult/1 of a module file already loaded reads it again, as SWI does.
# Its module/2 directive found the module there and stopped the load, so
# the old clauses stayed. A file consulting itself must still stop.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

MOD=tmp_rcm_mod.pl
SELF=tmp_rcm_self.pl
DRV=tmp_rcm_drive.pl

trap "rm -f $MOD $SELF $DRV" EXIT

printf ':- module(tmp_rcm, [ep/1]).\nep(1).\n' > $MOD
printf ':- module(tmp_rcm_s, [sp/1]).\n:- consult(tmp_rcm_self).\nsp(1).\n' > $SELF

cat > $DRV <<'EOF'
:- initialization(main).

main :-
	consult(tmp_rcm_mod),
	open('tmp_rcm_mod.pl', write, S), write(S, ':- module(tmp_rcm, [ep/1]).\nep(2).\n'), close(S),
	consult(tmp_rcm_mod),
	findall(X, tmp_rcm:ep(X), Xs), write(module(Xs)), nl,
	findall(Y, ep(Y), Ys), write(imported(Ys)), nl,
	use_module(tmp_rcm_self),
	findall(Z, sp(Z), Zs), write(self(Zs)), nl,
	halt.
EOF

timeout 60 $TPL -q $DRV </dev/null 2>&1
