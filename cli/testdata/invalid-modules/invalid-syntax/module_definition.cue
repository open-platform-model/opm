package invalidsyntax

// This file has invalid CUE syntax - missing colons, wrong structure
metadata: {
	name = "invalid"  // Should be: name: "invalid"
	this is not valid CUE syntax!!!
}

components {  // Missing colon
	test "value"
}
