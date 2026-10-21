% Issue #1174: with_output_to/2 takes its own task's, directives' and portray's writes, not other tasks' or an engine's.

:- initialization(main).
:- dynamic(got/2).

portray(foo) :- write(bar).

main :-
	with_output_to(atom(A1), load_text(":- write(directive).", [])), writeq(A1), nl,
	with_output_to(atom(A2), (task_call(write(child)), task_wait, write(parent))), writeq(A2), nl,
	task_call(task(one, a, b)), task_call(task(two, c, d)), task_wait,
	findall(N-T, got(N, T), L), writeq(L), nl,
	engine_create(X, (write(engine), X = 1), E),
	with_output_to(atom(A3), engine_next(E, _)), nl, writeq(A3), nl,
	with_output_to(atom(A4), (write(x), with_output_to(atom(B4), format("~p", [foo])), write(y))), writeq(A4-B4), nl.

task(Name, A, B) :-
	with_output_to(atom(T), (write(A), task_yield, write(B))),
	assertz(got(Name, T)).
