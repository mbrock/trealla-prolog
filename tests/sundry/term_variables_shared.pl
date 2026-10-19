% term_variables/2 and term_singletons/2 over subterms shared through variables, once walked per path, so doubling with each level

:- initialization(main).

dag(0, X, X) :- !.
dag(N, f(Y, Y), X) :- N1 is N-1, dag(N1, Y, X).

main :-
	dag(1000, D, V), term_variables(D, L), term_singletons(D, S),
	( L == [V] -> R1 = ok ; R1 = wrong ), write(variables_1000(R1)), nl,
	write(singletons_1000(S)), nl,
	dag(1000, D2, g(A, B, A)), term_variables(D2, L2), term_singletons(D2, S2),
	( L2 == [A, B] -> R2 = ok ; R2 = wrong ), write(variables_over_g(R2)), nl,
	write(singletons_over_g(S2)), nl,
	Y = g(Z), T = f(Y, Y), term_singletons(T, S3), write(shared_once(S3)), nl,
	W = h(P, Q, P), T4 = k(W, Q, R), term_variables(T4, L4), term_singletons(T4, S4),
	( L4 == [P, Q, R], S4 == [R] -> R4 = ok ; R4 = wrong(L4, S4) ), write(order_and_singletons(R4)), nl,
	U = m(X1), T5 = n(U, X2, U), term_singletons(T5, S5),
	( S5 == [X2] -> R5 = ok ; R5 = wrong(S5) ), write(shared_twice(R5)), nl,
	( var(X1) -> true ; true ).
