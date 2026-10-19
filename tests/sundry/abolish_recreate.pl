% A predicate abolished and made again takes over its old header when nothing reads it, so it must
% come back with nothing of the old one: no properties, and static if consulted. A call compiled
% before sees the new one, and a query still inside the old one keeps its view.

:- initialization(main).
:- dynamic(r/1).
:- discontiguous(r/1).
:- dynamic(w/1).

r(1).

c :- (r(X), write(c(X)), nl, fail ; true).
cw :- (w(X), write(cw(X)), nl, fail ; true).

props(Tag) :-
	findall(P, (predicate_property(r(_), P), memberchk(P, [dynamic, discontiguous, multifile, static])), Ps),
	msort(Ps, S),
	write(Tag-S), nl.

% In the working directory, since consult/1 would look beside this file.

tmp_file(Name, File) :-
	working_directory(D, D),
	format(atom(File), "~s~w", [D, Name]).

recreated :-
	c, props(before),
	abolish(r/1), assertz(r(2)), c, props(reasserted),
	abolish(r/1),
	tmp_file('abolish_recreate_tmp.pl', F),
	setup_call_cleanup(open(F, write, S), format(S, "r(3).~nr(4).~n", []), close(S)),
	consult(F), delete_file(F),
	c, props(consulted),
	catch((assertz(r(5)), write(asserted)), error(E, _), (functor(E, N, _), write(N))), nl.

reader_inside :-
	assertz(w(a)), assertz(w(b)),
	findall(X, (w(X), (X == a -> abolish(w/1), assertz(w(new)) ; true)), L1), write(L1), nl, cw,
	abolish(w/1), assertz(w(again)), cw,
	abolish(w/1), assertz(w(third)), cw,
	retract(w(third)), cw.

% Linear now: each round used to leave a dead header for every later lookup to walk past.

many_rounds :-
	(between(1, 20000, I), assertz(m(I)), abolish(m/1), fail ; true),
	assertz(m(last)), findall(X, m(X), L), write(L), nl.

main :-
	recreated,
	reader_inside,
	many_rounds.
