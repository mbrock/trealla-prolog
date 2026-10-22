% unload_file/1, SWI's: one file's clauses go, and make/0 leaves it out until it is consulted again.

:- initialization(main).

main :-
	F = 'tmp_unload_file.pl',
	open(F, write, S), write(S, 'uf(1).\n'), close(S),
	consult(tmp_unload_file),
	findall(X, uf(X), L1), write(loaded(L1)), nl,
	unload_file(tmp_unload_file),
	findall(X, catch(uf(X), _, fail), L2), write(unloaded(L2)), nl,
	sleep(1.1), open(F, write, S2), write(S2, 'uf(2).\n'), close(S2),
	make,
	findall(X, catch(uf(X), _, fail), L3), write(after_make(L3)), nl,
	delete_file(F),
	unload_file(never_loaded_file), write(never_loaded_ok), nl,
	catch(unload_file(_), error(E1, _), true), write(E1), nl,
	catch(unload_file(123), error(E2, _), true), write(E2), nl,
	catch(unload_file([a]), error(E3, _), true), write(E3), nl.
