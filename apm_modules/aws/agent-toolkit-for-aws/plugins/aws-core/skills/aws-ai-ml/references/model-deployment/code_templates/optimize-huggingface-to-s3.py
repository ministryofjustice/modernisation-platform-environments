# Cell 0 [markdown]: Download a HuggingFace Hub Model to S3 (for optimization)

# Cell 1: Setup

# sagemaker>=3.20.0 ships the download_huggingface_model helper.
# %pip install --upgrade "sagemaker>=3.20.0,<4.0" --quiet  # NOTEBOOK_ONLY

# Cell 2: Configuration

import os

os.environ["AWS_DEFAULT_REGION"] = "[REGION]"

from sagemaker.core import Attribution, set_attribution
from sagemaker.core.helper.session_helper import Session
from sagemaker.serve import download_huggingface_model

set_attribution(Attribution.SAGEMAKER_AGENT_PLUGIN)

HF_MODEL_ID = "[HF_MODEL_ID]"          # e.g. "mistralai/Mistral-7B-Instruct-v0.3"
# Gated models only; else None. Prefer a Secrets Manager ARN over a literal token, and
# avoid DEBUG-level SDK/HTTP logging in this cell so the token isn't written to stdout.
HF_HUB_TOKEN = "[HF_TOKEN_OR_NONE]"

# Cell 3: Download the HuggingFace snapshot to S3

# download_huggingface_model is the SDK's supported helper: it pulls the model
# snapshot from the HuggingFace Hub and stages it to S3 in one call, returning the
# S3 URI. NON-AWS NETWORK CALL (justification): the download step reaches
# huggingface.co (not *.amazonaws.com) — unavoidable and the whole point here,
# since the model lives only on the Hub (not JumpStart) and no AWS API can supply
# the weights. All subsequent steps (recommendation, deploy) use the S3 copy.
session = Session()
bucket = session.default_bucket()
prefix = f"hf-models/{HF_MODEL_ID.replace('/', '--')}"
# Treat empty, literal "None", or an un-substituted placeholder as no token, so
# public (ungated) downloads aren't broken by a stray string being sent as a token.
_hf_token = (HF_HUB_TOKEN or "").strip()
if _hf_token in ("", "None", "[HF_TOKEN_OR_NONE]"):
    _hf_token = None
MODEL_S3_URI = download_huggingface_model(
    HF_MODEL_ID,
    s3_uri=f"s3://{bucket}/{prefix}",
    hf_hub_token=_hf_token,
    sagemaker_session=session,
)
print(f"Model uploaded to: {MODEL_S3_URI}")
# Feed MODEL_S3_URI into the recommendation workflow (recommendation-workflow.md).
