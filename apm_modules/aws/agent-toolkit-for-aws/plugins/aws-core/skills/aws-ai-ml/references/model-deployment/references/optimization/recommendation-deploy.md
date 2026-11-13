# Deploy from ModelPackage

Deployment is **Cell 6** of `../../code_templates/optimize-recommendation.py`:
`model_builder.deploy(endpoint_name=[ENDPOINT_NAME], recommendation_index=0, role=ROLE_ARN, auto_approve=True, wait=True)`.
It reuses the `ModelBuilder` that ran `generate_deployment_recommendations` (no job-name lookup),
creates the Model/EndpointConfig/Endpoint from the selected row's ModelPackage, and blocks until InService.

- **Selecting a row:** `recommendation_index=0` is the top-ranked default; pass `recommendation_index=N` or `recommendation_spec_name="..."` (from `model_builder.recommendations`) to pick another.
- **Approval:** a recommendation's ModelPackage is created **unapproved**, so `deploy()` needs `auto_approve=True` (it approves the package in place). This bypasses manual-approval governance on the package group — fine when the user deploys their own recommendation; if that governance must be preserved, drop `auto_approve` and approve the package through your normal process first.
- **From a job run elsewhere** (no in-memory builder): use Cell 6's commented alternate, which rebuilds via `ModelBuilder.from_recommendation_job("[RECOMMENDATION_JOB_NAME]")` then deploys the same way.
- **`CannotStartContainerError` on deploy:** the recommended container may need a newer CUDA runtime than the instance supports (e.g. a CUDA-13 vLLM image won't start on `ml.g5`, capped at CUDA 12.4). Deploy on a newer GPU family, or pick a row using the LMI framework.
