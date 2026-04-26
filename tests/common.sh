#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT_DIR/unkovenv"
TEST_TMP=""
TEST_COUNT=0
PASS_COUNT=0
SKIP_COUNT=0

CATEGORIES=()

cleanup_suite() {
  if [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]]; then
    rm -rf "$TEST_TMP"
  fi
}

init_suite() {
  TEST_TMP="$(mktemp -d)"
  trap cleanup_suite EXIT
}

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

skip_test() {
  local name="$1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
  echo "[SKIP] $name"
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [[ "$expected" != "$actual" ]]; then
    fail "$msg (expected=$expected actual=$actual)"
  fi
}

assert_ne() {
  local left="$1"
  local right="$2"
  local msg="$3"
  if [[ "$left" == "$right" ]]; then
    fail "$msg (value=$left)"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"
  [[ "$haystack" == *"$needle"* ]] || fail "$msg (needle=$needle)"
}

assert_file_exists() {
  local path="$1"
  [[ -e "$path" ]] || fail "file not found: $path"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" && ! -L "$path" ]] || fail "path should not exist: $path"
}

assert_same_inode() {
  local a="$1"
  local b="$2"
  local ia ib
  ia="$(stat -f "%d:%i" "$a")"
  ib="$(stat -f "%d:%i" "$b")"
  [[ "$ia" == "$ib" ]] || fail "inode differs: $a vs $b"
}

assert_not_same_inode() {
  local a="$1"
  local b="$2"
  local ia ib
  ia="$(stat -f "%d:%i" "$a")"
  ib="$(stat -f "%d:%i" "$b")"
  [[ "$ia" != "$ib" ]] || fail "inode should differ: $a vs $b"
}

run_cmd_capture() {
  local out_var="$1"
  local status_var="$2"
  shift 2

  local captured_out captured_status
  set +e
  captured_out="$("$@" 2>&1)"
  captured_status=$?
  set -e

  printf -v "$out_var" '%s' "$captured_out"
  printf -v "$status_var" '%s' "$captured_status"
}

mk_case_root() {
  local name="$1"
  local root="$TEST_TMP/$name"
  mkdir -p "$root"
  echo "$root"
}

mkvenv_like() {
  local venv="$1"
  local pyver="$2"
  mkdir -p "$venv/lib/python$pyver/site-packages/pkg"
}

hash_file() {
  local path="$1"
  shasum -a 256 "$path" | awk '{print $1}'
}

run_test() {
  local name="$1"
  local fn="$2"
  TEST_COUNT=$((TEST_COUNT + 1))
  echo "[TEST] $name"
  "$fn"
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "[PASS] $name"
}

finish_suite() {
  echo "[RESULT] total=$TEST_COUNT pass=$PASS_COUNT skip=$SKIP_COUNT"
}
