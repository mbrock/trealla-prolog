% Deeply nested terms read back without overflowing the C stack, as the
% reader stacks the enclosing state on the heap rather than recursing. A
% canonical list nests one level per element.

:- initialization(main).

repeated(N, Atom, Text) :-
	length(L, N),
	maplist(=(Atom), L),
	atomic_list_concat(L, Text).

depth([X], N0, N) :- !, N1 is N0+1, depth(X, N1, N).
depth({X}, N0, N) :- !, N1 is N0+1, depth(X, N1, N).
depth(f(X), N0, N) :- !, N1 is N0+1, depth(X, N1, N).
depth(a, N, N).

nested(Label, N, Open, Close) :-
	repeated(N, Open, Os),
	repeated(N, Close, Cs),
	atomic_list_concat([Os, a, Cs], Text),
	term_to_atom(T, Text),
	depth(T, 0, D),
	format("~w: depth ~w~n", [Label, D]).

bad(Text) :-
	(   catch(term_to_atom(_, Text), error(syntax_error(_), _), fail)
	->  format("~w: PARSED~n", [Text])
	;   format("~w: syntax error~n", [Text])
	).

main :-
	N = 100000,
	numlist(1, N, L),
	format(atom(A), "~k", [L]),
	term_to_atom(T, A),
	( T == L -> R = 'reads back' ; R = 'DIFFERS' ),
	format("canonical list of ~w: ~w~n", [N, R]),
	nested('[]', N, '[', ']'),
	nested('{}', N, '{', '}'),
	nested('f()', N, 'f(', ')'),
	nested('f([{}])', 25000, 'f([{(', ')}])'),
	repeated(N, '(', Ps), repeated(N, ')', Qs),
	atomic_list_concat([Ps, a, Qs], P),
	term_to_atom(G, P),
	format("(): reads as ~w~n", [G]),
	bad('f(g(a]))'),
	bad('[f({a)}]'),
	bad('{[a}]'),
	bad('f([a|b,c])'),
	term_to_atom(After, 'f(x,[a|b],{c})'),
	format("then: ~q~n", [After]).
