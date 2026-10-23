% An atom built at run time (atom_chars/2, atom_codes/2, atom_concat/3,
% sub_atom/5) is a TAG_CSTR cell, not an interned one. Unifying it with a
% compound compared only the names, so atom_chars(A, "foo"), A = foo(_)
% succeeded, and such an atom matched clause heads of any arity.

h(foo(_)).
h(foo(_, _)).

p(foo(_), compound).
p(foo, atom).

:- dynamic(big/2).

:- initialization(main).

main :-
	forall(between(1, 600, N), assertz(big(foo(N), N))),
	assertz(big(foo, atom)),
	atom_chars(A, "foo"),
	atom_codes(B, [0'f,0'o,0'o]),
	atom_concat(fo, o, C),
	sub_atom(xfoox, 1, 3, _, D),
	atom_chars(L, "a_name_too_long_to_fit_inside_a_cell"),
	LT =.. [L, x],
	check(literal, \+ foo = foo(_)),
	check(atom_chars, \+ A = foo(_)),
	check(atom_codes, \+ B = foo(_)),
	check(atom_concat, \+ C = foo(_, _, _)),
	check(sub_atom, \+ D = foo(_)),
	check(long_name, \+ L = LT),
	check(nested, \+ f(A) = f(foo(_))),
	check(list, \+ [A] = [foo(_)]),
	check(not_unify, A \= foo(_)),
	check(occurs_check, \+ unify_with_occurs_check(A, foo(_))),
	check(subsumes, \+ subsumes_term(A, foo(_))),
	check(head, \+ h(A)),
	check(head_atom, findall(W, p(A, W), [atom])),
	check(indexed, findall(W, big(A, W), [atom])),
	check(still_atom, (A = foo, B = foo, C = foo, D = foo)).

check(Name, Goal) :-
	(   catch(Goal, E, (format("~w threw ~q~n", [Name,E]), fail))
	->  format("~w ok~n", [Name])
	;   format("~w FAILED~n", [Name])
	).
