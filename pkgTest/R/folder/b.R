b = function() {
	print("Hello, I'm b()")
	r = 0
	result = .C("d", result = as.integer(r), package="pkgTest")$result
	print(paste("The result is ", result))
}
