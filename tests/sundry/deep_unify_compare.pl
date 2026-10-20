% Unify and compare past the depth they once recursed to, raising resource_error(stack) or crashing; as SWI and Scryer

:- initialization(main).

nest(0, X, X) :- !.
nest(N, f(G), X) :- N1 is N-1, nest(N1, G, X).
lsum(0, X, X) :- !.
lsum(N, G+1, X) :- N1 is N-1, lsum(N1, G, X).
loop(0, T, T) :- !.
loop(N, f(G), T) :- N1 is N-1, loop(N1, G, T).

t(Name, G) :-
	( catch(G, E, (write(caught(E)), nl, fail)) -> R = yes ; R = no ),
	format("~w: ~w~n", [Name, R]).

main :-
	N = 100000,
	nest(N, A, a), nest(N, B, _), t('unify, 100k deep', A = B),
	nest(N, C, a), nest(N, D, b), t('unify differing at the bottom', C = D),
	nest(N, E, a), nest(N, F, a), t('==, 100k deep', E == F),
	nest(N, G, a), nest(N, H, b), t('compare, 100k deep', (compare(O, G, H), O == (<))),
	lsum(N, I, a), lsum(N, J, _), t('unify, 100k left-nested', I = J),
	lsum(N, K, a), lsum(N, L, a), t('==, 100k left-nested', K == L),
	nest(N, M, a), nest(N, P, _), t('subsumes_term, 100k deep', subsumes_term(P, M)),
	nest(N, Q, a), t('unify_with_occurs_check, 100k deep', unify_with_occurs_check(Q, _)),
	loop(N, X, X), loop(N, Y, Y), t('unify, cycles of 100k', X = Y),
	loop(N, X2, X2), loop(N, Y2, Y2), t('==, cycles of 100k', X2 == Y2),
	N2 is N*2, loop(N, X3, X3), loop(N2, Y3, Y3), t('unify, cycles of 100k and 200k', X3 = Y3).
