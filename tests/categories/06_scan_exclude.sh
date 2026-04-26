run_category_06_scan_exclude() {
  t06_scan_targets_and_excludes() {
    local root store venv sp out status
    root="$(mk_case_root "06_scan_targets")"
    store="$root/store"
    venv="$root/project/venv-a"

    mkvenv_like "$venv" "3.12"
    sp="$venv/lib/python3.12/site-packages"

    local regular deep_file pyc pycache_file symlink_target symlink_file
    regular="$sp/pkg/regular.txt"
    deep_file="$sp/pkg/deep/nested/data.bin"
    pyc="$sp/pkg/cache.pyc"
    pycache_file="$sp/pkg/__pycache__/mod.cpython-312.pyc"
    symlink_target="$root/outside-target.txt"
    symlink_file="$sp/pkg/link.txt"

    mkdir -p "$(dirname "$deep_file")" "$(dirname "$pycache_file")"
    printf 'regular-data\n' > "$regular"
    printf 'deep-data\n' > "$deep_file"
    printf 'pyc-data\n' > "$pyc"
    printf 'pycache-data\n' > "$pycache_file"
    printf 'outside-only\n' > "$symlink_target"
    ln -s "$symlink_target" "$symlink_file"

    local pyc_before pycache_before
    pyc_before="$(stat -f "%d:%i" "$pyc")"
    pycache_before="$(stat -f "%d:%i" "$pycache_file")"

    run_cmd_capture out status env UNKOENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "0" "$status" "add should succeed"

    local pyc_after pycache_after
    pyc_after="$(stat -f "%d:%i" "$pyc")"
    pycache_after="$(stat -f "%d:%i" "$pycache_file")"
    assert_eq "$pyc_before" "$pyc_after" "*.pyc should be excluded"
    assert_eq "$pycache_before" "$pycache_after" "__pycache__ should be excluded"

    local h_regular h_deep h_link_target
    h_regular="$(hash_file "$regular")"
    h_deep="$(hash_file "$deep_file")"
    h_link_target="$(hash_file "$symlink_target")"

    assert_file_exists "$store/blobs/${h_regular:0:2}/$h_regular"
    assert_file_exists "$store/blobs/${h_deep:0:2}/$h_deep"
    assert_not_exists "$store/blobs/${h_link_target:0:2}/$h_link_target"
    [[ -L "$symlink_file" ]] || fail "symlink should remain symlink"
  }

  run_test "06/scan_targets_and_excludes" t06_scan_targets_and_excludes
}

CATEGORIES+=("run_category_06_scan_exclude")
