% Strings and bigints made along these paths hold no reference past the query: see `make leaks`. split_string/4's
% fields, atom_concat/3's halves, a syntax error's partial term and the numbers skipped after it, a float that
% overflows, a radix bigint and each number but the last that number_codes/2 parsed were all left counted.

:- initialization(main).

main :-
	split_string("a long enough field,another long enough field", ",", "", Fs),
	length(Fs, NF), write(fields(NF)), nl,
	atom_concat(X, X, 'abcdefghijklmnopabcdefghijklmnop'), atom_length(X, NX), write(halves(NX)), nl,
	F = 'tmp_leftover_refs.pl',
	open(F, write, S),
	write(S, 'first("a string long enough for its own buffer").\n'),
	write(S, 'bad("another string long enough for a buffer" + ).\n'),
	write(S, 'skipped(123456789012345678901234567890 987654321098765432109876543210).\n'),
	write(S, 'last(123456789012345678901234567890).\n'),
	close(S),
	open(F, read, In), read_all(In, Ts), close(In), delete_file(F),
	write(Ts), nl,
	( catch(number_codes(_, "1.0e99999"), error(E, _), true), nonvar(E) -> write(overflow) ; write(no_overflow) ), nl,
	H = 0xffffffffffffffffffffffffffff, B = 0b11111111111111111111111111111111111111111111111111111111111111111111,
	O = 0o77777777777777777777777777777, write(H-B-O), nl,
	atom_codes('123456789012345678901234567890', Cs), number_codes(N1, Cs), atom_number('98765432109876543210987', N2),
	N3 is N1 + N2, write(N3), nl.

read_all(In, Ts) :-
	catch(read_term(In, T, []), error(syntax_error(_), _), T = syntax_error),
	( T == end_of_file -> Ts = [] ; functor(T, N, _), Ts = [N|Ts1], read_all(In, Ts1) ).
