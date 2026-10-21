% clause/3 resolved the stored clause's variables in the caller's frame: by reference its head
% bound to the caller's first variable (a cycle when that held the goal, so writeq/1 never ended),
% and with the reference unbound the body was not linked to the head.

:- initialization(main).
:- dynamic(p/1).
:- dynamic(q/1).
:- dynamic(r/2).
:- dynamic(t/2).

check(Name, Goal) :-
	(catch(Goal, E, (write(Name-E), nl, fail)) -> write(Name-ok) ; write(Name-failed)), nl.

main :-
	G = (assertz(p(_), R), clause(p(A), _, R)),
	check(ref_head, (call(G), var(A), acyclic_term(G))),
	assertz((q(X) :- foo(X, _))),
	check(var_ref_body, (clause(q(H), B, _), B = foo(H1, _), H1 == H)),
	assertz((r(X, Z) :- foo(X, _, Z)), R2),
	check(ref_rule, (clause(r(P, Q), foo(P1, _, Q1), R2), P1 == P, Q1 == Q)),
	assertz(t(X, X), R3),
	check(ref_shared, (clause(t(C, D), true, R3), C == D, var(C))),
	check(ref_mismatch, \+ (assertz(p(1), R4), clause(p(2), _, R4))).
