#!/usr/bin/env bash

set -euo pipefail

TERRAFORM_PLAN="${1:-}"

if [[ -z "${TERRAFORM_PLAN}" ]]; then
  echo "Usage: $0 <terraform-plan-json-file>" >&2
  exit 1
fi

if [[ ! -f "${TERRAFORM_PLAN}" ]]; then
  echo "Error: plan file not found: ${TERRAFORM_PLAN}" >&2
  exit 1
fi

SUMMARY_JSON=$(jq '
  [
    .resource_changes[]?
    | . as $rc
    | ($rc.change.actions // []) as $actions
    | select(any($actions[]; . != "no-op" and . != "read"))
    | ($rc.change.before // {}) as $before
    | ($rc.change.after // {}) as $after
    | ($before | del(.tags, .tags_all)) as $before_without_tags
    | ($after | del(.tags, .tags_all)) as $after_without_tags
    | ($before.tags != $after.tags or $before.tags_all != $after.tags_all) as $tag_changed
    | (($actions | index("delete")) != null and ($actions | index("create")) != null) as $is_replacement
    | (($actions | length) == 1 and $actions[0] == "update") as $is_update
    | {
        address: ($rc.address // (($rc.type // "unknown") + "." + ($rc.name // "unknown"))),
        action: ($actions | join(",")),
        tag_changed: $tag_changed,
        is_replacement: $is_replacement,
        is_update: $is_update,
        tag_only_update: ($is_update and $tag_changed and ($before_without_tags == $after_without_tags)),
        tag_related_replacement: ($is_replacement and $tag_changed)
      }
  ]
  | {
      total_changes: length,
      changes_with_tag_diff: (map(select(.tag_changed)) | length),
      tag_only_updates: (map(select(.tag_only_update)) | length),
      total_replacements: (map(select(.is_replacement)) | length),
      tag_related_replacements: (map(select(.tag_related_replacement)) | length),
      tag_related_replacement_addresses: (map(select(.tag_related_replacement) | .address) | .[:20]),
      non_tag_replacement_addresses: (map(select(.is_replacement and (.tag_related_replacement | not)) | .address) | .[:20])
    }
' "${TERRAFORM_PLAN}")

TOTAL_CHANGES=$(jq -r '.total_changes' <<<"${SUMMARY_JSON}")
TAG_DIFF_CHANGES=$(jq -r '.changes_with_tag_diff' <<<"${SUMMARY_JSON}")
TAG_ONLY_UPDATES=$(jq -r '.tag_only_updates' <<<"${SUMMARY_JSON}")
TOTAL_REPLACEMENTS=$(jq -r '.total_replacements' <<<"${SUMMARY_JSON}")
TAG_RELATED_REPLACEMENTS=$(jq -r '.tag_related_replacements' <<<"${SUMMARY_JSON}")

echo "### Tag impact analysis"
echo
echo "| Metric | Count |"
echo "|---|---:|"
echo "| Resource changes in this plan | ${TOTAL_CHANGES} |"
echo "| Changes where tags/tags_all differ | ${TAG_DIFF_CHANGES} |"
echo "| Tag-only in-place updates | ${TAG_ONLY_UPDATES} |"
echo "| Total replacements (delete/create) | ${TOTAL_REPLACEMENTS} |"
echo "| Tag-related replacements | ${TAG_RELATED_REPLACEMENTS} |"

if [[ "${TAG_RELATED_REPLACEMENTS}" -gt 0 ]]; then
  echo
  echo "Tag-related replacements (first 20):"
  jq -r '.tag_related_replacement_addresses[] | "- " + .' <<<"${SUMMARY_JSON}"
fi

NON_TAG_REPLACEMENTS=$(jq -r '.non_tag_replacement_addresses | length' <<<"${SUMMARY_JSON}")
if [[ "${NON_TAG_REPLACEMENTS}" -gt 0 ]]; then
  echo
  echo "Non-tag replacements (first 20):"
  jq -r '.non_tag_replacement_addresses[] | "- " + .' <<<"${SUMMARY_JSON}"
fi
