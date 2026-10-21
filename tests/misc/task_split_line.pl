% A task's line read gave up at the first EAGAIN and passed off the part
% of the line it had as the whole, so a line that came in two packets
% read as two lines. The part read so far is now kept on the stream
% until the rest arrives, as a read outside a task waits for it.

:- use_module(library(socket)).
:- initialization(main).

quiet_pair(Srv, Client, Slave) :-
	tcp_socket(Cl), tcp_connect(Cl, '127.0.0.1':3442),
	tcp_accept(Srv, Sl, _),
	tcp_open_socket(Cl, Client),
	tcp_open_socket(Sl, Slave).

% Runs Goal in a task on the client side of a fresh pair, while a thread
% of its own writes Pieces to the peer side, Gap seconds apart, and then
% closes it if Close is close.

t(Srv, Label, Pieces, Gap, Close, S, Goal) :-
	quiet_pair(Srv, S, SS),
	set_stream(S, timeout(5)),
	thread_create(writer(SS, Pieces, Gap, Close), W, []),
	task_create(report(Label, Goal, S), _),
	task_wait,
	thread_join(W, _),
	close(S),
	catch(close(SS), _, true).

writer(SS, Pieces, Gap, Close) :-
	forall(nth1(I, Pieces, P),
	       (	(I > 1 -> sleep(Gap) ; true),
		format(SS, "~s", [P]), flush_output(SS)
	       )),
	(Close == close -> close(SS) ; true).

report(Label, Goal, S) :-
	catch(
	    (call(Goal) -> Outcome = ok ; Outcome = failed),
	    E,
	    (	E = error(timeout_error(read, S0), _), S0 == S
	    ->	Outcome = timeout_error
	    ;	Outcome = E
	    )
	),
	format("~w: ~w~n", [Label, Outcome]).

main :-
	tcp_socket(Srv), tcp_bind(Srv, '127.0.0.1':3442), tcp_listen(Srv, 5),
	t(Srv, getline_2, ["ab", "c\n"], 0.1, open, S1, (getline(S1, L1), L1 == "abc")),
	t(Srv, getline_3, ["ab", "c\n"], 0.1, open, S2, (getline(S2, L2, []), L2 == "abc")),
	t(Srv, read_line_to_string_2, ["ab", "c\n"], 0.1, open, S3, (read_line_to_string(S3, L3), L3 == "abc")),
	t(Srv, read_line_to_codes_2, ["ab", "c\n"], 0.1, open, S4, (read_line_to_codes(S4, L4), atom_codes(abc, L4))),
	t(Srv, read_term_2, ["foo(", "bar).\n"], 0.1, open, S5, (read_term(S5, T5, []), T5 == foo(bar))),
	t(Srv, lines_then_split, ["x\ny\nz", "w\n"], 0.1, open, S6,
	  (getline(S6, A6), getline(S6, B6), getline(S6, C6), [A6, B6, C6] == ["x", "y", "zw"])),
	t(Srv, three_pieces, ["a", "b", "c\n"], 0.1, open, S7, (getline(S7, L7), L7 == "abc")),
	t(Srv, gaps_within_timeout, ["a", "b", "c\n"], 0.15, open, S8,
	  (set_stream(S8, timeout(0.25)), getline(S8, L8), L8 == "abc")),
	t(Srv, part_then_eof, ["ab", "c"], 0.1, close, S9,
	  (getline(S9, L9), L9 == "abc", \+ getline(S9, _))),
	t(Srv, timeout_drops_part, ["ab", "c\n"], 0.4, open, S10,
	  (	set_stream(S10, timeout(0.2)),
		catch(getline(S10, _), error(timeout_error(read, _), _), true),
		set_stream(S10, timeout(5)),
		getline(S10, L10), L10 == "c"
	  )),
	tcp_close_socket(Srv).
