:- module(lr_a, [a/1]).
:- use_module(lr_b).
:- use_module('./lr_c').
:- use_module('sub/lr_d').
:- include(lr_inc).

a([B,C,D,I]) :- b(B), c(C), d(D), inc(I).
