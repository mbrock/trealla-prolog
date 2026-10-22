#!/bin/sh

# A relative consult/1 run by a module's predicate after loading resolves
# against the working directory, as SWI does, not the module's own file:
# the module's filename stayed that file once its load was done.

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

DIR=tmp_rcb_sub
DRV=tmp_rcb_drive.pl

trap "rm -rf $DIR $DRV tmp_rcb_data.pl" EXIT

mkdir -p $DIR
printf ':- module(tmp_rcb, [go/0]).\ngo :- consult(tmp_rcb_data).\n' > $DIR/tmp_rcb_mod.pl
printf 'where(sub).\n' > $DIR/tmp_rcb_data.pl
printf 'where(cwd).\n' > tmp_rcb_data.pl
printf ":- use_module('tmp_rcb_sub/tmp_rcb_mod').\n" > $DRV

timeout 60 $TPL -q $DRV -g "go,tmp_rcb:where(W),write(W),nl,halt" </dev/null 2>&1
