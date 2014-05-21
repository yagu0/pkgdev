# Core function to load a package (source R files and compile/load C libraries)
# @param path Location of the (non-standard) package to be loaded
# @param cc Compilator to be used (e.g. 'gcc -std=gnu99' [default])
.pkgdev.load = function(path, cc) {

    # Get package name from path
    pathTokens = strsplit(path, c(.Platform$file.sep))[[1]]
    pkgName = pathTokens[length(pathTokens)]
    
    # Create base directory for pkgName under R_HOME_USER/pkgdev/pkgs/pkgName (if not existing)
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    dir.create(file.path(pkdev_path,"pkgs",pkgName), showWarnings=FALSE)
    
    # R code first
    # Warning: R/tests folder should not be sourced
    forbiddenPath = file.path(path,"R","tests")
    for (fileOrDir in list.files( file.path(path,"R"),full.names=TRUE )) {
        if (fileOrDir != forbiddenPath) {
            if (file.info(fileOrDir)$isdir) {
                rFiles = list.files(fileOrDir, pattern="\\.[RrSsq]$",
                         full.names=TRUE, recursive=TRUE)
                # NOTE: potential unexported functions are not hidden;
                # the developer is assumed to handle this
                lapply(rFiles, source)
            }
            else source(fileOrDir)
        }
    }
    
    # Also load datasets (if any)
    rData = list.files(file.path(path,"data"),pattern="\\.R(d|D)ata$",full.names=TRUE)
    lapply(rData, load)
    
    # This file tells if the package is currently loaded
    pkgLoadFile = file.path(pkdev_path,"pkgs",pkgName,"loaded")
    
    if (file.exists(file.path(path,"src"))) {
        # C code -- Warning: src/tests folder should not be listed
        cFiles = c(
            list.files( file.path(path,"src","adapters"), pattern="\\.[cChH]$",
                full.names=TRUE, recursive=TRUE ),
            list.files( file.path(path,"src","sources"), pattern="\\.[cChH]$",
                full.names=TRUE, recursive=TRUE ))
        
        # Create folder R_HOME_USER/pkgdev/pkgs/pkgName/src (if not existing)
        dir.create(file.path(pkdev_path,"pkgs",pkgName,"src"), showWarnings=FALSE)
        
        # Generate suitable Makefile (all object files go at R_HOME_USER/pkgdev/pkgs/pkgName/src)
        .generateMakefileLoad(path, cFiles, pkgName, cc)
        
        # Compile in the right folder (R_HOME_USER/pkgdev/pkgs/pkgName/src)
        save_wd = getwd()
        setwd( file.path(pkdev_path,"pkgs",pkgName,"src") )
        library(parallel)
        system( paste( Sys.getenv("MAKE"), "depend", sep=' ') )
        system( paste( Sys.getenv("MAKE"), "-j", detectCores(), "all", sep=' ') )
        setwd(save_wd)
        
        # Finally load library
        sharedLib = 
            file.path(pkdev_path,"pkgs",pkgName,paste(pkgName,.Platform$dynlib.ext,sep=''))
        if (file.exists(pkgLoadFile)) dyn.unload(sharedLib)
        dyn.load(sharedLib)
    }
    
    # Mark package as 'loaded'
    writeLines("loaded",pkgLoadFile)
}

# Generate appropriate Makefile under R_HOME_USER/pkgdev/pkgs/pkgName/src
.generateMakefileLoad = function(path, cFiles, pkgName, cc) {
    
    # Preparation: separate cFiles into codes and headers
    codeFiles = grep(".*(c|C)$", cFiles, value=TRUE)
    headerFiles = grep(".*(h|H)$", cFiles, value=TRUE)
    
    # objectFiles = all .o files in current folder, duplicating file structure under path/src/
    basePathFrom = file.path(path, "src")
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    basePathTo = file.path(pkdev_path,"pkgs",pkgName,"src")
    for (fileOrDir in list.files(basePathFrom, recursive=TRUE, include.dirs=TRUE)) {
        if (file.info(file.path(basePathFrom,fileOrDir))$isdir) {
            # Process folders only
            dir.create(file.path(basePathTo,fileOrDir),showWarnings=FALSE,recursive=TRUE)
        }
    }
    objectFiles = c()
    for (codeFile in codeFiles) {
        objectFiles = c(
            objectFiles, 
            sub("(.*)\\.(c|C)$","\\1\\.o", sub(basePathFrom,basePathTo,codeFile,fixed=TRUE)))
    }
    
    # Build Makefile
    makefile = paste('
CC = ', cc, '
INCLUDES = -I/usr/include/R/ -I/usr/local/include -I/usr/share/R/include
LIBRARIES = -L/usr/lib -L/usr/lib/R/lib -lR -lm
CFLAGS = -DNDEBUG -fpic -march=native -mtune=generic -O2 -pipe \\
         -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2
LDFLAGS = -shared -Wl,-O1,--sort-common,--as-needed,-z,relro
LIB = ', paste(file.path("..",pkgName), .Platform$dynlib.ext, sep=''), '
SRCS = ', paste(codeFiles, sep='', collapse=' '), '
HEDS = ', paste(headerFiles, sep='', collapse=' '), '
OBJS = ', paste(objectFiles, sep='', collapse= ' '), '
all: $(LIB)
$(LIB) : $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $(LIB) $(LIBRARIES)', sep='')
    compileObjects = ""
for (i in 1:length(codeFiles)) {
    compileObjects = paste(compileObjects, '
', objectFiles[i], ' : ', codeFiles[i], '
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@', sep='')
}
    makefile = paste(makefile, compileObjects, '
.PHONY: clean delib depend
clean:
	rm -f $(OBJS) ./.depend
delib:
	rm -f $(LIB)
depend: .depend
.depend: $(SRCS) $(HEDS)
	rm -f ./.depend
	$(CC) -MM $^ > ./.depend
include .depend
', sep='')

    # Write it to disk
    writeLines(makefile, file.path(pkdev_path,"pkgs",pkgName,"src","Makefile"))
}
