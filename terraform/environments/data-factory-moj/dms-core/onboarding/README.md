# Configuration-driven sandbox onboarding

These service files use the existing test databases. The test harnesses
remain owned by the dms-core component.

They do not move the existing DMS resources into the new composition.

The onboarding_platform_bindings output provides the real network,
database, secret and target references. It contains no credential values,
but is sensitive to avoid printing infrastructure identifiers.

From the development workspace, export it with:

    terraform output -json onboarding_platform_bindings > platform.json

Using the updated configuration compiler:

    ingestion-config compile-directory --services onboarding/services --platform platform.json --generations onboarding/generations.json --output compiled.auto.tfvars.json

Write generated Terraform inputs in the separate deployment root that
will call configured-ingestion, not in the existing dms-core root.

Do not commit generated files containing environment identifiers.

Source preparation settings are exported separately through
onboarding_source_credentials. PostgreSQL uses the existing credential
sync function. Oracle uses connection_test.

The platform bindings retain PostgreSQL TLS and Oracle LogMiner settings.

New landing locations use configured-ingestion/ rather than the existing
integration-test task prefixes.

These files do not deploy the new composition by themselves. The deployment
root, published-document storage, publication and workflow integration
still need to be connected.
