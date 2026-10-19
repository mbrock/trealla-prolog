% A static predicate's file reconsulted while a call is part way through its indexed clauses: the
% call goes on over the old ones, which reconsult freed under it before v3.13.15.

:- initialization(main).
:- dynamic(done/0).

gen(File, Shape) :-
	open(File, write, S),
	forall(between(1, 600, I), (K is I mod 3, clause_text(Shape, K, I, T), format(S, "~w.~n", [T]))),
	close(S).

clause_text(atom, K, I, T) :- format(atom(T), "p(k~w, ~w)", [K, I]).
clause_text(compound, K, I, T) :- format(atom(T), "p(f(k~w), ~w)", [K, I]).
clause_text(second, K, I, T) :- format(atom(T), "p(~w, k~w)", [I, K]).

goal(atom, p(k1, X), X).
goal(compound, p(f(k1), X), X).
goal(second, p(X, k1), X).

% In the working directory, since consult/1 would look beside this file.

tmp_file(Name, File) :-
	working_directory(D, D),
	format(atom(File), "~s~w", [D, Name]).

walk(Shape) :-
	tmp_file('reconsult_index_walk_tmp.pl', File),
	gen(File, Shape), consult(File),
	goal(Shape, G, X),
	retractall(done),
	findall(X, (G, (done -> true ; assertz(done), consult(File))), L),
	length(L, N), L = [First|_], last(L, Last),
	write(Shape-N-First-Last), nl,
	delete_file(File).

main :-
	walk(atom),
	walk(compound),
	walk(second).
