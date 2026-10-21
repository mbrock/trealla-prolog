% Issue #1173: threads making modules at once lost some from the module list.

:- initialization(main).

make(P) :- forall(between(1, 3000, I), (format(atom(M), '~w_~w', [P, I]), '$create_module'(M))).

main :-
	findall(T, (member(P, [mc_a, mc_b, mc_c, mc_d]), thread_create(make(P), T, [])), Ts),
	findall(S, (member(T, Ts), thread_join(T, S)), Ss),
	findall(M, (current_module(M), sub_atom(M, 0, _, _, mc_)), Ms),
	length(Ms, N),
	writeq(Ss-N), nl.
