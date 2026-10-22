% parse_csv_file/2 asserts each row and gives back what parsing the line took: it freed its line buffer and then
% parser_destroy() freed it again, aborting every call, and each line's field bindings stayed counted until the
% query ended (see `make leaks`). The row on the heap is the clause's once asserted, so it is not released twice.
% A row of the wrong arity raised an error catch/3 never saw: parsing carried on as if the throw had succeeded.

:- initialization(main).

main :-
	F = 'tmp_parse_csv_file.csv',
	open(F, write, S),
	forall(between(1, 50, I), format(S, "a_long_enough_first_field_~w,another_long_enough_field_~w,~w~n", [I, I, I])),
	close(S),
	parse_csv_file(F, [functor(ra)]),
	findall(A, ra(A,_,_), As), length(As, NA), last(As, LA), write(atoms(NA, LA)), nl,
	parse_csv_file(F, [functor(rs), strings(true)]),
	findall(B, rs(_,B,_), Bs), length(Bs, NB), last(Bs, LB), atom_chars(LBA, LB), write(strings(NB, LBA)), nl,
	parse_csv_file(F, [functor(rn), numbers(true)]),
	findall(C, rn(_,_,C), Cs), sum_list(Cs, Sum), write(numbers(Sum)), nl,
	catch(parse_csv_file(F, [functor(rx), arity(2)]), error(E, _), true), write(E), nl,
	delete_file(F).
