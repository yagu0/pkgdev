# Core function to unload a package (UNsource R files and unload C libraries)
# @param path Location or name of the (non-standard) package to be unloaded
.pkgdev.unload = function(path) {

    # Get package name from path
    pathTokens = strsplit(path, c(.Platform$file.sep))[[1]]
    pkgName = pathTokens[length(pathTokens)]
    
    # This file tells if the package is currently loaded
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    pkgLoadFile = file.path(pkdev_path,"pkgs",pkgName,"loaded")
    
    # Unload shared library (if any)
    if (file.exists(pkgLoadFile)) {
        sharedLib = file.path(pkdev_path,"pkgs",pkgName,paste(pkgName,.Platform$dynlib.ext,sep=''))
        dyn.unload(sharedLib)
        unlink(pkgLoadFile)
    }
}
