run_category_04_locking() {
  t04_lock_released_after_add_and_gc() {
    local root store venv out status
    root="$(mk_case_root "04_lock_release")"
    store="$root/store"
    venv="$root/project/venv-a"

    mkvenv_like "$venv" "3.12"
    printf 'a\n' > "$venv/lib/python3.12/site-packages/pkg/a.txt"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "0" "$status" "add should succeed"
    assert_not_exists "$store/lock/unkovenv.lock"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" gc
    assert_eq "0" "$status" "gc should succeed"
    assert_not_exists "$store/lock/unkovenv.lock"
  }

  t04_lock_conflict_exit3() {
    local root store venv out status
    root="$(mk_case_root "04_lock_conflict")"
    store="$root/store"
    venv="$root/project/venv-a"

    mkvenv_like "$venv" "3.12"
    printf 'b\n' > "$venv/lib/python3.12/site-packages/pkg/b.txt"
    mkdir -p "$store/lock"
    printf '%s\n' "$$" > "$store/lock/unkovenv.lock"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "3" "$status" "existing lock should make add fail with exit 3"
    assert_contains "$out" "failed to acquire lock" "should report lock acquisition failure"
  }

  t04_stale_lock_is_recovered() {
    local root store venv out status
    root="$(mk_case_root "04_stale_lock_recovered")"
    store="$root/store"
    venv="$root/project/venv-a"

    mkvenv_like "$venv" "3.12"
    printf 'stale\n' > "$venv/lib/python3.12/site-packages/pkg/stale.txt"
    mkdir -p "$store/lock"
    printf '999999\n' > "$store/lock/unkovenv.lock"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "0" "$status" "stale lock should be removed and add should succeed"
    assert_not_exists "$store/lock/unkovenv.lock"
  }

  t04_dry_run_no_lock_file() {
    local root store venv out status
    root="$(mk_case_root "04_dry_run_no_lock")"
    store="$root/store"
    venv="$root/project/venv-a"

    mkvenv_like "$venv" "3.12"
    printf 'c\n' > "$venv/lib/python3.12/site-packages/pkg/c.txt"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add --dry-run "$venv"
    assert_eq "0" "$status" "dry-run add should succeed"
    assert_not_exists "$store/lock/unkovenv.lock"
  }

  run_test "04/lock_released_after_add_and_gc" t04_lock_released_after_add_and_gc
  run_test "04/lock_conflict_exit3" t04_lock_conflict_exit3
  run_test "04/stale_lock_is_recovered" t04_stale_lock_is_recovered
  run_test "04/dry_run_no_lock_file" t04_dry_run_no_lock_file
}

CATEGORIES+=("run_category_04_locking")
