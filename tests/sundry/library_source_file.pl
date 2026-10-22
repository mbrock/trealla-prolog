% An embedded library first loaded from a user file is from the library, not that file.

:- initialization(main).
:- use_module(library(ugraphs)).

main :-
	ugraphs:source_info(vertices_edges_to_ugraph/3, Infos),
	Infos = [Info|_],
	memberchk(filename(F), Info),
	write(F), nl.
