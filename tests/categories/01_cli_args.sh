run_category_01_cli_args() {
  t01_no_subcommand() {
    local out status
    run_cmd_capture out status "$SCRIPT"
    assert_eq "1" "$status" "no subcommand should fail"
    assert_contains "$out" "Usage:" "usage should be shown"
  }

  t01_unknown_subcommand() {
    local out status
    run_cmd_capture out status "$SCRIPT" nope
    assert_eq "1" "$status" "unknown subcommand should fail"
    assert_contains "$out" "Usage:" "usage should be shown"
  }

  t01_help() {
    local out status
    run_cmd_capture out status "$SCRIPT" --help
    assert_eq "0" "$status" "--help should succeed"
    assert_contains "$out" "Usage:" "usage should be shown"
  }

  t01_add_missing_arg() {
    local out status
    run_cmd_capture out status "$SCRIPT" add
    assert_eq "1" "$status" "add without venv_dir should fail"
    assert_contains "$out" "Usage:" "usage should be shown"
  }

  t01_gc_extra_arg() {
    local out status
    run_cmd_capture out status "$SCRIPT" gc extra
    assert_eq "1" "$status" "gc with positional arg should fail"
    assert_contains "$out" "Usage:" "usage should be shown"
  }

  t01_status_extra_arg() {
    local out status
    run_cmd_capture out status "$SCRIPT" status extra
    assert_eq "1" "$status" "status with positional arg should fail"
    assert_contains "$out" "Usage:" "usage should be shown"
  }

  run_test "01/no_subcommand" t01_no_subcommand
  run_test "01/unknown_subcommand" t01_unknown_subcommand
  run_test "01/help" t01_help
  run_test "01/add_missing_arg" t01_add_missing_arg
  run_test "01/gc_extra_arg" t01_gc_extra_arg
  run_test "01/status_extra_arg" t01_status_extra_arg
}

CATEGORIES+=("run_category_01_cli_args")
