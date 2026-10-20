% Past the writer's depth limit an acyclic term raises resource_error(stack), or with a big enough stack is written whole, never silently cut off with ...; a cyclic term still is

:- initialization(main).

nest(0, z) :- !.
nest(N, f(G)) :- N1 is N-1, nest(N1, G).
conj(0, true) :- !.
conj(N, (a, G)) :- N1 is N-1, conj(N1, G).
lsum(0, 1) :- !.
lsum(N, G+1) :- N1 is N-1, lsum(N1, G).
minus(0, z) :- !.
minus(N, a-G) :- N1 is N-1, minus(N1, G).
neg(0, a) :- !.
neg(N, \+ G) :- N1 is N-1, neg(N1, G).

% Writes T with Goal, which leaves the text in A
written(Name, T, A, Goal) :-
	(   catch((Goal, R0 = ok), error(E, _), R0 = E)
	->  (   R0 == resource_error(stack) -> R = 'not cut off'
		;   R0 \== ok -> R = R0
		;   sub_atom(A, _, _, _, '...') -> R = 'cut off with ...'
		;   catch(term_to_atom(B, A), _, fail), B =@= T -> R = 'not cut off'
		;   R = 'written wrong'
		)
	;   R = failed
	),
	format("~w: ~w~n", [Name, R]).

writers(What, T) :-
	written(What-write, T, A1, with_output_to(atom(A1), write(T))),
	written(What-writeq, T, A2, with_output_to(atom(A2), writeq(T))),
	written(What-print, T, A3, with_output_to(atom(A3), print(T))),
	written(What-write_canonical, T, A4, with_output_to(atom(A4), write_canonical(T))),
	written(What-write_term, T, A5, with_output_to(atom(A5), write_term(T, [quoted(true)]))),
	written(What-format_w, T, A6, format(atom(A6), "~w", [T])),
	written(What-format_q, T, A7, format(atom(A7), "~q", [T])),
	written(What-term_to_atom, T, A8, term_to_atom(T, A8)),
	written(What-write_term_to_atom, T, A9, write_term_to_atom(A9, T, [quoted(true)])),
	written(What-write_canonical_to_chars, T, A10, (write_canonical_to_chars(Cs, T, []), atom_chars(A10, Cs))).

main :-
	nest(2000, F0), writers('f(f(...)) 2k', F0),
	nest(100000, F), writers('f(f(...)) 100k', F),
	conj(100000, C), written('(a, a, ...) 100k', C, AC, with_output_to(atom(AC), writeq(C))),
	lsum(100000, S), written('1+1+... 100k', S, AS, with_output_to(atom(AS), writeq(S))),
	minus(100000, M), written('a-(a-(...)) 100k', M, AM, with_output_to(atom(AM), writeq(M))),
	neg(100000, N), written('\\+ \\+ ... 100k', N, AN, with_output_to(atom(AN), writeq(N))),
	with_output_to(atom(P), (write(x), catch(write(F), _, true))),
	( sub_atom(P, _, _, _, '...') -> PR = 'part of it, cut off with ...' ; PR = 'none of it or all of it' ),
	format("text a raising write leaves: ~w~n", [PR]),
	Cy = f(Cy),
	with_output_to(atom(CA), writeq(Cy)),
	( sub_atom(CA, _, _, _, '...') -> CE = 'still cut off with ...' ; CE = 'no longer cut off' ),
	format("cyclic f(f(...)): ~w~n", [CE]),
	catch((format(atom(_), "~w", [Cy]), CR = no_error), error(CR0, _), CR = CR0),
	format("format ~~w of a cyclic term: ~w~n", [CR]).
