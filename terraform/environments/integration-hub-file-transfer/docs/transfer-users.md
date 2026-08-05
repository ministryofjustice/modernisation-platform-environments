### **Transfer custom IdP users:**

AWS Transfer Family authenticates each custom IdP user from the Secrets Manager
secret named `integration-hub-file-transfer/<environment>/transfer-users/<username>`.
The Lambda lower-cases the supplied username and retrieves that secret once for
both FTPS password authentication and SFTP public-key authentication.

The current secret version must be a JSON object containing `username`,
`password`, `publicKeys`, `Role`, `Policy`, `HomeDirectoryType`,
`ipv4_allow_list`, and `server_id_allow_list`.

For `HomeDirectoryType = "LOGICAL"`, include `HomeDirectoryDetails` to map
virtual paths, such as `/`, to specific S3 locations. This lets the user see a
simple directory structure without exposing the underlying bucket path. For
`HomeDirectoryType = "PATH"`, include `HomeDirectory` to place the user directly
at that path. `PosixProfile` is optional.

Terraform creates the initial record with a null password. A user cannot use
FTPS password authentication until an operator publishes a complete new secret
version with a non-null password.

Terraform intentionally ignores later secret value changes so credentials do
not enter Terraform state. Operators must publish a complete replacement JSON
record when changing a password, public keys, home directory, restrictions,
role, or policy; omitted fields are not preserved automatically. Deleting the
user secret disables that user's authentication.