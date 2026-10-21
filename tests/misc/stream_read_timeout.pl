% Issue #1172: set_stream(S, timeout(T)), as http_open/3's timeout(T)
% does, was stored but never bounded a socket read, so a silent peer
% held the reader until it chose to answer. A read with nothing arriving
% for T seconds throws error(timeout_error(read, S), _), as in SWI.

:- use_module(library(socket)).
:- use_module(library(http)).
:- use_module(library(iso_ext)).
:- initialization(main).

quiet_pair(Srv, Client, Slave) :-
	tcp_socket(Cl), tcp_connect(Cl, '127.0.0.1':3437),
	tcp_accept(Srv, Sl, _),
	tcp_open_socket(Cl, Client),
	tcp_open_socket(Sl, Slave).

% Runs Goal on the client side of a fresh pair after Setup has written
% to the peer, and reports how it ended and whether that took under 1s.

t(Srv, Label, Setup, S, Goal) :-
	quiet_pair(Srv, S, SS),
	set_stream(S, timeout(0.2)),
	call(Setup, SS),
	outcome(Goal, S, Outcome, Fast),
	format("~w: ~w ~w~n", [Label, Outcome, Fast]),
	close(S), close(SS).

outcome(Goal, S, Outcome, Fast) :-
	get_time(T0),
	catch(
	    (call(Goal) -> Outcome = success ; Outcome = failure),
	    E,
	    (	E = error(timeout_error(read, S0), _), (var(S) -> true ; S0 == S)
	    ->	Outcome = timeout_error
	    ;	E = error(time_limit_exceeded(_, _), _)
	    ->	Outcome = time_limit_exceeded
	    ;	Outcome = E
	    )
	),
	get_time(T1),
	(T1 - T0 < 1.0 -> Fast = fast ; Fast = slow).

silent(_).
one_line(SS) :- format(SS, "one~n", []), flush_output(SS).
partial(SS) :- format(SS, "abc", []), flush_output(SS).
open_term(SS) :- format(SS, "foo(~n", []), flush_output(SS).

late(SS) :-
	thread_create((sleep(0.1), format(SS, "late~n", []), flush_output(SS)), _, [detached(true)]).

% A read that timed out partway through a term, on a long partial line,
% leaves the next reads to start afresh, as in SWI: the rest of the
% broken term is a syntax error and the term after it reads whole.

recover(Srv) :-
	quiet_pair(Srv, S, SS),
	set_stream(S, timeout(0.2)),
	length(Ys, 3000), maplist(=(y), Ys), atom_chars(Y, Ys),
	format(SS, "/* x~n~w", [Y]), flush_output(SS),
	outcome(read_term(S, _, []), S, O1, _),
	format(SS, "~n*/ baz.~nqux.~n", []), flush_output(SS),
	outcome(read_term(S, _, []), S, O2, _),
	outcome((read_term(S, T, []), T == qux), S, O3, _),
	format("recover: ~w ~w ~w~n", [O1, O2, O3]),
	close(S), close(SS).

silent_http :-
	tcp_socket(Srv), tcp_bind(Srv, '127.0.0.1':3438), tcp_listen(Srv, 5),
	tcp_accept(Srv, Cl, _),
	tcp_open_socket(Cl, S),
	sleep(1.2),
	close(S),
	tcp_close_socket(Srv).

main :-
	tcp_socket(Srv), tcp_bind(Srv, '127.0.0.1':3437), tcp_listen(Srv, 5),
	t(Srv, getline_2, silent, S1, getline(S1, _)),
	t(Srv, getline_3, silent, S2, getline(S2, _, [])),
	t(Srv, get_char_2, silent, S3, get_char(S3, _)),
	t(Srv, read_term_2, silent, S4, read_term(S4, _, [])),
	t(Srv, partial_line, partial, S5, getline(S5, _)),
	t(Srv, term_continuation, open_term, S6, read_term(S6, _, [])),
	t(Srv, data_in_time, late, S7, (set_stream(S7, timeout(5)), getline(S7, L), L == "late")),
	t(Srv, getlines_2, one_line, S11, getlines(S11, _)),
	t(Srv, second_timeout, partial, S10, (catch(getline(S10, _), _, true), read_term(S10, _, []))),
	t(Srv, alarm_first, silent, S8, (set_stream(S8, timeout(5)), call_with_time_limit(0.2, getline(S8, _)))),
	t(Srv, infinite, silent, S9, (set_stream(S9, timeout(infinite)), call_with_time_limit(0.2, getline(S9, _)))),
	recover(Srv),
	tcp_close_socket(Srv),
	thread_create(silent_http, T, []),
	sleep(0.1),
	outcome(http_open("http://127.0.0.1:3438/", _, [timeout(0.2)]), _AnyStream, Outcome, Fast),
	format("http_open: ~w ~w~n", [Outcome, Fast]),
	thread_join(T, _).
