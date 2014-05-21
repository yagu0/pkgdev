# Setup a file structure under R_HOME/pkgdev/ to run later tests
# @param atInstall Logical, TRUE if invoked at package installation
.pkgdev.setup = function(reset=FALSE) {

    # environment variable R_HOME_USER must be set: everything starts here
    if (Sys.getenv("R_HOME_USER") == "") {
        cat("*** WARNING: for pkgdev to work properly, you need to specify\n")
        cat("*** an environment variable R_HOME_USER in a .Renviron file.\n")
        cat("*** Standard choice is /home/userName/.R under UNIX systems,\n")
        cat("*** or maybe C:/Users/userName/Documents/R under Windows")
        stop("Please specify R_HOME_USER before using pkgdev")
    }
    
    # create convenient folders and files, if not already existing
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    
    # clean up: wipe possibly existing pkgdev/ contents
    if (reset) {
        unlink(pkdev_path, recursive=TRUE)
        unlink(pkdev_path, recursive=TRUE) #bug?
    }
    
    # copy file structure only if directory is absent
    if (file.exists(pkdev_path)) return (NULL)
    
    # create testing file structure under pkgdev/
    dir.create(pkdev_path)
    dir.create( file.path(pkdev_path,"R") )
    dir.create( file.path(pkdev_path,"R","tests") )
    writeLines(RunitTestsMethods, file.path(pkdev_path,"R","tests","unitTestsMethods.R"))
    dir.create( file.path(pkdev_path,"src") )
    dir.create( file.path(pkdev_path,"src","tests") )
    writeLines(CunitTestsMacros, file.path(pkdev_path,"src","tests","unitTestsMacros.c"))
    dir.create( file.path(pkdev_path,"pkgs") )
}
