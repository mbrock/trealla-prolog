% erase/1 of a reference whose clause has already gone fails, as in SWI, rather than succeeding
% with nothing erased.

:- initialization(main).
:- dynamic(r/1).

try(Tag, G) :-
	(catch(G, E, (write(Tag-caught(E)), nl, fail)) -> write(Tag-yes) ; write(Tag-no)),
	nl.

main :-
	assertz(r(1)), assertz(r(2)),
	clause(r(1), true, R1), try(first, erase(R1)), try(twice, erase(R1)),
	clause(r(2), true, R2), retract(r(2)), try(after_retract, erase(R2)),
	assertz(r(3)), clause(r(3), true, R3), abolish(r/1), assertz(r(4)), try(after_abolish, erase(R3)),
	findall(X, r(X), L), write(left-L), nl,
	assertz(r(5)), clause(r(5), true, R5), try(live, erase(R5)),
	findall(X, r(X), L2), write(left2-L2), nl.
