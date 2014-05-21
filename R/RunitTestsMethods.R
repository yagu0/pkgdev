# Functions to assert that conditions are true or false in R unit tests

RunitTestsMethods = '
# Functions to assert that a condition is true or false [to be extended]
assertTrue = function(condition, message, context="") {
    if (!condition) {
        cat("Failure: ", message, sep=\'\')
        if (context != "") cat(" [",context,"]")
        cat("\\n")
    }
}

assertFalse = function(condition, message, context="") {
    assertTrue(!condition, message, context)
}
'
