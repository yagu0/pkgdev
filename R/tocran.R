# Convert a package with custom sub-folders to a valid CRAN package
# @param inPath Input path: location of the package to flatten
# @param outPath Output path: location of the package to create
.pkgdev.tocran = function(inPath, outPath) {

    # Gather all R source files (no tests)
    fullPathRfiles = c()
    forbiddenPath = file.path(inPath,"R","tests")
    for (fileOrDir in list.files(file.path(inPath,"R"),full.names=TRUE)) {
        if (fileOrDir != forbiddenPath) {
            if (file.info(fileOrDir)$isdir) {
                fullPathRfiles = c(
                    fullPathRfiles,
                    list.files(fileOrDir,pattern="\\.[RrSsq]$",
                               recursive=TRUE,full.names=TRUE))
            }
            else fullPathRfiles = c(fullPathRfiles, fileOrDir)
        }
    }
    # Truncate paths: only suffix in pkgname/R/suffix is useful
    fullPathRfiles = sub(
        paste(inPath,.Platform$file.sep,"R",.Platform$file.sep,sep=''),
        "",
        fullPathRfiles,
        fixed=TRUE)
    
    # Transform rFiles until no folder separator can be found
    rFiles = fullPathRfiles
    while (length(grep(.Platform$file.sep,rFiles)) > 0) {
        rFiles = lowerFileDepth(rFiles)
    }
    
    # Create and fill every non-sensible folder on output path
    unlink(outPath, recursive=TRUE) #in case of [TODO: warn user]
    dir.create(outPath, showWarnings=FALSE)
    forbiddenPath = "R"
    for (fileOrDir in list.files(inPath)) {
        if (fileOrDir != forbiddenPath) {
            if (file.info(file.path(inPath,fileOrDir))$isdir) {
                dir.create(file.path(outPath,fileOrDir), showWarnings=FALSE, recursive=TRUE)
                file.copy(file.path(inPath,fileOrDir), file.path(outPath),recursive=TRUE)
            }
            else file.copy(file.path(inPath,fileOrDir), file.path(outPath))
        }
    }
    
    # Prepare R folder (empty for the moment)
    dir.create( file.path(outPath,"R") )
    
    # Copy "flattened" files to R/
    for (i in 1:length(rFiles)) {
        file.copy( file.path(inPath,"R",fullPathRfiles[i]),
                   file.path(outPath,"R",rFiles[i]) )
    }
    
    # Optional processing if /src is present
    if (file.exists(file.path(inPath,"src"))) {
    
        # Gather all C code files (NOT including headers; no tests)
        cCodeFiles = c()
        forbiddenPath = file.path(inPath,"src","tests")
        for (fileOrDir in list.files(file.path(inPath,"src"),full.names=TRUE)) {
            if (fileOrDir != forbiddenPath) {
                if (file.info(fileOrDir)$isdir) {
                    cCodeFiles = c(
                        cCodeFiles,
                        list.files(fileOrDir,pattern="\\.[Cc]$",
                                   recursive=TRUE,full.names=TRUE))
                }
                else cCodeFiles = c(cCodeFiles, fileOrDir)
            }
        }
        # Truncate paths: only suffix in pkgname/R/suffix is useful
        cCodeFiles = sub(
            paste(inPath,.Platform$file.sep,"src",.Platform$file.sep,sep=''),
            "",
            cCodeFiles,
            fixed=TRUE)
        
        # Add a 'Makevars' file under src/ to allow compilation by R CMD INSTALL
        makevars = paste(
            paste("SOURCES","=",paste(cCodeFiles,sep='',collapse=' '),"\n",sep=' '),
            paste("OBJECTS","=","$(SOURCES:.c=.o)","\n",sep=' '),
            sep='\n')
        writeLines(makevars, file.path(outPath,"src","Makevars"))
    }
}

# NOTE: rule = sort according to first subfolder, then place 1 for the first ...etc;
# for example tr1/tr2/tr3/file.c --> tr2/tr3/file_1.c --> tr3/file_12.c ...etc
lowerFileDepth = function(files) {

    # Sort files according to their prefix paths
    sortedFiles = sort(files, index.return=TRUE)
    
    # Truncate paths if required
    folderKount = 0
    lastFolder = ""
    for (i in 1:length(files)) {
        if (length(grep(.Platform$file.sep, sortedFiles$x[i], fixed=TRUE)) > 0) {
            prefix = strsplit(sortedFiles$x[i], c(.Platform$file.sep))[[1]][1]
            if (prefix != lastFolder) {
                folderKount = folderKount + 1
                lastFolder = prefix
            }
            sortedFiles$x[i] = paste(
                #truncate base name
                substr(sortedFiles$x[i],nchar(prefix)+2,nchar(sortedFiles$x[i])-2),
                #add [sub-]folder identifier
                folderKount,
                #add suffix (.R, .r ...) de
                substr(sortedFiles$x[i],nchar(sortedFiles$x[i])-1,nchar(sortedFiles$x[i])),
                sep='')
        }
    }
    
    # Return transformed files list ranked as in input (unsorted)
    for (i in 1:length(files)) {
        files[ sortedFiles$ix[i] ] = sortedFiles$x[i]
    }
    return (files)
}
