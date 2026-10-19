% Clauses abolish/1 or a reconsult takes away while still in use: running, bound into, or walked
% by a choicepoint. They were freed at once; now they last as long as a retracted clause would.

:- initialization(main).
:- dynamic(p/1).
:- dynamic(r/0).
:- dynamic(s/1).
:- dynamic(q/1).

p(1). p(2). p(3).
s(f(abc, [1,2,3])).

% Abolished under an open choicepoint, with enough retracts after it to set off a purge (#1171).

choicepoint :-
	forall(between(1, 600, I), assertz(q(I))),
	p(X), abolish(p/1), retractall(q(_)),
	write(X), nl,
	X >= 3, !.

running_body :-
	assertz((r :- abolish(r/0), atom_length(abcdef, L), X = f(L, g(h, [1,2,3])), write(X), nl)),
	r.

bound_into :-
	s(X), abolish(s/1), atom_length(xyzzy, _),
	write(X), nl.

% current_prolog_flag/2 with the flag unbound reloads its table, abolishing the old one.

flag_value :-
	current_prolog_flag(F, V), compound(V), F \== argv, F \== raw_argv, !,
	current_prolog_flag(_, _), !,
	atom_length(xyzzy, _),
	(compound(V) -> write(still_compound) ; write(V)), nl.

temporary_module :-
	in_temporary_module(M, true, (assertz(M:t(f(abc, [1,2,3]))), M:t(X))),
	atom_length(xyzzy, _),
	write(X), nl.

% Reconsulting a file after erase/1 left a clause waiting to be reclaimed.

erase_then_reconsult :-
	tmp_file('abolish_in_use_tmp1.pl', File),
	setup_call_cleanup(open(File, write, S),
		format(S, ":- dynamic(d/1).~nd(1).~nd(2).~nd(3).~n", []), close(S)),
	consult(File), clause(d(2), true, R), erase(R), consult(File),
	findall(X, d(X), L), write(L), nl,
	retract(d(1)), findall(X, d(X), L2), write(L2), nl,
	delete_file(File).

% Reconsulting the file whose clause is running.

reconsult_running :-
	tmp_file('abolish_in_use_tmp2.pl', File),
	setup_call_cleanup(open(File, write, S),
		format(S, "rc :- consult(~q), atom_length(abcdef, L), X = g(L, h([1,2])), write(X), nl.~n", [File]), close(S)),
	consult(File), rc,
	delete_file(File).

% In the working directory, since consult/1 would look beside this file.

tmp_file(Name, File) :-
	working_directory(D, D),
	format(atom(File), "~s~w", [D, Name]).

main :-
	choicepoint,
	running_body,
	bound_into,
	flag_value,
	temporary_module,
	erase_then_reconsult,
	reconsult_running.
