# Cell 0 [markdown]: Inference Optimization — Benchmark an Endpoint

# Cell 1: Setup

# sagemaker>=3.20.0 ships the GenAI benchmarking interface (start_benchmark / Workload / job.show_result).
# %pip install --upgrade "sagemaker>=3.20.0,<4.0" --quiet  # NOTEBOOK_ONLY

# Cell 2: Configuration

import json
import os

os.environ["AWS_DEFAULT_REGION"] = "[REGION]"

from sagemaker.core import Attribution, set_attribution
from sagemaker.serve import start_benchmark
from sagemaker.serve.ai_inference_recommender import Workload

set_attribution(Attribution.SAGEMAKER_AGENT_PLUGIN)

ENDPOINT_NAME = "[ENDPOINT_NAME]"
ROLE_ARN = "[ROLE_ARN]"
S3_OUTPUT_LOCATION = "[S3_OUTPUT_LOCATION]"
BENCHMARK_JOB_NAME = "[BENCHMARK_JOB_NAME]"
WORKLOAD_CONFIG_NAME = "[WORKLOAD_CONFIG_NAME]"
TOKENIZER = "[TOKENIZER]"

# Cell 3: Define the Workload

# Default: synthetic prompts against an OpenAI ChatCompletions endpoint.
# For a load test, raise concurrency (e.g. 50-200) and request_count.
workload = Workload.synthetic(
    tokenizer=TOKENIZER,
    prompt_input_tokens_mean=[INPUT_TOKENS_MEAN],
    prompt_input_tokens_stddev=[INPUT_TOKENS_STDDEV],
    output_tokens_mean=[OUTPUT_TOKENS_MEAN],
    output_tokens_stddev=[OUTPUT_TOKENS_STDDEV],
    concurrency=[CONCURRENCY],
    request_count=[REQUEST_COUNT],
    # Optional extra AIPerf params passthrough — e.g. ignore_eos when an exact
    # output length is required, a low sampling temperature for speculative-decoding
    # runs, or a warmup control if the runtime exposes one. Omit if not needed.
    # **[EXTRA_PARAMS]  # e.g. {"ignore_eos": True, "temperature": 0.2}
)

# Custom (non-OpenAI) endpoint format — provide a Jinja2 request template and a
# JMESPath response_field (omit response_field to let AIPerf auto-detect):
#   workload = Workload.template(
#       "[REQUEST_TEMPLATE]",  # local path or inline Jinja2 string
#       response_field="[RESPONSE_FIELD]",  # e.g. "generated_text"
#       tokenizer=TOKENIZER, concurrency=[CONCURRENCY], request_count=[REQUEST_COUNT])
#
# Benchmark on your own data / real traffic — replay a dataset or SageMaker Data
# Capture. custom_dataset_type is an OPTIONAL hint naming the schema so AIPerf
# parses it ("openai-chat", "openai-completions", "sharegpt", or
# "sagemaker-datacapture"); omit it to let AIPerf auto-detect. Inspect the data
# to pick the value; if it's an unsupported format, convert it first with the
# dataset-transformation skill.
#   workload = Workload.from_dataset(
#       "[DATASET_S3_URI]", tokenizer=TOKENIZER,
#       custom_dataset_type="openai-chat",  # optional; from the schema you detected
#       concurrency=[CONCURRENCY], request_count=[REQUEST_COUNT])

# Cell 4: Run the Benchmark

job = start_benchmark(
    endpoint=ENDPOINT_NAME,
    workload=workload,
    role=ROLE_ARN,
    output_path=S3_OUTPUT_LOCATION,
    name=BENCHMARK_JOB_NAME,
    workload_config_name=WORKLOAD_CONFIG_NAME,
    # inference_components=["[INFERENCE_COMPONENT_NAME]"],  # only if the endpoint uses inference components
    wait=True,
)
print(f"Benchmark job {job.get_name()} finished: {job.ai_benchmark_job_status}")

# Cell 5: Display Results

result = job.show_result()
print(result)

# Cell 6: Save Manifest
# Save manifest - record output of workflow step for future reference
from pathlib import Path
manifest_dir = Path("[PROJECT_DIR]") / "manifests"
manifest_dir.mkdir(parents=True, exist_ok=True)
manifest_path = manifest_dir / f"benchmark-{BENCHMARK_JOB_NAME}.json"
manifest_path.write_text(json.dumps({
    "benchmark_job_name": BENCHMARK_JOB_NAME,
    "endpoint_name": ENDPOINT_NAME,
    "workload_config_name": WORKLOAD_CONFIG_NAME,
    "s3_output_location": result.s3_output_location,
    "status": job.ai_benchmark_job_status,
}, indent=2))
print(f"Manifest saved: {manifest_path}")

# Cell 7: Compare Runs (optional)
# Include this cell only when comparing this run against another — before/after an
# optimization, synthetic vs. dataset, or a step in a concurrency sweep. compare_benchmarks
# aligns every metric across runs and reports a signed Δ% oriented so "+" is always better
# (higher throughput / lower latency). The FIRST result is the baseline. Reload a prior run
# with BenchmarkJob.get("<job-name>").show_result().
from sagemaker.serve.ai_inference_recommender import compare_benchmarks
from sagemaker.serve.ai_inference_recommender.jobs import BenchmarkJob

baseline_result = BenchmarkJob.get("[BASELINE_JOB_NAME]").show_result()
comparison = compare_benchmarks(
    baseline_result,
    result,
    names=["[BASELINE_LABEL]", "[THIS_RUN_LABEL]"],
    stat="avg",  # or "p50" / "p90" / "p95" / "p99" / "min" / "max"
)
print(comparison)
