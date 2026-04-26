run_category_02_store_init() {
  t02_store_precedence() {
    local root store_a store_b venv out status
    root="$(mk_case_root "02_store_precedence")"
    store_a="$root/store-a"
    store_b="$root/store-b"
    venv="$root/project/venv-a"

    mkvenv_like "$venv" "3.12"
    printf 'x\n' > "$venv/lib/python3.12/site-packages/pkg/a.txt"

    run_cmd_capture out status env UNKOENV_STORE_DIR="$store_a" "$SCRIPT" add "$venv"
    assert_eq "0" "$status" "add with UNKOENV_STORE_DIR should succeed"
    assert_file_exists "$store_a/venvs/venv-a"

    run_cmd_capture out status env UNKOENV_STORE="$store_b" UNKOENV_STORE_DIR="$store_a" "$SCRIPT" status --json
    assert_eq "0" "$status" "status json should succeed"
    assert_contains "$out" "\"store\":\"$store_b\"" "UNKOENV_STORE should win over UNKOENV_STORE_DIR"
  }

  t02_default_home_store() {
    local root fake_home expected_store venv out status
    root="$(mk_case_root "02_default_home_store")"
    fake_home="$root/fake-home"
    expected_store="$fake_home/.cache/unkoenv"
    venv="$root/project/venv-b"

    mkdir -p "$fake_home"
    mkvenv_like "$venv" "3.12"
    printf 'y\n' > "$venv/lib/python3.12/site-packages/pkg/b.txt"

    run_cmd_capture out status env HOME="$fake_home" "$SCRIPT" add "$venv"
    assert_eq "0" "$status" "add with HOME override should succeed"
    assert_file_exists "$expected_store/venvs/venv-b"
    assert_file_exists "$expected_store/blobs"
    assert_file_exists "$expected_store/lock"
  }

  run_test "02/store_precedence" t02_store_precedence
  run_test "02/default_home_store" t02_default_home_store
}

CATEGORIES+=("run_category_02_store_init")
