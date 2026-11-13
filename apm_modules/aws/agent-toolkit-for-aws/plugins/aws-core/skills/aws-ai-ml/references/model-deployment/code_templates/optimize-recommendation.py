# Cell 0 [markdown]: Inference Optimization — Deployment Recommendations

# Cell 1: Setup

# sagemaker>=3.20.0 ships the GenAI deployment-recommendation interface
# (ModelBuilder.generate_deployment_recommendations / model_builder.recommendations).
# %pip install --upgrade "sagemaker>=3.20.0,<4.0" --quiet  # NOTEBOOK_ONLY

# Cell 2: Configuration

import json
import os

os.environ["AWS_DEFAULT_REGION"] = "[REGION]"

from sagemaker.core import Attribution, set_attribution
from sagemaker.serve import ModelBuilder
from sagemaker.serve.ai_inference_recommender import Workload

set_attribution(Attribution.SAGEMAKER_AGENT_PLUGIN)

MODEL_S3_URI = "[MODEL_S3_URI]"
ROLE_ARN = "[ROLE_ARN]"
S3_OUTPUT_LOCATION = "[S3_OUTPUT_LOCATION]"
RECOMMENDATION_JOB_NAME = "[RECOMMENDATION_JOB_NAME]"
WORKLOAD_CONFIG_NAME = "[WORKLOAD_CONFIG_NAME]"
PERFORMANCE_TARGET = "[PERFORMANCE_METRIC]"  # "cost", "ttft-ms", or "throughput"
TOKENIZER = "[TOKENIZER]"

# Cell 3: Define the Workload

workload = Workload.synthetic(
    tokenizer=TOKENIZER,
    prompt_input_tokens_mean=[INPUT_TOKENS_MEAN],
    prompt_input_tokens_stddev=[INPUT_TOKENS_STDDEV],
    output_tokens_mean=[OUTPUT_TOKENS_MEAN],
    output_tokens_stddev=[OUTPUT_TOKENS_STDDEV],
    concurrency=[CONCURRENCY],
    request_count=[REQUEST_COUNT],
)
# For throughput + optimization, a dataset is required. Build the workload from
# a dataset instead of synthetic prompts. Inspect the data to detect its schema;
# custom_dataset_type is an OPTIONAL hint naming that schema ("openai-chat",
# "openai-completions", "sharegpt", "sagemaker-datacapture") — omit it to let
# AIPerf auto-detect. If the format is unsupported, convert it first with the
# dataset-transformation skill.
#   workload = Workload.from_dataset("[DATASET_S3_URI]", tokenizer=TOKENIZER,
#       custom_dataset_type="openai-chat",  # optional; from the schema you detected
#       prompt_input_tokens_mean=[INPUT_TOKENS_MEAN],
#       concurrency=[CONCURRENCY], request_count=[REQUEST_COUNT])

# Cell 4: Run the Recommendation Job

# Model source A — your own HuggingFace-format weights in S3 (the default path):
model_builder = ModelBuilder(model_path=MODEL_S3_URI, role_arn=ROLE_ARN)

# Model source B — a SageMaker JumpStart base model (no S3 copy of your own).
# build() resolves the JumpStart artifacts to their cache S3 URI, which the
# recommendation job reads. Works for UNGATED JumpStart models; a GATED model
# resolves to a private cache your role can't read and the job fails with an
# "Access denied" / "Invalid ModelSource.S3.S3Uri" error — in that case stage
# the weights to your own S3 (see references/optimization/huggingface-to-s3.md)
# and use source A instead. Use this INSTEAD of the line above:
#   from sagemaker.core.jumpstart.configs import JumpStartConfig
#   from sagemaker.core.training.configs import Compute
#   model_builder = ModelBuilder.from_jumpstart_config(
#       jumpstart_config=JumpStartConfig(model_id="[JUMPSTART_MODEL_ID]", model_version="*"),
#       compute=Compute(instance_type="[INSTANCE_TYPE]", instance_count=1),
#       role_arn=ROLE_ARN,
#   )
#   model_builder.build()  # required: resolves the JumpStart model's S3 artifacts

job = model_builder.generate_deployment_recommendations(
    workload=workload,
    performance_target=PERFORMANCE_TARGET,
    output_path=S3_OUTPUT_LOCATION,
    job_name=RECOMMENDATION_JOB_NAME,
    workload_config_name=WORKLOAD_CONFIG_NAME,
    # instance_types=["ml.g6.12xlarge"],  # optional: up to 3 candidates (latency/throughput only)
    # advanced_optimization=False,        # optional: default True (kernel tuning, speculative decoding)
    # framework="VLLM",                   # optional: "VLLM" or "LMI"; default auto-selected
    wait=True,
)
print(f"Recommendation job {job.get_name()} finished: {job.ai_recommendation_job_status}")

# Cell 5: Review Recommendations

recommendations = model_builder.recommendations
print(recommendations)

# Cell 6: Deploy Top Recommendation

# Only include this cell if the user wants to deploy after reviewing results.
# Deploys the top-ranked recommendation (index 0). Pass recommendation_index=N
# to deploy a different row, or recommendation_spec_name="..." to pick by name.
#
# A recommendation's ModelPackage is created unapproved, so deploy() would raise
# unless the package is approved first. auto_approve=True approves it in place as
# part of this deploy. This bypasses manual-approval governance on the package's
# model package group — appropriate here because the user is deploying their own
# recommendation. Remove auto_approve and approve the ModelPackage through your
# normal process if that governance must be preserved.
ENDPOINT_NAME = "[ENDPOINT_NAME]"
endpoint = model_builder.deploy(
    endpoint_name=ENDPOINT_NAME,
    recommendation_index=0,
    role=ROLE_ARN,
    auto_approve=True,
    wait=True,
)
print(f"Endpoint {endpoint.endpoint_name} status: {endpoint.endpoint_status}")

# Deploy from a recommendation job run in a different session (no in-memory
# model_builder — reconstruct it from the job name) — use INSTEAD of the block
# above when the recommendation job was run elsewhere (another session or a
# teammate):
#   model_builder = ModelBuilder.from_recommendation_job("[RECOMMENDATION_JOB_NAME]")
#   endpoint = model_builder.deploy(
#       endpoint_name="[ENDPOINT_NAME]",
#       recommendation_index=0,
#       role=ROLE_ARN,
#       auto_approve=True,
#       wait=True,
#   )
#   print(f"Endpoint {endpoint.endpoint_name} status: {endpoint.endpoint_status}")

# Cell 7: Save Manifest
# Save manifest - record output of workflow step for future reference
from pathlib import Path
manifest_dir = Path("[PROJECT_DIR]") / "manifests"
manifest_dir.mkdir(parents=True, exist_ok=True)
manifest_path = manifest_dir / f"recommendation-{RECOMMENDATION_JOB_NAME}.json"
# Record a model-source-appropriate identifier: MODEL_S3_URI for source A (S3 weights),
# or the JumpStart model id for source B (uncomment the appropriate line below).
manifest_path.write_text(json.dumps({
    "recommendation_job_name": RECOMMENDATION_JOB_NAME,
    "model_source": {"type": "s3", "model_s3_uri": MODEL_S3_URI},
    # For a JumpStart-sourced run, use this instead of the line above:
    #   "model_source": {"type": "jumpstart", "model_id": "[JUMPSTART_MODEL_ID]"},
    "workload_config_name": WORKLOAD_CONFIG_NAME,
    "performance_target": PERFORMANCE_TARGET,
    "status": job.ai_recommendation_job_status,
}, indent=2))
print(f"Manifest saved: {manifest_path}")
