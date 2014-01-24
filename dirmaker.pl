#!/usr/local/bin/swipl -s dirmaker.pl -g go
:- module(dirmaker, []).


dirmaker_opts(
    [
        [   opt(nofiles),
	    type(boolean),
	    default(false),
            shortflags([n]),
	    longflags(['nofiles']),
            help('Don\'t create files')],

	[   opt(files),
	    type(atom),
	    shortflags([f]),
	    longflags(['files']),
            help('Directory for exemplar files')]
	]
).
% TODO the arg is Argv
% TODO replace this with optparse
do_dirmaker(_) :-
	dirmaker_opts(OptSpec),
	opt_arguments(OptSpec, Opts, [_, Infile, BaseDir]),
	working_directory(WD, WD),
	absolute_file_name(BaseDir, AbsBaseDir),
	do_dirmaker_helper(Opts, Infile, AbsBaseDir).
do_dirmaker(_) :-
	dirmaker_opts(OptSpec),
	opt_help(OptSpec, Help),
	format(user_error, 'Usage: swipl -s dirmaker.pl -g go -- <options> <infile> <basedir>~nOptions:~n~w~n', [Help]).

do_dirmaker_helper(Options, Infile, BaseDir) :-
	member(nofiles(true), Options),!,
	dirmaker(notouch, Infile, BaseDir).
do_dirmaker_helper(Options, Infile, BaseDir) :-
	member(files(Exemplars), Options),
	ground(Exemplars),
	dirmaker(exemplar(Exemplars), Infile, BaseDir).
do_dirmaker_helper(_, Infile, BaseDir) :-
	dirmaker(touch, Infile, BaseDir).

dirmaker(FileGoal, Infile, BaseDir) :-
	prolog_to_os_filename(Pinfile, Infile),
	current_input(OldInStream),
	setup_call_cleanup(
	    open(Pinfile, read, InStream),
	    (
		set_input(InStream),
		prolog_to_os_filename(PBaseDir, BaseDir),
		working_directory(_, PBaseDir),
		next_line(FileGoal, BaseDir)
	    ),
	    close(InStream)
	),
	set_input(OldInStream).

next_line(FileGoal, BaseDir) :-
	current_input(S),
	read_line_to_codes(S, Codes),
	string_codes(String, Codes),
	!, % make debugging much easier
	process_line(String, FileGoal, BaseDir).


concat_file_path(Rel, Base, Abs) :-
	string_concat(_, "/", Base),
	cchelper(Rel, Base, Abs).
concat_file_path(Rel, Base, Abs) :-
	string_concat(Base, "/", BBase),
	cchelper(Rel, BBase, Abs).

cchelper(Rel, Base, Abs) :-
	string_concat("./", Rest, Rel),
	string_concat(Base, Rest, Abs).
cchelper(Rel, Base, Abs) :-
	string_concat("/", Rest, Rel),
	string_concat(Base, Rest, Abs).
cchelper(Rel, Base, Abs) :-
	string_concat(Base, Rel, Abs).

process_line(end_of_file, _, _).
process_line(".:", FileGoal, BaseDir) :-
	working_directory(_, BaseDir),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	string_concat(Dir, ":", Line),
	concat_file_path(Dir , BaseDir , Abs),
	working_directory(_, Abs),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	string_concat(_, "/", Line),
	working_directory(WD, WD),
	concat_file_path(Line, WD, Abs),
	force_exists_dir(Abs),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	string_concat(File, "@", Line),
	call(FileGoal, File),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	string_concat(File, "*", Line),
	call(FileGoal, File),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	string_codes(Line, CLine),
	maplist(iswhite, CLine),
	next_line(FileGoal, BaseDir).
process_line("", FileGoal, BaseDir) :-
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	call(FileGoal, Line),
	next_line(FileGoal, BaseDir).

iswhite(X) :- code_type(X, white).

force_exists_dir(Abs) :-
	exists_directory(Abs),
	!.
force_exists_dir(Abs) :-
	format('making ~w~n', [Abs]),
	make_directory(Abs).

exemplar(Dir, File) :-
	file_name_extension(_, Ext, File),
	directory_files(Dir, AFile),
	file_name_extension(_, Ext, AFile),
	atom_concat(Dir, AFile, APath),
	absolute_file_name(File, NewPath),
	link_file(APath, NewPath, symbolic).
exemplar(_, File) :-
	touch(File).
touch(File)  :-
	format('touching ~w~n', [File]),
	open(File, write, Stream),
	format(Stream, 'x~n', []),
	close(Stream).
notouch(_).

user:go :-
        catch(do_dirmaker([]), E, (print_message(error, E), fail)).




