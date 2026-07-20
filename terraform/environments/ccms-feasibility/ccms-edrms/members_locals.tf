locals {
  # Use "feasibility" as the environment label for all resource names in this shared account.
  # local.environment resolves to "development" which conflicts with the real ccms-edrms-development environment.
  env_label = "feasibility"
}
