### **Transfer custom IdP users:**

AWS Transfer Family authenticates each custom IdP user from the Secrets Manager
secret named `integration-hub-file-transfer/<environment>/transfer-users/<username>`.
The Lambda lower-cases the supplied username and retrieves that secret once for
both FTPS password authentication and SFTP public-key authentication.

The current secret version must be a JSON object containing `username`,
`password`, `publicKeys`, `ipv4_allow_list`, and `server_id_allow_list`. The
secret contains authentication and connection restriction data only.

Terraform provides the shared Transfer role, session policy, and logical home
directory configuration to the custom IdP Lambda. The Lambda returns these
Terraform-managed values after authenticating the user. AWS Transfer assumes
the role and applies the session policy, which restricts the user to the S3
prefix matching their lower-cased username. The logical home directory maps:

```text
/ -> /<incoming-bucket>/<username>
```

Terraform creates the initial record with a null password. A user cannot use
FTPS password authentication until an operator publishes a complete new secret
version with a non-null password.

Terraform intentionally ignores later secret value changes so credentials do
not enter Terraform state. Operators must publish a complete replacement JSON
record when changing a password, public keys, or restrictions; omitted fields
are not preserved automatically. Role, policy, and home directory fields in a
secret are ignored. Deleting the user secret disables that user's
authentication.
