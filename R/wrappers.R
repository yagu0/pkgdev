# Main wrapped entry point: call package function 'func'
.execMethod = function(func, ...) {

    # check for R_HOME_USER variable, and for R_HOME_USER/pkgdev folder
    .pkgdev.setup()
    
    # get appropriate core function and call it
    func = match.fun(func)
    func(...)
}

#' Reset pkgdev folder under R_HOME_USER
#' WARNING: all loaded packages will have to be rebuilt
pkgdev.wipeAll = function() {
    .pkgdev.setup(reset=TRUE)
}

#' Load a package containing arbitrary file structures under R/ and src/{adapters,sources}
#'
#' @param path Location of the package to load
#' @param cc Compilator to be used (e.g. 'gcc -std=gnu99' [default])
pkgdev.load = function(path, cc="gcc -std=gnu99") {
    path = normalizePath(path) #allow to give only pkg name (in pkg/.. folder)
    .execMethod(".pkgdev.load", path, cc)
}

#' Unload a package containing arbitrary file structures under R/ and src/{adapters,sources}
#'
#' @param path Location or name of the package to unload
pkgdev.unload = function(path) {
    path = normalizePath(path) #allow to give only pkg name (in pkg/.. folder)
    .execMethod(".pkgdev.unload", path)
}

#' Wipe a specific package under R_HOME_USER/pkgdev/pkgs/
#' NOTE: when this package will be loaded again, it will be completely rebuilt
#'
#' @param pkgName Name of the package to be removed
pkgdev.clean = function(pkgName) {
    unlink(file.path(Sys.getenv("R_HOME_USER"),"pkgdev","pkgs",pkgName), recursive=TRUE)
    unlink(file.path(Sys.getenv("R_HOME_USER"),"pkgdev","pkgs",pkgName), recursive=TRUE) #bug?
}

#' Launch R unit tests (arbitrary file structure under R/tests), or display the list of test functions
#'
#' @param path Location of the package containing tests (under /R/tests)
#' @param prefix Prefix for names of the functions to be tested; leave empty to test all (default)
#' @param show Logical, TRUE to display the list of unit tests (default: FALSE)
pkgdev.rtest = function(path, prefix="", show=FALSE, cc="gcc -std=gnu99") {
    path = normalizePath(path) #allow to give only pkg name (in pkg/.. folder)
    .execMethod(".pkgdev.rtest", path, prefix, show, cc)
}

#' Launch C unit tests (arbitrary file structure under src/tests), or display the list of test functions
#'
#' @param path Location of the package containing tests (under /src/tests)
#' @param prefix Prefix for names of the functions to be tested; leave empty to test all (default)
#' @param show Logical, TRUE to display the list of unit tests (default: FALSE)
pkgdev.ctest = function(path, prefix="", show=FALSE, cc="gcc -std=gnu99") {
    .execMethod(".pkgdev.ctest", path, prefix, show, cc)
}

#' "Flatten" a package: gather all sources under R/ and src/ without hierarchical file structure
#'
#' @param inPath Input path: location of the package to flatten
#' @param outPath Output path: location of the package to create [default: inPath_cran]
pkgdev.tocran = function(inPath, outPath=NULL) {
    inPath = normalizePath(inPath) #allow to give only pkg name (in pkg/.. folder)
    if (is.null(outPath)) outPath = paste(inPath, "_cran", sep='')
    .execMethod(".pkgdev.tocran", inPath, outPath)
}

#' Invoke R CMD check on a flat package (maybe with optional arguments, like --as-cran)
#'
#' @param opts Vector of strings arguments to pass to R CMD CHECK
pkgdev.check = function(path, opts) {
    path = normalizePath(path) #allow to give only pkg name (in pkg/.. folder)
    system( paste("R CMD check", opts, path, sep=' ') )
}
