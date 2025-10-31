# Shared Terraform Modules

## Introduction

This folder contains the Modernisation Platform user contributed shared Terraform modules.

Any Modernisation Platform user can contribute to modules in this folder or use them.

This folder allows users to rapidly create shared modules, these modules can later be moved out into their own repository if needed.

## Contributing guidelines

1. Check that a module for your use case doesn't already exist [as a Modernisation Platform maintained module](https://github.com/ministryofjustice/modernisation-platform#terraform-modules---for-member-account-use), you can also raise PRs to contribute to these modules or ask the Modernisation Platform team to add features to suit your needs.

1. Keep modules generic - modules should be designed to be used across applications and business units, if your module is very specific to your application, use your application folder.

1. Use standard Terraform module best practices and naming conventions, such as using inputs and outputs. See [here](https://github.com/ministryofjustice/modernisation-platform#terraform-modules---for-member-account-use) for examples of modules.

1. Ensure code passes the Terraform Static Code Analysis checks.

1. When a module is big/stable/used by multiple teams, contact the Modernisation Platform team about moving the module to its own repository. This will allow Terratest tests to be added and the module to be versioned.
