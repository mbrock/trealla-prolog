% Lookups in an indexed dynamic predicate stay right while other threads assert into it: a fact
% is found though keys are inserted before it, and dropping the composite index waits for readers.

:- initialization(main).
:- dynamic(p/1).

main :-
	inserts_before_key,
	composite_dropped.

inserts_before_key :-
	forall(between(1, 1000, I), assertz(p(I))),
	assertz(p(999999999)),
	p(1),
	findall(T, (between(1, 2, N), B is N * 1000000, thread_create(writer(B), T, [])), Ws),
	thread_create(reader(100000), R, []),
	forall(member(T, Ws), thread_join(T, _)),
	thread_join(R, S),
	writeq(inserts_before_key(S)), nl.

writer(Base) :- forall(between(1, 20000, I), (K is Base + I, assertz(p(K)))).
reader(N) :- forall(between(1, N, _), p(999999999)).

composite_dropped :-
	forall(between(1, 30, I), round(I)),
	writeq(composite_dropped), nl.

round(I) :-
	format(atom(P), "q_~w", [I]),
	forall(between(1, 2000, J), (A is J mod 3, B is J mod 3 + (J mod 9) // 3 * 3, C =.. [P, A, B], assertz(C))),
	forall(between(1, 300, _), (call(P, 1, 4) -> true ; true)),
	findall(T, (between(1, 3, _), thread_create(probe(P), T, [])), Ts),
	V =.. [P, _, 5], assertz(V),
	forall(member(T, Ts), thread_join(T, _)).

probe(P) :- forall(between(1, 1000, _), (call(P, 1, 4) -> true ; true)).
