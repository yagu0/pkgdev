#called when package is detached ( detach("package:pkg_name") )
.onDetach = function(libpath)
{
	library.dynam.unload("pkgTest", libpath)
}
