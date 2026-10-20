#!/bin/sh

# A thread gets an 8MB stack whatever the main one has, so its depth limit must come from that: with ulimit -s raised, a deep write or evaluation in a thread, or in an engine a thread ran, crashed

TPL=${TPL:-./tpl}

# In the current directory, not mktemp: the WASM runner's wasmtime only sees '.'.

TMPPL=tmp_thread_deep_stack.pl

trap "rm -f $TMPPL" EXIT

cat > $TMPPL <<'EOF'
nest(0, z) :- !.
nest(N, f(G)) :- N1 is N-1, nest(N1, G).
lsum(0, 1) :- !.
lsum(N, G+1) :- N1 is N-1, lsum(N1, G).

% Either outcome depends on the stack size; a crash is the failure
wrote(Where, T) :-
	catch((with_output_to(atom(A), writeq(T)), \+ sub_atom(A, _, _, _, '...'), R = ok), error(resource_error(stack), _), R = ok),
	format("~w write: ~w~n", [Where, R]).
evaluated(Where, E) :-
	catch((_ is E, R = ok), error(type_error(evaluable, _), _), R = ok),
	format("~w is: ~w~n", [Where, R]).

deep(Where) :-
	nest(100000, F), wrote(Where, F),
	lsum(100000, E), evaluated(Where, E).

main :-
	deep(main),
	(   catch(thread_create(deep(thread), Id, []), _, fail)
	->  thread_join(Id, St)
	;   deep(thread), St = true
	),
	format("thread exit: ~w~n", [St]),
	% An engine made here runs on the stack of whoever asks it for an answer
	engine_create(x, deep(engine), E),
	(   catch(thread_create(engine_next(E, _), Id2, []), _, fail)
	->  thread_join(Id2, St2)
	;   engine_next(E, _), St2 = true
	),
	format("engine exit: ~w~n", [St2]).
EOF

# The bigger the main stack the more a thread was trusted with; unlimited also tests the cap
ulimit -s unlimited 2>/dev/null || ulimit -s 65520 2>/dev/null

$TPL -q -g main,halt $TMPPL
