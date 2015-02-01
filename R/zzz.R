#called by library(pkgdev)
.onAttach = function(libname, pkgname) {
	#wipe all previous "loaded" tags
	R_HOME_USER = Sys.getenv("R_HOME_USER")
	if (R_HOME_USER != "") {
		pkgdevPackagesPath = file.path( Sys.getenv("R_HOME_USER"),"pkgdev","pkgs" )
		for (package in list.dirs(pkgdevPackagesPath, recursive=FALSE))
			file.remove(file.path(package,"loaded"))
	}
}
