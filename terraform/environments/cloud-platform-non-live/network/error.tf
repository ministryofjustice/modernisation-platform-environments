data "external" "throw_error" {
    count = 1 # 0 means no error is thrown, else throw error
    program = ["idonotexist", "throw 'An error has ocurred.'"]
}
