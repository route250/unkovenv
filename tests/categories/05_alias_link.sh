run_category_05_alias_link() {
  t05_alias_created_absolute() {
    local root store venv out status link target expected
    root="$(mk_case_root "05_alias_created")"
    store="$root/store"
    venv="$root/project/venv-a"

    mkvenv_like "$venv" "3.12"
    printf 'a\n' > "$venv/lib/python3.12/site-packages/pkg/a.txt"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "0" "$status" "add should succeed"

    link="$store/venvs/venv-a"
    assert_file_exists "$link"
    [[ -L "$link" ]] || fail "alias should be symlink"
    target="$(readlink "$link")"
    expected="$(cd "$venv" && pwd -P)"
    assert_eq "$expected" "$target" "alias should point to absolute resolved path"
  }

  t05_alias_idempotent_same_target() {
    local root store venv out status
    root="$(mk_case_root "05_alias_idempotent")"
    store="$root/store"
    venv="$root/project/venv-a"

    mkvenv_like "$venv" "3.12"
    printf 'b\n' > "$venv/lib/python3.12/site-packages/pkg/b.txt"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "0" "$status" "first add should succeed"
    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "0" "$status" "second add should also succeed"
  }

  t05_alias_conflict_and_non_symlink() {
    local root store venv1 venv2 out status
    root="$(mk_case_root "05_alias_conflict")"
    store="$root/store"
    venv1="$root/project1/.venv"
    venv2="$root/project2/.venv"

    mkvenv_like "$venv1" "3.12"
    mkvenv_like "$venv2" "3.12"
    printf 'c\n' > "$venv1/lib/python3.12/site-packages/pkg/c.txt"
    printf 'd\n' > "$venv2/lib/python3.12/site-packages/pkg/d.txt"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv1"
    assert_eq "0" "$status" "first add should succeed"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$venv2"
    assert_eq "1" "$status" "alias conflict should fail with exit 1"
    assert_contains "$out" "venv alias conflict" "should show alias conflict"

    local root2 store2 venv3
    root2="$(mk_case_root "05_alias_non_symlink")"
    store2="$root2/store"
    venv3="$root2/project/venv-x"
    mkvenv_like "$venv3" "3.12"
    printf 'e\n' > "$venv3/lib/python3.12/site-packages/pkg/e.txt"
    mkdir -p "$store2/venvs"
    printf 'not-link\n' > "$store2/venvs/venv-x"

    run_cmd_capture out status env UNKOVENV_STORE="$store2" "$SCRIPT" add "$venv3"
    assert_eq "1" "$status" "existing non-symlink alias should fail"
    assert_contains "$out" "path exists and is not symlink" "should show non-symlink alias error"
  }

  t05_legacy_project_link_migration() {
    local root store project venv out status link target expected
    root="$(mk_case_root "05_legacy_project_link_migration")"
    store="$root/store"
    project="$root/VoiceBotKit"
    venv="$project/.venv"

    mkvenv_like "$venv" "3.12"
    printf 'migrate\n' > "$venv/lib/python3.12/site-packages/pkg/data.txt"

    mkdir -p "$store/venvs"
    ln -s "$project" "$store/venvs/VoiceBotKit"

    run_cmd_capture out status env UNKOVENV_STORE="$store" "$SCRIPT" add "$project"
    assert_eq "0" "$status" "legacy project-root alias should be migrated"

    link="$store/venvs/VoiceBotKit"
    target="$(readlink "$link")"
    expected="$(cd "$venv" && pwd -P)"
    assert_eq "$expected" "$target" "alias should point to resolved .venv after migration"
  }

  run_test "05/alias_created_absolute" t05_alias_created_absolute
  run_test "05/alias_idempotent_same_target" t05_alias_idempotent_same_target
  run_test "05/alias_conflict_and_non_symlink" t05_alias_conflict_and_non_symlink
  run_test "05/legacy_project_link_migration" t05_legacy_project_link_migration
}

CATEGORIES+=("run_category_05_alias_link")
