% A postfix operator ends its operand, so a comma may follow it in a list, and with '' an operator 0'' is 0 and then ''; as Scryer

:- initialization(main).

% Each # in a case stands for a single quote

r(Case) :-
	atom_codes(Case, Cs0),
	findall(C, (member(C0, Cs0), (C0 =:= 0'# -> C = 39 ; C = C0)), Cs),
	atom_codes(Text, Cs),
	(   catch(term_to_atom(T, Text), error(E, _), (functor(E, N, _), T = err(N)))
	->  ( T = err(_) -> R = T ; with_output_to(atom(R), writeq(T)) )
	;   R = failed
	),
	format("~w  ->  ~w~n", [Text, R]).

cases :-
	op(100, xf, fact),
	r('[3 fact, 1]'), r('[1, 3 fact, 2]'), r('[3 fact|t]'), r('[a +, 1]'),
	op(0, xf, fact),
	op(100, xf, ''),
	r('0##'), r('0## '), r('f(0##, a)'), r('[0##, 1]'), r('(0##; a)'),
	op(0, xf, ''),
	op(100, xfx, ''),
	r('0##1'), r('0## 1'),
	op(0, xfx, ''),
	r('0##'), r('0###').

main :-
	write('default:'), nl, cases,
	set_prolog_flag(strict_iso, true),
	write('strict_iso:'), nl, cases.
