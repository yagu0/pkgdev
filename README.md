# pkgdev: help to develop R packages

## NOTE: (mostly) superseded by devtools

However it was interesting to develop, and could still be used.

## Basic usage

	#Install and load library
	R CMD INSTALL path/to/pkgdev/folder
	library(pkgdev) #inside R

	#load some package (with its datasets)
	pkgpath = "path/to/some/package"
	pkgdev.load(pkgpath) #this command also reload package

	#test it (if unit tests defined under tests/ subfolders)
	pkgdev.rtest(pkgpath) ; pkgdev.ctest(pkgpath)

	#you can also run its functions
	foo(...) ; bar(...)

	#...and so on

	#finally, unload package
	pkgdev.unload(pkgpath)

Try also pkgTest/ testing package.

-----

Warning: old R package format - might require adjustments.
