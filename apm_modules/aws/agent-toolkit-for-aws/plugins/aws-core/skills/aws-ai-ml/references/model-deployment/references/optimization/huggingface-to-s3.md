# Deploying / Optimizing a HuggingFace Hub Model (not on JumpStart)

Use this when the user wants to deploy or optimize a model that lives on the **HuggingFace Hub** (e.g. `mistralai/Mistral-7B-Instruct-v0.3`) rather than SageMaker JumpStart / the SageMaker Hub.

The AI recommendation job needs the model weights in **S3** (`ModelBuilder(model_path="s3://...")`). So the flow is: **download from HuggingFace → upload to S3 → run a recommendation job on the S3 model → deploy the top recommendation.**

## Step 1: Confirm the model + license

- Confirm the exact HuggingFace repo id with the user (e.g. `mistralai/Mistral-7B-Instruct-v0.3`).
- Surface the model's license and get acceptance before downloading (gated models — Llama, Mistral, etc. — require accepting terms on HuggingFace and a HF token).
- If the model is gated, ask the user for a HuggingFace access token (store it securely; never echo it back).

## Step 2: Download the model to S3

Generate a Jupyter notebook or a Python script — read `../code_output_guide.md` for the mode choice and output format rules (the template's `# NOTEBOOK_ONLY` markers make it dual-mode). The code comes from `../../code_templates/optimize-huggingface-to-s3.py` (split on the `# Cell N:` comments). Cell 3 calls the SDK's `download_huggingface_model(...)` helper, which pulls the HuggingFace snapshot from the Hub and stages it to the session's default S3 bucket in one call, returning `MODEL_S3_URI`.

Placeholders to fill in Cell 2:

- `[REGION]` — the AWS region for the run (e.g. `us-west-2`).
- `[HF_MODEL_ID]` — the HuggingFace repo id confirmed in Step 1 (e.g. `mistralai/Mistral-7B-Instruct-v0.3`).
- `[HF_TOKEN_OR_NONE]` — a HuggingFace access token for gated models, or `None` for public models.

Requirements/notes:

- Requires `sagemaker>=3.20.0` (carries `download_huggingface_model`); Cell 1 installs it in notebook mode.
- Large models take time/disk to download; use an instance/host with enough space, and warn the user for big models (70B+ can be >100 GB).
- The helper stages HuggingFace-format artifacts (`config.json` + weight files) to S3 — exactly what the recommendation job expects.

## Step 3: Run the recommendation job on the S3 model

Feed `MODEL_S3_URI` into the recommendation workflow — this is identical to the standard recommendation path (`recommendation-workflow.md`), just with the S3 URI you produced above:

```python
model_builder = ModelBuilder(model_path=MODEL_S3_URI, role_arn=ROLE_ARN)
job = model_builder.generate_deployment_recommendations(workload=workload, performance_target=PERFORMANCE_TARGET, wait=True)
recommendations = model_builder.recommendations
```

## Step 4: Deploy the best recommendation

```python
# index 0 (the best/top-ranked row) is the default — no need to pass it explicitly
endpoint = model_builder.deploy(role=ROLE_ARN, auto_approve=True, wait=True)
```

## Applies to

- Same as `recommendation-workflow.md` → Applies to (it runs a recommendation job on the S3 model).
- The model must be a text-generation LLM compatible with the recommender's serving containers (vLLM / LMI).
