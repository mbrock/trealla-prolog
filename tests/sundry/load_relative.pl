% Relative loads resolve against the loading file, not the working directory or a module's name.

:- initialization(main).
:- use_module('load_relative/lr_a').

main :-
	a(L),
	write(L), nl.
