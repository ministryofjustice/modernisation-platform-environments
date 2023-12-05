#### This file can be used to store locals specific to the member account ####

locals {

app_data = jsondecode(file("./application_variables.json"))

}