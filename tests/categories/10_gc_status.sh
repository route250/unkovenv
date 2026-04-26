run_category_10_gc_status() {
  t10_gc_and_status() {
    local root store venv1 venv2 f1 f2 out status
    root="$(mk_case_root "10_gc_status")"
    store="$root/store"
    venv1="$root/project1/venv-a"
    venv2="$root/project2/venv-b"

    mkvenv_like "$venv1" "3.12"
    mkvenv_like "$venv2" "3.12"

    f1="$venv1/lib/python3.12/site-packages/pkg/data.bin"
    f2="$venv2/lib/python3.12/site-packages/pkg/data.bin"
    printf 'same-content\n' > "$f1"
    printf 'same-content\n' > "$f2"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv1"
    assert_eq "0" "$status" "first add should succeed"
    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv2"
    assert_eq "0" "$status" "second add should succeed"

    local orphan_hash orphan_path broken_link
    orphan_hash="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    orphan_path="$store/blobs/${orphan_hash:0:2}/$orphan_hash"
    mkdir -p "$(dirname "$orphan_path")"
    printf 'orphan\n' > "$orphan_path"

    mkdir -p "$store/venvs"
    broken_link="$store/venvs/broken"
    ln -s "$root/no-target" "$broken_link"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" status --json
    assert_eq "0" "$status" "status --json should succeed"
    assert_contains "$out" '"venv_count":3' "status should count all venv symlinks including broken ones"
    assert_contains "$out" '"broken_link_count":' "status should include broken_link_count field"

    local saved_est
    saved_est="$(echo "$out" | grep -Eo '"estimated_saved_bytes":[0-9]+' | awk -F: '{print $2}')"
    [[ "$saved_est" =~ ^[0-9]+$ ]] || fail "estimated_saved_bytes should be a number"
    [[ "$saved_est" -gt 0 ]] || fail "estimated_saved_bytes should be positive"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" gc --dry-run
    assert_eq "0" "$status" "gc --dry-run should succeed"
    assert_file_exists "$orphan_path"
    [[ -L "$broken_link" ]] || fail "dry-run gc should keep broken link"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" gc
    assert_eq "0" "$status" "gc should succeed"
    assert_not_exists "$orphan_path"
    assert_not_exists "$broken_link"
  }

  run_test "10/gc_and_status" t10_gc_and_status
}

CATEGORIES+=("run_category_10_gc_status")
