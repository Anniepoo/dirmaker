---++   dirmaker

A small tool that takes a file made by 

ls -R > myfile

and recreates that directory structure using dummy files.

This assumes you're using linux file conventions (that is, the ls command has to be on,
or at least produce, unix style /paths/with/forward/slashes/and/no/volume/letter

directories and files are created with the current umask, owner, and group.



---+++  Usage

You will need [[http://swi-prolog.org  SWI-Prolog]] 

then run 

dirmaker <options> <infile> <basedir>

There are only two options

   -f  <dir>
   or  
   --files  <dir>       
   on encountering a non-directory file in the ls, look for a file with similar extension,
   or, if the file has no extension, the same name, in <dir> and symlink that file.
   if -f is omitted a length zero file will be created (a la 'touch')
   
   -nf
   or
   --nofiles
   Don't create any files/symlinks (overrides -f) 

examples:
dirmaker.pl /path/to/myfile  /path/to/dir

dirmaker -f /path/for/exemplars  /path/to/myfile  /path/to/dir


---+++ Why is this useful?

When working on projects with large asset stores (e.g. games, movies, download sites, picture sharing sites) in file systems, every developer needs a copy of the asset store, or they all
need to be local so they can mount the assets, or they need some other kludge. 
Usually they don't need the actual assets, just the directory structure.










