% Issue #1175: an asserted clause's variables were printed by garbage names for goal_expansion/2, which also stayed disabled after.

:- initialization(main).

goal_expansion(eq(_,_), _) :- fail.
goal_expansion(mark(X,Y), (Local = added, target(X,Y,Local))).
goal_expansion(ground_marker, true).
goal_expansion(dbl(X,Y), (Y is X*2)).
goal_expansion(unbound(_), _).
goal_expansion(loop(X), loop(f(X))).

target(a, b, added).
eq(a, a).

main :-
	assertz((probe(X,X,Y) :- eq(X,Y))),
	check(probe, findall(A-B-C, probe(A,B,C), [a-a-a])),
	assertz((ground_recovery :- ground_marker)),
	check(ground, ground_recovery),
	assertz((after(X,X,Y) :- mark(X,Y))),
	check(after, findall(A-B-C, after(A,B,C), [a-a-b])),
	assertz((twice(X,Y) :- dbl(X,Y)), Ref),
	check(clause_ref, (clause(twice(P,Q), (Q1 is P1*2), Ref), P1 == P, Q1 == Q)),
	check(twice, (twice(4,Z), Z == 8)),
	asserta(('q x'(X,'A b',X) :- dbl(X,_))),
	check(quoted, 'q x'(1,'A b',1)),
	throws(unbound, assertz((u(X) :- unbound(X)))),
	check(unbound_not_stored, \+ catch(clause(u(_),_), _, fail)),
	throws(loop, assertz((l(X) :- loop(X)))),
	check(module, module_case).

% The issue's own case: hooks loaded by load_text/2 into a temporary module.

module_case :-
	atom_chars('goal_expansion(eq(_,_),_) :- fail. goal_expansion(mark(X,Y),(L=added,target(X,Y,L))). goal_expansion(ground_marker,true). target(a,b,added). store(C) :- assertz(C).', Cs),
	in_temporary_module(probe_m, load_text(Cs, [module(probe_m)]), module_checks).

module_checks :-
	read_term_from_atom('probe(X,X,Y) :- eq(X,Y).', C1, []),
	probe_m:store(C1),
	probe_m:assertz(eq(a,a)),
	findall(A-B-C, probe_m:probe(A,B,C), [a-a-a]),
	probe_m:store((ground_recovery :- ground_marker)),
	probe_m:ground_recovery,
	read_term_from_atom('after(X,X,Y) :- mark(X,Y).', C2, []),
	probe_m:store(C2),
	findall(A-B-C, probe_m:after(A,B,C), [a-a-b]).

check(Name, Goal) :-
	(   catch(Goal, E, (format("~w threw ~q~n", [Name,E]), fail))
	->  format("~w ok~n", [Name])
	;   format("~w FAILED~n", [Name])
	).

throws(Name, Goal) :-
	catch((Goal, format("~w did not throw~n", [Name])), error(E, _), format("~w threw ~q~n", [Name,E])).
