# Core function to execute C unit tests (or just show functions names)
.pkgdev.ctest = function(path, prefix, show, cc) {

    # Initial step: list every potential unit test under path/src/tests.
    allFuncNames = .parseCunitTests(file.path(path,"src","tests"))
    
    # Filter functions names matching prefix
    funcNames = grep( paste("^test_",prefix,sep=''), allFuncNames, value=TRUE )
    if (length(funcNames) == 0) return #shortcut: nothing to do...
    
    # If show==TRUE, display every potential test starting with prefix, and exit
    if (show) {
        #display in alphabetic order
        return (paste(sort(funcNames), sep='\n'))
    }
    
    # Get package name from path
    pathTokens = strsplit(path, c(.Platform$file.sep))[[1]]
    pkgName = pathTokens[length(pathTokens)]
    
    # Generate main.c to run exactly the tests asked by user
    .generateMainCall(funcNames, pkgName)
    
    # Get all C source files (src/tests/*, src/sources/* ...)
    cFilesUser = c(
        list.files(file.path(path,"src","tests"),pattern="\\.[cChH]$",
                   full.names=TRUE,recursive=TRUE),
        list.files(file.path(path,"src","sources"),pattern="\\.[cChH]$",
                   full.names=TRUE,recursive=TRUE))
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    cFilesPkdev = c(
        "main.c", #above generated main.c
        file.path(pkdev_path,"src","tests","unitTestsMacros.c")) #C unit tests macros
    
    # Now generate appropriate Makefile based on C sources and headers
    pathTokens = strsplit(path, c(.Platform$file.sep))[[1]]
    pkgName = pathTokens[length(pathTokens)]
    .generateMakefileTest(path, cFilesUser, cFilesPkdev, pkgName, cc)
    
    # Run selected tests (after 'funcs' filter applied)
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    save_wd = getwd()
    setwd( file.path(pkdev_path,"pkgs",pkgName,"src","tests") )
    library(parallel)
    system( paste( Sys.getenv("MAKE"), "depend", sep=' ') )
    system( paste( Sys.getenv("MAKE"), "-j", detectCores(), "all", sep=' ') )
    system("./runTests")
    setwd(save_wd)
}

# Recursively explore initial path to parse source files for unit tests.
.parseCunitTests = function(path) {

    # Unit test names to return
    funcNames = c()
    
    # For each file in current folder
    for (fileName in list.files(path, full.names=TRUE, recursive=TRUE)) {
    
        # If the file is not a source, skip
        if ( length( grep("\\.[CcHh]$", fileName) ) == 0) next
        
        # Every test function has a name starting with "test_"
        matches = grep(
            "^[ \t]*void[ \t]*test_[a-zA-Z0-9_]*[ \t]*\\(.*",
            scan(fileName, what="character", sep='\n'),
            value = TRUE)

        # We matched more to be 100% sure we got test functions, but need to strip now
        funcNames = c(funcNames, sub(
            "^[ \t]*void[ \t]*(test_[a-zA-Z0-9_]*)[ \t]*\\(.*",
            "\\1",
            matches))
    }
    
    return (funcNames)
}

# Generate main.c file under R_HOME_USER/pkgdev/pkgs/pkgName/src/tests
.generateMainCall = function(funcNames, pkgName) {

    # Build text file main.c
    mainDotC = '
#include <stdlib.h>
#include <stdio.h>
#include <time.h> // to print timings

void main() {
    clock_t start, end;
'
    for (funcName in funcNames) {
        mainDotC = paste(mainDotC, "printf(\">>> Running ",funcName,"\\n\");\n",sep='')
        mainDotC = paste(mainDotC, "start = clock();\n", sep='')
        mainDotC = paste(mainDotC, funcName, "();\n", sep='')
        mainDotC = paste(mainDotC, "end = clock();\n", sep='')
        mainDotC = paste(mainDotC, "printf(\">>> ... completed in %.3fs.\\n\",((double) (end - start)) / CLOCKS_PER_SEC);\n", sep='')
    }
    mainDotC = paste(mainDotC, "}\n", sep='')
    
    # Write it on disk
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    dir.create(file.path(pkdev_path,"pkgs",pkgName,"src","tests"), recursive=TRUE, showWarnings=FALSE)
    writeLines(mainDotC, file.path(pkdev_path,"pkgs",pkgName,"src","tests","main.c"))
}

# Generate appropriate Makefile under R_HOME_USER/pkgdev/pkgs/pkgName/src/tests
.generateMakefileTest = function(path, cFilesUser, cFilesPkdev, pkgName, cc) {

    # Preparation: separate cFiles into codes and headers
    codeFilesUser = grep(".*(c|C)$", cFilesUser, value=TRUE)
    codeFilesPkdev = grep(".*(c|C)$", cFilesPkdev, value=TRUE)
    headerFiles = grep(".*(h|H)$", c(cFilesUser,cFilesPkdev), value=TRUE)
    
    # objectFiles = all .o files in current folder, duplicating file structure under path/src/
    basePathFrom = file.path(path, "src")
    pkdev_path = file.path(Sys.getenv("R_HOME_USER"), "pkgdev")
    basePathTo = file.path(pkdev_path,"pkgs",pkgName,"src","tests")
    for (fileOrDir in list.files(basePathFrom, recursive=TRUE, include.dirs=TRUE)) {
        if (file.info(file.path(basePathFrom,fileOrDir))$isdir) {
            # Process folders only
            dir.create(file.path(basePathTo,fileOrDir),showWarnings=FALSE,recursive=TRUE)
        }
    }
    objectFiles = c()
    for (codeFileUser in codeFilesUser) {
        objectFiles = c(
            objectFiles, 
            sub("(.*)\\.(c|C)$","\\1\\.o", sub(basePathFrom,basePathTo,codeFileUser,fixed=TRUE)))
    }
    for (codeFilePkdev in codeFilesPkdev) {
        objectFiles = c(
            objectFiles, 
            sub("(.*)\\.(c|C)$","\\1\\.o", codeFilePkdev))
    }
    
    # Build Makefile
    makefile = paste('
CC = ', cc, '
INCLUDES = 
LIBRARIES = -lm
CFLAGS = -g
LDFLAGS = 
EXEC = runTests
SRCS = ', paste(
            paste(codeFilesUser,sep='',collapse=' '),
            paste(codeFilesPkdev,sep='',collapse=' '),
            sep=' '), '
HEDS = ', paste(headerFiles, sep='', collapse=' '), '
OBJS = ', paste(objectFiles, sep='', collapse= ' '), '
all: $(EXEC)
$(EXEC) : $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $(EXEC) $(LIBRARIES)', sep='')
    compileObjects = ""
lengthCodeFilesUser = length(codeFilesUser)
for (i in 1:lengthCodeFilesUser) {
    compileObjects = paste(compileObjects, '
', objectFiles[i], ' : ', codeFilesUser[i], '
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@', sep='')
}
for (i in 1:length(codeFilesPkdev)) {
    compileObjects = paste(compileObjects, '
', objectFiles[i+lengthCodeFilesUser], ' : ', codeFilesPkdev[i], '
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@', sep='')
}
    makefile = paste(makefile, compileObjects, '
.PHONY: clean delex depend
clean:
	rm -f $(OBJS) ./.depend
delex:
	rm -f $(EXEC)
depend: .depend
.depend: $(SRCS) $(HEDS)
	rm -f ./.depend
	$(CC) -MM $^ > ./.depend
include .depend
', sep='')

    # Write it to disk
    writeLines(makefile, file.path(pkdev_path,"pkgs",pkgName,"src","tests","Makefile"))
}
