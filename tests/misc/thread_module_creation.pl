% A thread's query has no parser, so making a new module there must not read one (#1177).
% The module names come in as variables so compiling this file does not make them first.

:- initialization(main).

load(M) :-
	atom_chars('probe(ok).', Cs),
	load_text(Cs, [module(M)]),
	call(M:probe(ok)).

switch(M) :-
	'$module'(M),
	assertz(M:probe(ok)),
	call(M:probe(ok)).

in_thread(G, M) :-
	thread_create(call(G, M), T, []),
	thread_join(T, S),
	findall(X, call(M:probe(X)), Xs),
	write(G-M-S-Xs), nl.

main :-
	in_thread(load, tmc_load),
	in_thread(switch, tmc_switch),
	load(tmc_main_load), write(main(load)), nl,
	switch(tmc_main_switch), write(main(switch)), nl.
