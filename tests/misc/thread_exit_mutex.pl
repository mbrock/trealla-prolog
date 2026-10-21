% A thread that ends holding a mutex, however many times it took it, leaves it free for the next.

:- initialization(main).

main :-
	mutex_create(M),
	thread_create((mutex_lock(M), mutex_lock(M)), T, []),
	thread_join(T, _),
	( mutex_trylock(M) -> R = free ; R = still_locked ),
	writeq(R), nl,
	mutex_unlock(M),
	mutex_property(M, status(S)),
	writeq(S), nl.
