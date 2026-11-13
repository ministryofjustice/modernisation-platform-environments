# Benchmarking Guidance (know-how)

General principles the agent should apply when setting up and interpreting benchmarks. Read this before choosing workload parameters or explaining results. This is guidance, not a step list — the concrete steps live in `benchmark-workflow.md`.

## When does a benchmark stop?

- The benchmark stops after it has issued **`request_count`** requests. That is the run-length control — there is **no duration-based stop** parameter; `benchmark_duration` in the results is *measured* (an output), not something you set.
- To make a run longer/more stable, raise `request_count` (and/or `concurrency`), not a timer.

## Warm up when you can

A **warmup** — a set of requests issued before measurement starts, whose results are discarded — reduces cold-start skew (container/model load, JIT, cache priming) in the reported numbers. It's a good idea for a clean measurement, but it's not wired into the standard template's `Workload.synthetic(...)` call, so treat it as an **optional refinement**, not an automatic default: if the runtime's AIPerf workload exposes a warmup control, pass it through the workload's extra parameters (`**params` on `synthetic`/`from_dataset`, or `extra_inputs` on `template` — see the `[EXTRA_PARAMS]` note in `benchmark-workflow.md` Step 5), with a small warmup (~10–20 requests) usually enough. See the prefix-caching note below for how warmup requests interact with caching when using real user data.

## How many requests do I need?

Size `request_count` to the statistic you're claiming: ~50 for averages, ~100 for p50, ~200 for p90, and ≥~1000 for a trustworthy p99 (its tail is only 1% of requests). Don't report p99 off a tiny run, and state the sample count alongside percentile claims.

## Synthetic vs. dataset vs. real traffic — which to use

- **Synthetic** (`Workload.synthetic`): fastest to set up; good for a standard perf check or a load test where you just need representative token lengths. Prompts are generated from a fixed distribution, so results reflect *your chosen* input/output token means, not your real traffic. **When the user specifies an output-token length, set `ignore_eos=True`** so the model generates the full requested length instead of stopping early at an end-of-sequence token — otherwise the measured output sequence length (and thus throughput/latency) won't match what was asked for. **How to pass it depends on the factory:** on `synthetic` / `from_dataset` use `**params` — Python kwargs, so `Workload.synthetic(..., ignore_eos=True)` (or equivalently the `[EXTRA_PARAMS]` dict `{"ignore_eos": True}`); on `template` use the *string* form `Workload.template(..., extra_inputs="ignore_eos:true")` (lowercase, colon-separated). Same setting, two different value formats — don't mix them.
- **Dataset** (`Workload.from_dataset` on an S3 JSONL): use when the user wants numbers that reflect *their* prompt/response shapes. Sequence lengths come from the data, so latency/throughput track real usage.
- **Real traffic** (`Workload.from_dataset` on a **SageMaker Data Capture** prefix): the closest to production — replays actually-served requests.

**Speculative decoding:** if the endpoint (or a recommendation config) uses **speculative decoding**, prefer **real data over synthetic**. Speculative decoding's speedup depends on how predictable the tokens are; synthetic prompts don't reflect real acceptance rates, so synthetic benchmarks can badly over- or under-state the gain. Use a dataset or Data Capture for any spec-decoding comparison. (This is also why the recommendation job *requires* a dataset for throughput + optimization.) **Also keep sampling temperature low** — high temperature makes the model's next token less predictable, which lowers the draft-model acceptance rate and makes speculation ineffective, so a high-temperature run understates the real-world gain. Treat **temperature > 0.3 as high**; set temperature through the workload's AIPerf extra parameters — dict-kwarg on `synthetic`/`from_dataset` (`temperature=0.2`), or `extra_inputs="temperature:0.2"` on `template` — for a representative spec-decoding measurement.

## Prefix caching can inflate throughput on repeated requests

If the endpoint has **prefix caching** enabled, it caches requests it has already seen and serves cache hits far faster than a clean inference. This **artificially inflates measured throughput** when the same request is replayed — and it's easy to trigger accidentally with real user data:

