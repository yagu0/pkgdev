# Core function to execute R unit tests (or just show functions names)
.pkgdev.rtest = function(path, prefix, show, cc) {

    # Initial step: list every potential unit test under path/R/tests.
    allFuncNames = .parseRunitTests(file.path(path,"R","tests"))

    # Filter functions names matching prefix
    funcNames = grep( paste("^test_",prefix,sep=''), allFuncNames, value=TRUE )
    if (length(funcNames) == 0) return #shortcut: nothing to do...
    
    # If show==TRUE, display every potential test starting with prefix, and exit
    if (show) {
        #display in alphabetic order
        return (paste(sort(funcNames), sep='\n'))
    }
    
    # Source all R unit test files
    rFiles = list.files(file.path(path,"R","tests"), 
             pattern="\\.[RrSsq]$", full.names=TRUE, recursive=TRUE)
    lapply(rFiles, source)
    
    # Source R file containing unit tests methods
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    source(file.path(pkdev_path,"R","tests","unitTestsMethods.R"))
    
    # Get package name from path
    pathTokens = strsplit(path, c(.Platform$file.sep))[[1]]
    pkgName = pathTokens[length(pathTokens)]
    
    # This file tells if the package is currently loaded
    pkgLoadFile = file.path(pkdev_path,"pkgs",pkgName,"loaded")
    
    # Now manually load package (may not be installable if non-flat)
    pkgAlreadyLoaded = file.exists(pkgLoadFile)
    .pkgdev.load(path, cc)
    
    # Run selected tests (after 'funcs' filter applied)
    for (funcName in funcNames) {
        cat(">>> Running ",funcName,"\n",sep='')
        func = match.fun(funcName)
        execTime = as.numeric(system.time(func())[1])
        cat(">>> ... completed in ",execTime,"s.\n",sep='')
    }
    
    # Unload shared library if it wasn't already loaded
    if (!pkgAlreadyLoaded) .pkgdev.unload(path)
}

# Recursively explore initial path to parse source files for unit tests.
.parseRunitTests = function(path) {

    # Unit test names to return
    funcNames = c()
    
    # For each file in current folder
    for (fileName in list.files(path, full.names=TRUE, recursive=TRUE)) {
    
        # If the file is not a source, skip
        if ( length( grep("\\.[RrSsq]$", fileName) ) == 0) next
        
        # Every test function has a name starting with "test_"
        matches = grep(
            "^[ \t]*test_[a-zA-Z0-9_]*[ \t]*(=|<-)[ \t]*function.*",
            scan(fileName, what="character", sep='\n', quiet=TRUE),
            value = TRUE)
        
        # We matched more to be 100% sure we got test functions, but need to strip now
        funcNames = c(funcNames, sub(
            "^[ \t]*(test_[a-zA-Z0-9_]*)[ \t]*(=|<-)[ \t]*function.*",
            "\\1",
            matches))
    }
    
    return (funcNames)
}
