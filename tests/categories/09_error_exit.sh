run_category_09_error_exit() {
  t09_exit_codes_1_2_3() {
    local root store venv out status
    root="$(mk_case_root "09_exit_codes_123")"
    store="$root/store"

    run_cmd_capture out status "$SCRIPT" add
    assert_eq "1" "$status" "usage error should return 1"

    run_cmd_capture out status env UNKOENV_STORE="$store" "$SCRIPT" add "$root/no-venv"
    assert_eq "2" "$status" "missing venv should return 2"

    venv="$root/project/venv-a"
    mkvenv_like "$venv" "3.12"
    printf 'data\n' > "$venv/lib/python3.12/site-packages/pkg/a.txt"
    mkdir -p "$store/lock"
    printf '%s\n' "$$" > "$store/lock/unkoenv.lock"
    run_cmd_capture out status env UNKOENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "3" "$status" "lock conflict should return 3"
    assert_contains "$out" "failed to acquire lock" "lock conflict should report acquisition failure"
  }

  t09_exdev_error_code_4() {
    local root store venv fakebin out status
    root="$(mk_case_root "09_exdev_code4")"
    store="$root/store"
    venv="$root/project/venv-a"
    fakebin="$root/fakebin"

    mkvenv_like "$venv" "3.12"
    printf 'payload\n' > "$venv/lib/python3.12/site-packages/pkg/a.txt"
    mkdir -p "$fakebin"

    cat > "$fakebin/ln" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-s" ]]; then
  exec /bin/ln "$@"
fi
echo "ln: failed to create hard link: Cross-device link" >&2
exit 1
EOF
    chmod +x "$fakebin/ln"

    run_cmd_capture out status env PATH="$fakebin:$PATH" UNKOENV_STORE="$store" "$SCRIPT" add "$venv"
    assert_eq "4" "$status" "cross-device link should return 4"
    assert_contains "$out" "cross-device link" "error message should mention cross-device"
  }

  run_test "09/exit_codes_1_2_3" t09_exit_codes_1_2_3
  run_test "09/exdev_error_code_4" t09_exdev_error_code_4
}

CATEGORIES+=("run_category_09_error_exit")
