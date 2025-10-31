package main

empty(value) {
	count(value) == 0
}

no_violations {
	empty(deny)
}

test_no_backends {
	deny["Adding backends is not allowed"] with input as {"terraform": {"backend": {}}}
}

test_no_providers {
	deny["Adding providers is not allowed"] with input as {"provider": {"aws": {}}}
}
