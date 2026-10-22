% process_create/3's env(Env) gave the child every variable as the last one: they were kept as pointers into one
% string buffer on the stack. Nothing made here may outlive the query either, under `make leaks`: the environment
% copy env/1 replaced, realpath/readlink results, and a message still queued when the thread ends.

:- initialization(main).
:- use_module(library(filesex)).

main :-
	process_create('/usr/bin/env', [], [env(['TPL_A'=one, 'TPL_B'=two]), stdout(pipe(Out)), process(Pid)]),
	read_lines(Out, Ls), close(Out), process_wait(Pid, exit(0)),
	msort(Ls, Sorted), forall(member(L, Sorted), (atom_chars(A, L), write(A), nl)),
	D = 'tmp_leftover_refs_os_directory',
	make_directory(D),
	atom_concat(D, '/a_file_with_a_long_enough_name.txt', File),
	atom_concat(D, '/a_link_with_a_long_enough_name.txt', Link),
	open(File, write, S), close(S),
	link_file('a_file_with_a_long_enough_name.txt', Link, symbolic),
	posix_readlink(Link, Target), atom_length(Target, NT), write(readlink(NT)), nl,
	posix_realpath(Link, Real), ( atom_concat(_, 'a_file_with_a_long_enough_name.txt', Real) -> write(realpath_ok) ; write(Real) ), nl,
	delete_directory_and_contents(D),
	thread_self(Me),
	thread_send_message(Me, left_for_shutdown_to_free_with_a_long_string("abcdefghijklmnopqrstuvwxyz")),
	write(done), nl.

read_lines(S, Ls) :-
	read_line_to_string(S, L),
	( L == end_of_file -> Ls = [] ; Ls = [L|Ls1], read_lines(S, Ls1) ).
