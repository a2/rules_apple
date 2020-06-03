#!/bin/bash

# Copyright 2020 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eu

newline=$'\n'

# This script allows many of the functions in apple_shell_testutils.sh to be
# called through apple_verification_test_runner.sh.template by using environment
# variables.
#
# Supported operations:
#  BINARY_TEST_FILE: The file to test with `PLIST_TEST_VALUES`
#  PLIST_TEST_VALUES: Array for keys and values in the format "KEY VALUE" where
#      the key is a string without spaces, followed by by a single space,
#      followed by the value to test. * can be used as a wildcard value.

# Test that the binary contains and does not contain the specified plist symbols.
if [[ -n "${BINARY_TEST_FILE-}" ]]; then
  path=$(eval echo "$BINARY_TEST_FILE")
  if [[ ! -e "$path" ]]; then
    fail "Could not find binary at \"$path\""
  fi
  # Use `launchctl plist` to test for key/value pairs in an embedded plist file.
  if [[ -n "${PLIST_TEST_VALUES-}" ]]; then
    for test_values in "${PLIST_TEST_VALUES[@]}"
    do
      # Keys and expected-values are in the format "KEY VALUE".
      IFS=' ' read -r key expected_value <<< "$test_values"
      # Replace wildcard "*" characters with a sed-friendly ".*" wildcard.
      expected_value=${expected_value/"*"/".*"}
      value="$(launchctl plist $path | sed -nE "s/.*\"$key\" = \"($expected_value)\";.*/\1/p" || true)"
      if [[ ! -n "$value" ]]; then
        fail "Expected plist key \"$key\" to be \"$expected_value\" in plist " \
            "embedded in \"$path\". Plist contents:$newline" \
            "$(launchctl plist $path)"
      fi
    done
  fi
fi
