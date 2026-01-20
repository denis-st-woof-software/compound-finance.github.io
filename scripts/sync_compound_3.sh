#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/sync_compound_3.conf}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Config file not found: ${CONFIG_FILE}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${CONFIG_FILE}"

required_vars=(
  SOURCE_OWNER
  SOURCE_REPO
  SOURCE_BRANCH
  SOURCE_PATH
  TARGET_PATH
  BASE_BRANCH
  PR_BRANCH
  PR_TITLE
  PR_BODY
  GIT_AUTHOR_NAME
  GIT_AUTHOR_EMAIL
  COMMIT_MESSAGE
  GITHUB_API_BASE
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required config: ${var_name}" >&2
    exit 1
  fi
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
TARGET_ABS_PATH="${REPO_ROOT}/${TARGET_PATH}"

tmp_file="$(mktemp)"
branch_tmp_file="$(mktemp)"
cleanup() {
  rm -f "${tmp_file}"
  rm -f "${branch_tmp_file}"
}
trap cleanup EXIT

api_url="${GITHUB_API_BASE}/repos/${SOURCE_OWNER}/${SOURCE_REPO}/contents/${SOURCE_PATH}?ref=${SOURCE_BRANCH}"

curl_args=(-sS -L -H "Accept: application/vnd.github.v3.raw")
if [[ -n "${GH_TOKEN:-}" ]]; then
  curl_args+=(-H "Authorization: token ${GH_TOKEN}")
fi

echo "Downloading source file from ${api_url}"
curl "${curl_args[@]}" "${api_url}" -o "${tmp_file}"

mkdir -p "$(dirname "${TARGET_ABS_PATH}")"

if [[ -f "${TARGET_ABS_PATH}" ]] && cmp -s "${tmp_file}" "${TARGET_ABS_PATH}"; then
  echo "No changes detected against base branch. Exiting."
  exit 0
fi

remote_url="$(git -C "${REPO_ROOT}" config --get remote.origin.url)"
if [[ "${remote_url}" =~ github.com[:/](.+)/(.+)(\.git)?$ ]]; then
  REPO_OWNER="${BASH_REMATCH[1]}"
  REPO_NAME="${BASH_REMATCH[2]}"
  REPO_NAME="${REPO_NAME%.git}"
else
  echo "Unable to parse GitHub repo from remote URL: ${remote_url}" >&2
  exit 1
fi

pr_list_url="${GITHUB_API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/pulls?head=${REPO_OWNER}:${PR_BRANCH}&base=${BASE_BRANCH}&state=open"
open_pr_exists="$(
  curl -sS -L -H "Accept: application/vnd.github.v3+json" \
    ${GH_TOKEN:+-H "Authorization: token ${GH_TOKEN}"} \
    "${pr_list_url}" | grep -q '"number"' && echo "yes" || echo ""
)"

if [[ -n "${open_pr_exists}" ]]; then
  echo "Found open PR for ${PR_BRANCH} -> ${BASE_BRANCH}."
  if git -C "${REPO_ROOT}" fetch origin "${PR_BRANCH}:${PR_BRANCH}" >/dev/null 2>&1; then
    if git -C "${REPO_ROOT}" show "${PR_BRANCH}:${TARGET_PATH}" > "${branch_tmp_file}" 2>/dev/null; then
      if cmp -s "${tmp_file}" "${branch_tmp_file}"; then
        echo "No changes detected against existing PR branch. Exiting."
        exit 0
      fi
    fi
  else
    echo "Failed to fetch PR branch ${PR_BRANCH}." >&2
    exit 1
  fi
fi

cp "${tmp_file}" "${TARGET_ABS_PATH}"

if git -C "${REPO_ROOT}" show-ref --verify --quiet "refs/heads/${PR_BRANCH}"; then
  git -C "${REPO_ROOT}" checkout "${PR_BRANCH}"
else
  git -C "${REPO_ROOT}" fetch origin "${BASE_BRANCH}:${BASE_BRANCH}" >/dev/null 2>&1 || true
  git -C "${REPO_ROOT}" checkout -B "${PR_BRANCH}" "origin/${BASE_BRANCH}"
fi

git -C "${REPO_ROOT}" add "${TARGET_PATH}"

if git -C "${REPO_ROOT}" diff --cached --quiet; then
  echo "No changes to commit after staging. Exiting."
  exit 0
fi

git -C "${REPO_ROOT}" config user.name "${GIT_AUTHOR_NAME}"
git -C "${REPO_ROOT}" config user.email "${GIT_AUTHOR_EMAIL}"
git -C "${REPO_ROOT}" commit -m "${COMMIT_MESSAGE}"
git -C "${REPO_ROOT}" push origin "${PR_BRANCH}"

if [[ -z "${open_pr_exists}" ]]; then
  echo "Creating pull request for ${PR_BRANCH} -> ${BASE_BRANCH}."
  pr_payload="$(
    python - <<'PY'
import json
import os

payload = {
  "title": os.environ["PR_TITLE"],
  "head": os.environ["PR_BRANCH"],
  "base": os.environ["BASE_BRANCH"],
  "body": os.environ.get("PR_BODY", ""),
}
print(json.dumps(payload))
PY
  )"

  curl -sS -L -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${GH_TOKEN}" \
    -d "${pr_payload}" \
    "${GITHUB_API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/pulls" >/dev/null
else
  echo "PR already open; new commit added to existing PR."
fi
