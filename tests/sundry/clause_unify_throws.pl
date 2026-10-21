% clause/2 and clause/3 went on after unification threw, reading state the throw had reset: a segfault, not the error.

:- initialization(main).
:- dynamic(p/1).
:- dynamic(q/2).

check(Name, Goal) :-
	catch((Goal -> write(Name-ok) ; write(Name-failed)), error(E, _), write(Name-E)), nl.

main :-
	set_prolog_flag(occurs_check, error),
	assertz((p(Y) :- g(Y)), R1),
	assertz(q(Y, f(Y)), R2),
	assertz(q(1, 1)),
	check(clause2_body, clause(p(A), g(f(A)))),
	check(clause3_head, clause(q(B, B), _, _)),
	check(clause3_body, clause(p(C), g(f(C)), _)),
	check(clause3_ref_head, clause(q(D, D), _, R2)),
	check(clause3_ref_body, clause(p(E), g(f(E)), R1)),
	set_prolog_flag(occurs_check, false),
	check(after, (clause(q(1, X), true, _), X == 1)).
