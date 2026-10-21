% Issue #1173: making modules grew the module map with realloc while
% another thread, returning from a call, looked its own module up there.

:- initialization(main).

loop(0) :- !.
loop(N) :- append([a,b], [c,d], L), length(L, 4), N1 is N-1, loop(N1).

main :-
	thread_self(Main),
	thread_create((thread_send_message(Main, ready), loop(400000)), T, []),
	thread_get_message(ready),
	forall(between(1, 4000, I), (format(atom(M), 'mm_~w', [I]), '$create_module'(M))),
	thread_join(T, S),
	writeq(S), nl.
