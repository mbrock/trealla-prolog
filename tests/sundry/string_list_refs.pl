% Strings walked by member/2 or put in a builtin's list hold no reference past the query: see `make leaks`.
% member/2 run through call/1, so by its clauses, leaves no choicepoint on the last element.

:- initialization(main).

det(G, R) :-
	call_cleanup(G, Det = true),
	( Det == true -> R = det ; R = nondet ),
	!.

exhausted :- \+ member(d, "0123456789").
exhausted_partial :- \+ member(d, [a,b|"0123456789"]).

main :-
	( exhausted -> write(compiled_exhausted) ; true ), nl,
	( exhausted_partial -> write(compiled_partial) ; true ), nl,
	G = member(d, "0123456789"),
	( \+ call(G) -> write(called_exhausted) ; true ), nl,
	det(call(member(_, [a])), D1), write(only(D1)), nl,
	det(call(member(c, [a,b,c])), D2), write(last(D2)), nl,
	F = 'tmp_string_list_refs_long_file_name.txt',
	open(F, write, S), write(S, 'a line long enough to need its own buffer\nshort\n'), close(S),
	getfile(F, Ls), length(Ls, N1), write(getfile(N1)), nl,
	open(F, read, S2), getlines(S2, Ls2), close(S2), length(Ls2, N2), write(getlines(N2)), nl,
	directory_files('.', Fs), ( memberchk(F, Fs) -> write(listed) ; write(not_listed) ), nl,
	delete_file(F).
