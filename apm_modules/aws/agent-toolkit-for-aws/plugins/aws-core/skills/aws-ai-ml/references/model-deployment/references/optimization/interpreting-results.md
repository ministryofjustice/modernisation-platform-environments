# Interpreting Results

Guide for presenting benchmark and recommendation results to users.

## Benchmark Job Results

`job.show_result()` returns a `BenchmarkResult` (it downloads and parses the job's `output.tar.gz` from S3). Fill the fields below from it: `print(result)` renders the key metrics as a table, typed metrics are on `result.metrics` (each with p50/p90/p99 and average where applicable), and the raw profile is on `result.profile`.

Report results **consistently**. Always lead with this one-line headline, filled from the run, then follow with second-order metrics. Do not free-form the summary.

**Headline (fill this template exactly):**

> Serving **{concurrency}** concurrent requests, each request completes between **{request_latency_p50_seconds}s (p50)** and **{request_latency_{tail}_seconds}s ({tail})**.

Convert `request_latency` from ms to seconds (1 decimal). Example:

> Serving **4** concurrent requests, each request completes between **2.2s (p50)** and **2.7s (p99)**.

**Pick the tail percentile `{tail}` from the run's sample count (`request_count`)** so you never lead with an under-sampled number (see `benchmarking-guidance.md` → "How many requests do I need?"):

- `request_count` ≥ ~1000 → use **p99**.
- ~200–1000 → use **p90** (say "p90" in the headline, not p99).
- < ~200 → use **p50 only** (drop the tail clause) and note the run is too small for a trustworthy tail.

The default `request_count` is 100, so a default run leads with p50 and no tail unless the user asked for more requests. When you report a tail percentile, state the sample count alongside it so the reader can judge confidence.

**Then** the second-order metrics (these come *after* the headline, never instead of it):

| Metric | Stat | Value | Unit |
| ------ | ---- | ----- | ---- |
| OutputTokenThroughput | avg | {value} | tokens/s |
| RequestThroughput | avg | {value} | requests/s |
| TimeToFirstToken | p50 / p99 | {value} / {value} | ms |
| InterTokenLatency | p50 | {value} | ms |
| InputSequenceLength | avg | {value} | tokens |
| OutputSequenceLength | avg | {value} | tokens |

**Always include InputSequenceLength and OutputSequenceLength** (from `input_sequence_length` / `output_sequence_length` in the result). They characterize the actual traffic that produced these numbers — latency and throughput are only comparable across runs at the same sequence lengths. This is what makes a **synthetic vs. dataset comparison** meaningful: it lets the reader see *how much* the real traffic differed from the synthetic profile, so the latency delta is attributable.

> **Note:** Values are illustrative placeholders — fill them from the actual `job.show_result()` output. Results vary by model size, instance type, concurrency, and workload.

### Comparing two or more benchmark runs

When the user has more than one run to weigh against each other — synthetic vs. dataset, before vs. after an optimization, instance A vs. B, or a concurrency sweep — do **not** hand-diff the tables. Use the first-class `compare_benchmarks(...)` utility; it aligns every metric across runs and reports a signed percentage change oriented so **`+` is always better** (higher throughput / lower latency), so the reader never has to reason about sign direction per metric.

The code for this is **Cell 7 of `../../code_templates/optimize-benchmark.py`** — generate that cell rather than writing the call inline. It takes the current run's result plus a baseline reloaded with `BenchmarkJob.get("<job-name>").show_result()` (the FIRST argument is the baseline), and accepts `stat="avg"` (or `"p50"`/`"p90"`/`"p95"`/`"p99"`/`"min"`/`"max"`).

Present the printed table as-is; then call out the one or two metrics that moved most (e.g. "+305% throughput but −719% latency at concurrency 150 — the endpoint is saturated"). `compare_benchmarks` rejects concurrency-search/sweep results (they have no single metric profile) — compare the individual winning runs instead. Because deltas are only meaningful at matched sequence lengths, keep ISL/OSL in view (see the note above).

Key insights to highlight (optional, after the numbers):

- **TTFT p50 vs p99** — a large gap means inconsistent latency (batching / cold starts).
- **OutputTokenThroughput** — higher is better for batch workloads.
- **Concurrency impact** — if multiple runs at different concurrency were done, compare how latency and throughput scale.
- **Synthetic vs. dataset** — when comparing a synthetic run to a dataset run on the same endpoint, put the two runs' input/output sequence lengths side by side. If the dataset's sequence lengths differ from the synthetic profile, that difference explains the latency delta — quantify it (e.g. "dataset averaged 180/95 in/out tokens vs the synthetic 128/128, so the higher latency is expected").
- **Cost framing** — benchmark results measure *performance*, not cost. To frame cost, pair OutputTokenThroughput with the instance's on-demand hourly rate (retrieve via `aws pricing get-products --service-code AmazonSageMaker --filters ...` — never fabricate) to express $/1M tokens. If the endpoint uses inference components (IC), the backing instance type may not be directly visible — tell the user, and retrieve pricing once you identify the instance (e.g. from `describe-endpoint-config`). If pricing cannot be retrieved at all, say so upfront and omit the column rather than failing silently.

## Recommendation Job Results

Present recommendations as a ranked table:

> "Here are the recommendations, ranked by [cost/latency/throughput]:
>
> | # | Instance Type  | TTFT p50 | Throughput | Optimizations | Est. Cost |
> | - | -------------- | -------- | ---------- | ------------- | --------- |
> | 1 | ml.g6.xlarge   | 95ms     | 42 tok/s   | Kernel Tuning | `<retrieve via aws pricing get-products>` |
> | 2 | ml.g5.xlarge   | 110ms    | 38 tok/s   | None          | `<retrieve via aws pricing get-products>` |
> | 3 | ml.g6.12xlarge | 45ms     | 120 tok/s  | Kernel Tuning | `<retrieve via aws pricing get-products>` |
>
> **Note:** The table above is an illustrative example, not an exhaustive list of possible results. Actual recommendations depend on the model, performance target, and available instance types.
>
> ⚠️ **Always** retrieve real-time pricing with `aws pricing get-products --service-code AmazonSageMaker --filters ...` before populating the Est. Cost column. Never estimate or fabricate cost values. If pricing cannot be retrieved, omit the column or show "N/A".

### What Each Field Means

- **Instance Type** — The GPU instance the model was tested on
- **TTFT (Time to First Token)** — How long until the first token is generated. Lower is better for interactive use cases.
- **Throughput (Output Token Throughput)** — Tokens generated per second. Higher is better for batch processing.
- **Optimizations** — What the service applied:
  - **Kernel Tuning** — GPU kernel optimizations specific to the hardware. Improves throughput with no quality impact.
  - **Speculative Decoding** — Uses a smaller draft model to predict tokens ahead. Improves latency but requires a compatible draft model.
- **Est. Cost** — The on-demand hourly price for the instance type. The recommendation job does not calculate cost directly — retrieve current rates with `aws pricing get-products --service-code AmazonSageMaker --filters ...` (see guardrail above). Actual costs depend on usage patterns, reserved capacity, and Savings Plans.
- **CopyCountPerInstance** — How many model copies fit on one instance. More copies = higher throughput per instance.

### Helping the User Choose

Guide based on their performance target:

- **Cost target** → Recommend #1 (lowest cost that meets baseline performance)
- **Latency target** → Recommend the one with lowest TTFT at the user's target percentile
- **Throughput target** → Recommend the one with highest OutputTokenThroughput

If the user is unsure, suggest:

> "For interactive applications (chatbots, real-time), prioritize low TTFT.
> For batch processing (summarization, translation), prioritize high throughput.
> For cost-sensitive workloads, the cost-optimized recommendation balances both."

### ModelPackage Deployment

Every recommendation is backed by a deployable ModelPackage (exposed on the row's `model_details`). Explain:

> "Each recommendation is packaged as a deployable ModelPackage. You can deploy any of them directly with `model_builder.deploy(recommendation_index=N)` — the model weights, container image, environment variables, and optimization artifacts are all bundled together.
>
> Would you like me to generate deployment code for one of these recommendations?"
