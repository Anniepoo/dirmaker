#!/usr/bin/swipl -q -t main -f
:- module(dirmaker, []).


dirmaker_opts(
    [
        [   opt(nofiles),
	    type(boolean),
	    default(false),
            shortflags([nf]),
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
	opt_arguments(OptSpec, Opts, [Infile, BaseDir]),
	do_dirmaker_helper(Opts, Infile, BaseDir).
do_dirmaker(_) :-
	dirmaker_opts(OptSpec),
	opt_help(OptSpec, Help),
	format(user_error, '~w~n', [Help]).

do_dirmaker_helper(Options, Infile, BaseDir) :-
	member(nf(true), Options),!,
	dirmaker(notouch, Infile, BaseDir).
do_dirmaker_helper(Options, Infile, BaseDir) :-
	member(files(Exemplars), Options),
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
	!, % make debugging much easier
	process_line(Codes, FileGoal, BaseDir).

process_line(end_of_file, _, _).
process_line(Line, FileGoal, BaseDir) :-
	append(Dir, ":", Line),
	working_directory(_, Dir),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	append(_, "/", Line),
	working_directory(WD, WD),
	absolute_file_name(Line, Abs, [relative_to(WD)]),
	force_exists_dir(Abs),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	append(File, "@", Line),
	call(FileGoal, File),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	append(File, "*", Line),
	call(FileGoal, File),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	maplist(iswhite, Line),
	next_line(FileGoal, BaseDir).
process_line(Line, FileGoal, BaseDir) :-
	call(FileGoal, Line),
	next_line(FileGoal, BaseDir).

iswhite(X) :- code_type(X, white).

force_exists_dir(Abs) :-
	exists_directory(Abs),
	!.
force_exists_dir(Abs) :-
	file_directory_name(Abs, Dir),
	make_directory(Dir).

exemplar(Dir, File) :-
	file_name_extension(_, Ext, File),
	directory_files(Dir, AFile),
	file_name_extension(_, Ext, AFile),
	atom_concat(Dir, AFile, APath),
	absolute_file_name(File, NewPath),
	link_file(APath, NewPath, symbolic).
touch(File)  :-
	open(File, write, Stream),
	close(Stream).
notouch(_).

:- style_check(-atom).
user:main(Argv) :-
        catch(do_dirmaker(Argv), E, (print_message(error, E), fail)),
        halt.
user:main(_) :-
	writeln('Usage:'),
	writeln("dirmaker <options> <infile> <basedir>\
\
There are only two options\
\
   -f  <dir>\
   or\
   --files  <dir>\
   on encountering a non-directory file in the ls, look for a file with similar extension,\
   or, if the file has no extension, the same name, in <dir> and symlink that file.\
   if -f is omitted a length zero file will be created (a la \'touch\')\
\
   -nf\
   or\
   --nofiles\
   Don't create any files/symlinks (overrides -f)\
\
examples:\
dirmaker.pl /path/to/myfile  /path/to/dir\
\
dirmaker -f /path/for/exemplars  /path/to/myfile  /path/to/dir"),
        halt(1).
:- style_check(+atom).


