% Long chains of control constructs in a clause body load, compile and
% run without exhausting the C stack: the walkers over a body loop down
% each chain's last argument rather than recursing into it.

:- initialization(main).

body(conj, 0, true) :- !.
body(conj, N, (true, G)) :- N1 is N-1, body(conj, N1, G).
body(disj, 0, true) :- !.
body(disj, N, (fail ; G)) :- N1 is N-1, body(disj, N1, G).
body(ite, 0, true) :- !.
body(ite, N, (fail -> true ; G)) :- N1 is N-1, body(ite, N1, G).
body(soft, 0, true) :- !.
body(soft, N, (fail *-> true ; G)) :- N1 is N-1, body(soft, N1, G).
body(if3, 0, true) :- !.
body(if3, N, if(fail, true, G)) :- N1 is N-1, body(if3, N1, G).

run(Kind, N) :-
	body(Kind, N, G),
	( call(G) -> R1 = ok ; R1 = failed ),
	H =.. [Kind],
	assertz((H :- G)),
	( H -> R2 = ok ; R2 = failed ),
	format("~w: call ~w, asserted ~w~n", [Kind, R1, R2]).

% Written as text, not with write/1, which elides terms nested past a depth limit

repeated(N, Atom, Sep, Text) :-
	length(L, N),
	maplist(=(Atom), L),
	atomic_list_concat(L, Sep, Text).

% In the working directory, since consult/1 would look beside this file

consulted(N) :-
	working_directory(Dir, Dir),
	format(atom(File), "~s~w", [Dir, 'long_bodies_tmp.pl']),
	repeated(N, true, ', ', Conj),
	repeated(N, fail, ' ; ', Disj),
	numlist(1, N, Is),
	findall(D, (member(I, Is), format(atom(D), "dynamic(d~w/0)", [I])), Ds),
	atomic_list_concat(Ds, ', ', Decls),
	open(File, write, S),
	format(S, ":- ~a.~nc :- ~a, !.~nd :- ~a ; true.~n", [Decls, Conj, Disj]),
	close(S),
	consult(File),
	delete_file(File),
	( c, d -> R = ok ; R = failed ),
	format(atom(Last), "d~w", [N]),
	( predicate_property(Last, dynamic) -> P = dynamic ; P = 'not dynamic' ),
	format("consulted: ~w, last declared ~w~n", [R, P]).

main :-
	N = 10000,
	forall(member(K, [conj, disj, ite, soft, if3]), run(K, N)),
	consulted(N).
