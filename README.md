# pkgdev: help to develop R packages

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
	pkgdev.unload(pkgpath)</code></pre>

Try also pkgTest/ testing package.
