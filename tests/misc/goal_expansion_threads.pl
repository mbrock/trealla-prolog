% goal_expansion/2's in-progress guard was one bit shared by all threads, so concurrent asserts skipped expansion (about two in three of 8000 here).

:- initialization(main).
:- dynamic(c/2).

goal_expansion(dbl(X,Y), (Y is X*2)).

worker(N) :- forall(between(1, 2000, I), assertz((c(N-I, Y) :- dbl(I, Y)))).

main :-
	findall(T, (between(1, 4, N), thread_create(worker(N), T, [])), Ts),
	maplist(thread_join, Ts),
	findall(B, clause(c(_,_), B), Bs), length(Bs, Len),
	findall(x, (member(B, Bs), B = (_ is _)), Xs), length(Xs, Expanded),
	format("~w clauses, ~w expanded~n", [Len, Expanded]).
