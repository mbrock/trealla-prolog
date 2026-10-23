% thread_property/2 copied a detached thread's exception ball while its
% cleanup freed it, and crashed (#1178). Polled here in each query mode,
% for threads that throw, exit and succeed; a retired thread named
% directly is an existence error, and one met while enumerating is skipped.

:- initialization(main).

worker(success).
worker(failure) :- fail.
worker(exception) :- throw(probe([a,b],pair(1,2))).
worker(exit) :- thread_exit(done).

expected(success, true).
expected(failure, false).
expected(exception, exception(probe([a,b],pair(1,2)))).
expected(exit, exited(done)).

% A joinable thread's status stays readable until join, and agrees with it.

joinable(Kind) :-
	thread_create(worker(Kind), T, []),
	expected(Kind, E),
	await_status(T, E, 5000),
	thread_join(T, S),
	(S == E -> true ; throw(join_status(Kind, S))).

await_status(T, E, N) :-
	thread_property(T, status(S)),
	(	S == E -> true
	;	N > 0 -> sleep(0.001), N1 is N-1, await_status(T, E, N1)
	;	throw(status_wait_exhausted(T, E, S))
	).

read_property(T, bound) :-
	thread_property(T, status(S)), valid(S).
read_property(T, properties) :-
	findall(P, thread_property(T, P), Ps),
	memberchk(status(S), Ps), valid(S).
read_property(T, threads) :-
	findall(Id-S, thread_property(Id, status(S)), Pairs),
	memberchk(T-S, Pairs), valid(S).
read_property(T, all) :-
	findall(Id-P, thread_property(Id, P), Pairs),
	memberchk(T-status(S), Pairs), valid(S).

valid(running).
valid(true).
valid(exception(probe([a,b],pair(1,2)))).
valid(exited(done)).

% Poll until the thread is gone: only an existence error may say so.

poll(_, _, 0) :- !, throw(poll_exhausted).
poll(T, Mode, N) :-
	catch((read_property(T, Mode) -> Again = true ; Again = false), E,
		(E = error(existence_error(thread_object,_),_) -> Again = false ; throw(E))),
	(Again == true -> N1 is N-1, poll(T, Mode, N1) ; true).

retire(Kind, Mode) :-
	thread_create(worker(Kind), T, [detached(true)]),
	poll(T, Mode, 100000).

% Each property once, alias only when there is one.

properties :-
	thread_create(true, T1, []),
	thread_create(true, T2, [alias(probe)]),
	await_status(T1, true, 5000),
	await_status(T2, true, 5000),
	findall(P, thread_property(T1, P), Ps1),
	findall(P, thread_property(probe, P), Ps2),
	thread_join(T1, _),
	thread_join(T2, _),
	writeq(Ps1), nl,
	writeq(Ps2), nl.

main :-
	forall(member(K, [success,failure,exception,exit]), joinable(K)),
	writeln(join_status_agrees),
	properties,
	forall(member(Mode, [bound,properties,threads,all]),
		(	forall((member(K, [exception,exit,success]), between(1, 100, _)), retire(K, Mode)),
			writeln(passed(Mode))
		)).
