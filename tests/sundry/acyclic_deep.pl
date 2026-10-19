% acyclic_term/1 and cyclic_term/1 past g_max_depth, once taken for cyclic, and over shared subterms, once walked per path; as SWI and Scryer

:- initialization(main).

nest(0, z) :- !.
nest(N, f(G)) :- N1 is N-1, nest(N1, G).
loop(0, T, T) :- !.
loop(N, f(G), T) :- N1 is N-1, loop(N1, G, T).
dag(0, X, X) :- !.
dag(N, f(Y, Y), X) :- N1 is N-1, dag(N1, Y, X).

t(Name, G) :-
	( catch(G, E, (write(caught(E)), nl, fail)) -> R = yes ; R = no ),
	format("~w: ~w~n", [Name, R]).

main :-
	nest(100000, A),
	t('acyclic_term, 100k deep', acyclic_term(A)),
	t('cyclic_term, 100k deep', cyclic_term(A)),
	t('must_be(acyclic), 100k deep', must_be(acyclic, A)),
	loop(100000, C, C),
	t('acyclic_term, cycle 100k round', acyclic_term(C)),
	t('cyclic_term, cycle 100k round', cyclic_term(C)),
	dag(1000, D, a),
	t('acyclic_term, shared 1000 levels', acyclic_term(D)),
	W = g(W), dag(1000, E, W),
	t('acyclic_term, shared 1000 levels over a cycle', acyclic_term(E)),
	S = s(P, P, Q), P = p(Q, Q), Q = q(1),
	t('acyclic_term, shared siblings', acyclic_term(S)),
	L = [a, b|L],
	t('acyclic_term, cyclic list', acyclic_term(L)).
