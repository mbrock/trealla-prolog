% A task's read yields to the scheduler rather than waiting itself, so
% the stream's timeout(_) has to bound the yields too: a read with
% nothing arriving for T seconds throws error(timeout_error(read, S), _),
% as the same read outside a task does (see stream_read_timeout.pl).

:- use_module(library(socket)).
:- use_module(library(http)).
:- initialization(main).

quiet_pair(Srv, Client, Slave) :-
	tcp_socket(Cl), tcp_connect(Cl, '127.0.0.1':3440),
	tcp_accept(Srv, Sl, _),
	tcp_open_socket(Cl, Client),
	tcp_open_socket(Sl, Slave).

% Runs Goal in a task on the client side of a fresh pair, while a thread
% of its own runs Setup on the peer side.

t(Srv, Label, Setup, S, Goal) :-
	quiet_pair(Srv, S, SS),
	set_stream(S, timeout(0.2)),
	thread_create(call(Setup, SS), W, []),
	task_create(report(Label, Goal, S), _),
	task_wait,
	thread_join(W, _),
	close(S), close(SS).

report(Label, Goal, S) :-
	outcome(Goal, S, Outcome, Fast),
	format("~w: ~w ~w~n", [Label, Outcome, Fast]).

outcome(Goal, S, Outcome, Fast) :-
	get_time(T0),
	catch(
	    (call(Goal) -> Outcome = success ; Outcome = failure),
	    E,
	    (	E = error(timeout_error(read, S0), _), (var(S) -> true ; S0 == S)
	    ->	Outcome = timeout_error
	    ;	Outcome = E
	    )
	),
	get_time(T1),
	(T1 - T0 < 1.0 -> Fast = fast ; Fast = slow).

silent(_).
one_line(SS) :- format(SS, "one~n", []), flush_output(SS).
late(Secs, SS) :- sleep(Secs), format(SS, "late~n", []), flush_output(SS).

% An HTTP reply whose body comes in pieces Gap seconds apart.

trickle_http(Gap) :-
	tcp_socket(Srv), tcp_bind(Srv, '127.0.0.1':3441), tcp_listen(Srv, 5),
	tcp_accept(Srv, Cl, _),
	tcp_open_socket(Cl, S),
	drain_headers(S),
	format(S, "HTTP/1.1 200 OK\r~nContent-Length: 6\r~n\r~nab", []), flush_output(S),
	catch(
	    (	sleep(Gap), format(S, "cd", []), flush_output(S),
		sleep(Gap), format(S, "ef", []), flush_output(S)
	    ),
	    _, true),
	close(S),
	tcp_close_socket(Srv).

drain_headers(S) :-
	getline(S, Line),
	(	(Line == "\r" ; Line == "" ; Line == '' ; Line == [])
	->	true
	;	drain_headers(S)
	).

http_case(Label, Gap) :-
	thread_create(trickle_http(Gap), T, []),
	sleep(0.1),
	task_create(report(Label, (http_get("http://127.0.0.1:3441/", D, [timeout(0.25)]), D == "abcdef"), _), _),
	task_wait,
	thread_join(T, _).

main :-
	tcp_socket(Srv), tcp_bind(Srv, '127.0.0.1':3440), tcp_listen(Srv, 5),
	t(Srv, getline_2, silent, S1, getline(S1, _)),
	t(Srv, get_char_2, silent, S2, get_char(S2, _)),
	t(Srv, read_term_2, silent, S3, read_term(S3, _, [])),
	t(Srv, zero_silent, silent, S4, (set_stream(S4, timeout(0)), getline(S4, _))),
	t(Srv, zero_with_input, one_line, S5, (set_stream(S5, timeout(0)), sleep(0.1), getline(S5, L5), L5 == "one")),
	t(Srv, data_in_time, late(0.1), S6, (set_stream(S6, timeout(5)), getline(S6, L6), L6 == "late")),
	t(Srv, infinite, late(0.3), S7, (set_stream(S7, timeout(infinite)), getline(S7, L7), L7 == "late")),
	tcp_close_socket(Srv),
	http_case(http_gaps_within_timeout, 0.15),
	http_case(http_gap_past_timeout, 0.4).
