% Issue #1174: with_output_to/2 collects only its own thread's or task's writes, and not an engine's, but a thread made inside it writes into it.

:- initialization(main).
:- dynamic(got/2).

main :-
	threads, tasks, engine, inherited, inherited_many.

threads :-
	thread_self(Parent),
	thread_create(worker(Parent), Child, []),
	thread_get_message(ready),
	with_output_to(atom(MainText), (write(beta), thread_send_message(Child, go), thread_get_message(wrote))),
	thread_send_message(Child, finish),
	thread_get_message(result(ChildText)),
	thread_join(Child, _),
	writeq(threads(MainText, ChildText)), nl.

worker(Parent) :-
	with_output_to(atom(Text),
		( write(alpha),
		  thread_send_message(Parent, ready),
		  thread_get_message(go),
		  write(omega),
		  thread_send_message(Parent, wrote),
		  thread_get_message(finish) )),
	thread_send_message(Parent, result(Text)).

tasks :-
	task_call(task(one, a, b)), task_call(task(two, c, d)), task_wait,
	findall(N-T, got(N, T), L),
	writeq(tasks(L)), nl.

task(Name, A, B) :-
	with_output_to(atom(T), (write(A), task_yield, write(B))),
	assertz(got(Name, T)).

engine :-
	engine_create(X, (write(engine), X = 1), E),
	with_output_to(atom(A), engine_next(E, _)), nl,
	writeq(engine(A)), nl.

inherited :-
	with_output_to(atom(A), (thread_create((thread_create(write(grandchild), G, []), thread_join(G, _), write(child)), T, []), thread_join(T, _), write(parent))),
	writeq(inherited(A)), nl.

inherited_many :-
	with_output_to(atom(A),
		( findall(T, (between(1, 4, I), thread_create(forall(between(1, 2000, _), write(I)), T, [])), Ts),
		  forall(between(1, 2000, _), write(p)),
		  forall(member(T, Ts), thread_join(T, _)) )),
	atom_length(A, L),
	writeq(inherited_many(L)), nl.
