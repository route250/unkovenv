run_category_07_hash_blob() {
  t07_hash_and_blob_layout() {
    local root store venv1 venv2 f1 f2 out status
    root="$(mk_case_root "07_hash_blob_layout")"
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
    assert_contains "$out" "new_blobs=1" "first add should create one blob"

    local h1 blob_path
    h1="$(hash_file "$f1")"
    blob_path="$store/blobs/${h1:0:2}/$h1"
    assert_file_exists "$blob_path"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv2"
    assert_eq "0" "$status" "second add should succeed"

    local blob_count
    blob_count="$(find "$store/blobs" -type f | wc -l | awk '{print $1}')"
    assert_eq "1" "$blob_count" "same content should reuse blob"

    assert_same_inode "$f1" "$blob_path"
    assert_same_inode "$f2" "$blob_path"
  }

  run_test "07/hash_and_blob_layout" t07_hash_and_blob_layout
}

CATEGORIES+=("run_category_07_hash_blob")
