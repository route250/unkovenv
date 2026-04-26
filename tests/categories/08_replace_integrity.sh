run_category_08_replace_integrity() {
  t08_replace_idempotent_and_dry_run() {
    local root store venv1 venv2 f1 f2 out status
    root="$(mk_case_root "08_replace_integrity")"
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

    local first_inode second_inode
    first_inode="$(stat -f "%d:%i" "$f1")"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv1"
    assert_eq "0" "$status" "second add on same venv should succeed"

    second_inode="$(stat -f "%d:%i" "$f1")"
    assert_eq "$first_inode" "$second_inode" "idempotent add should keep same inode"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add --dry-run "$venv2"
    assert_eq "0" "$status" "dry-run add should succeed"
    assert_not_same_inode "$f1" "$f2" "dry-run must not replace target file"
  }

  run_test "08/replace_idempotent_and_dry_run" t08_replace_idempotent_and_dry_run
}

CATEGORIES+=("run_category_08_replace_integrity")
