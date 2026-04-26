run_category_03_add_prereq() {
  t03_missing_venv_dir() {
    local root store out status
    root="$(mk_case_root "03_missing_venv_dir")"
    store="$root/store"

    run_cmd_capture out status env UNKOENV_STORE="$store" "$SCRIPT" add "$root/no-such-venv"
    assert_eq "2" "$status" "missing venv_dir should be exit 2"
    assert_contains "$out" "venv_dir not found" "error should mention missing venv path"
  }

  t03_missing_site_packages() {
    local root store venv out status
    root="$(mk_case_root "03_missing_site_packages")"
    store="$root/store"
    venv="$root/project/.venv"
    mkdir -p "$venv"

    run_cmd_capture out status env UNKOENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "2" "$status" "missing site-packages should be exit 2"
    assert_contains "$out" "site-packages not found" "error should mention site-packages"
  }

  t03_relative_and_unicode_path() {
    local root store project venv out status
    root="$(mk_case_root "03_relative_and_unicode")"
    store="$root/store"
    project="$root/プロジェクト with space"
    venv="$project/venv-a"

    mkvenv_like "$venv" "3.12"
    printf 'z\n' > "$venv/lib/python3.12/site-packages/pkg/c.txt"

    (
      cd "$root"
      run_cmd_capture out status env UNKOENV_STORE="$store" "$SCRIPT" add "プロジェクト with space/venv-a"
      assert_eq "0" "$status" "relative path with spaces/unicode should succeed"
    )

    assert_file_exists "$store/venvs/venv-a"
  }

  t03_project_path_with_dotvenv() {
    local root store project venv f out status
    root="$(mk_case_root "03_project_path_with_dotvenv")"
    store="$root/store"
    project="$root/VoiceBotKit"
    venv="$project/.venv"

    mkvenv_like "$venv" "3.12"
    f="$venv/lib/python3.12/site-packages/pkg/data.bin"
    printf 'voicebot\n' > "$f"

    run_cmd_capture out status env UNKOENV_STORE="$store" "$SCRIPT" add "$project"
    assert_eq "0" "$status" "project path with .venv should be accepted"
    assert_file_exists "$store/venvs/VoiceBotKit"

    local h blob
    h="$(hash_file "$f")"
    blob="$store/blobs/${h:0:2}/$h"
    assert_file_exists "$blob"
    assert_same_inode "$f" "$blob"
  }

  run_test "03/missing_venv_dir" t03_missing_venv_dir
  run_test "03/missing_site_packages" t03_missing_site_packages
  run_test "03/relative_and_unicode_path" t03_relative_and_unicode_path
  run_test "03/project_path_with_dotvenv" t03_project_path_with_dotvenv
}

CATEGORIES+=("run_category_03_add_prereq")
