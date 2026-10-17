% A clause another query reclaims while this one still reads it, runs it or is bound into it. The
% engine or thread doing it ends first, and what it reclaimed must not go with it.

:- initialization(main).
:- dynamic(p/1).
:- dynamic(r/0).
:- dynamic(s/1).

reset :-
	retractall(p(_)), assertz(p(1)), assertz(p(2)), assertz(p(3)),
	retractall(s(_)), assertz(s(f(abc, [1,2,3]))).

in_engine(G) :- engine_create(x, G, E), engine_next(E, _), engine_destroy(E).
in_thread(G) :- thread_create(G, Id, []), thread_join(Id, _).

abolish_under_choicepoint(Run) :-
	reset,
	findall(X, (p(X), (X == 1 -> call(Run, abolish(p/1)) ; true)), L),
	write(L), nl.

abolish_running_body :-
	assertz((r :- in_engine(abolish(r/0)), atom_length(abcdef, L), X = f(L, g(h, [1,2,3])), write(X), nl)),
	r.

retract_bound_into(Run) :-
	reset,
	s(X), call(Run, retract(s(_))), atom_length(xyzzy, _),
	write(X), nl.

flags_while_enumerating :-
	forall(current_prolog_flag(F, _), (F == bounded -> in_engine(current_prolog_flag(_, _)) ; true)),
	write(ok), nl.

main :-
	abolish_under_choicepoint(in_engine),
	abolish_under_choicepoint(in_thread),
	abolish_running_body,
	retract_bound_into(in_engine),
	retract_bound_into(in_thread),
	flags_while_enumerating.
