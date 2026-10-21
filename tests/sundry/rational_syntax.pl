% SWI's 1r3 rational syntax: read reduced, written so writeq/1 reads back, off under strict_iso.

:- initialization(main).

read_back(A) :-
	catch((term_to_atom(T, A), write_canonical(T)), error(E, _), write(E)),
	nl.

round_trip(T) :-
	format(atom(A), "~q", [T]),
	term_to_atom(T2, A),
	( T2 == T -> R = ok ; R = mismatch ),
	format("~w ~w~n", [A, R]).

main :-
	maplist(read_back, ['1r3', '2r4', '4r2', '0r5', '-1r3', '1_000r3', '1r0', '1R3', 'X = 1r', '1r3r4']),
	X is -1 rdiv 3, Y is 1 rdiv 3,
	maplist(round_trip, [X, Y, a-X, -(Y), -(X), 2*X, [X,Y], 1 rdiv 3]),
	rational(Y, N, D), write(N/D), nl,
	rational(5, N2, D2), write(N2/D2), nl,
	( rational(1.5, _, _) -> write(float_rational) ; write(float_not_rational) ), nl,
	atom_codes('2r6', Cs), number_codes(Z, Cs), writeq(Z), nl,
	set_prolog_flag(strict_iso, true),
	writeq(Y), nl,
	read_back('1r3'),
	set_prolog_flag(strict_iso, false).