- If you point `from_dataset` at, say, 100 records but set `request_count` to 1000, AIPerf **oversamples** — each record is reused ~10× on average. Only the first inference of a given request is a clean uncached run; every repeat is a cache hit, so the aggregate looks faster than production would be.
- The number to watch is **warmup request_count + benchmark request_count vs. the dataset size**. A request used during warmup is also cached, so warmup can prime the cache for the measured run too. Keep total requests ≤ the number of distinct records (or accept, and disclose, that repeats are cache hits).
- **This only matters when the customer provides their own data.** For **synthetic** generation every data point is independent (AIPerf generates fresh prompts), so oversampling/caching is not a concern there.

When reporting dataset-based numbers on a prefix-caching endpoint, note whether requests were oversampled, since it affects how the throughput translates to real traffic.

## Dataset schema hint (`custom_dataset_type`)

When driving a workload from a dataset (`Workload.from_dataset`), `custom_dataset_type` is an **optional hint** naming the dataset's schema so AIPerf parses records correctly — it is **not required**. Inspect the data and pass the matching value if you can identify it; if unsure, omit it and AIPerf attempts auto-detection. This is the single source of truth for the mapping (both the benchmark and recommendation workflows reference it):

| Detected schema | `custom_dataset_type` |
| --------------- | --------------------- |
| OpenAI Chat (`messages` field) | `"openai-chat"` |
| OpenAI Completions (`prompt` field) | `"openai-completions"` |
| ShareGPT (`conversations` field) | `"sharegpt"` |
| SageMaker Data Capture (captured endpoint traffic) | `"sagemaker-datacapture"` |

If the data isn't in a schema AIPerf understands, don't ask the user to reformat by hand — hand off to the `dataset-transformation` skill to convert it, then benchmark the converted data.

## Comparability — don't compare apples to oranges

- Latency and throughput are only comparable across runs at the **same input/output sequence lengths and the same concurrency.** Always report `input_sequence_length` / `output_sequence_length` (and the concurrency) with the numbers.
- When comparing two runs (synthetic vs dataset, before vs after optimization, instance A vs B), line up their ISL/OSL/concurrency first; if they differ, attribute the delta partly to the workload, not just the endpoint. Use the `compare_benchmarks(...)` utility rather than hand-diffing — it aligns every metric and reports a signed, better-is-`+` Δ% per run. See `interpreting-results.md` → "Comparing two or more benchmark runs" for the code and how to present it.

## Load testing (finding the ceiling)

- ⚠️ **Never load-test a live/production endpoint without explicit confirmation.** A load test deliberately drives the endpoint to saturation (high concurrency, errors, multi-second latency), so it is *more* disruptive than a normal benchmark — it can cause an outage for anyone currently served by that endpoint. Apply the `benchmark-workflow.md` Step 2 in-service gate here too, and for a true stress test steer the user toward a **dedicated copy** of the endpoint rather than the live one. Skip the warning only if the endpoint was just created in this conversation.
- To find the traffic ceiling, sweep `concurrency` (e.g. 1 → 10 → 50 → 100 → 200) at a fixed, representative token profile and watch where latency (esp. TTFT and p99) climbs sharply and where errors appear. That knee is the practical ceiling.
- A single high-concurrency run tells you "saturated or not" at that level; a **stepped series** tells you *where* it saturates — offer the series when the user wants the ceiling. When you run more than one step, feed the runs to `compare_benchmarks(...)` (baseline first) so the throughput-vs-latency crossover is a single Δ% table instead of several separate result blocks — see `interpreting-results.md`.
- Expect throughput to keep rising past the point where per-request latency becomes unacceptable — report both so the user picks the concurrency that meets their latency SLA, not just max throughput.

## Safety

- Benchmarking an **InService** endpoint sends real load and can degrade latency for anyone currently using it. Warn and confirm before benchmarking an endpoint that may serve production traffic (skip only if it was just created in this conversation). See `benchmark-workflow.md` Step 2.
