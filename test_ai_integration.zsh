#!/usr/bin/env zsh
#
# AI Strategy Integration Test
# Tests that AI functionality is working correctly without requiring real API calls
#

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_test() {
  echo "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
  echo "${GREEN}[PASS]${NC} $1"
  ((TESTS_PASSED++))
}

print_fail() {
 echo "${RED}[FAIL]${NC} $1"
 ((TESTS_FAILED++))
}

# Source the plugin
source ./zsh-autosuggestions.zsh

# Mock curl for testing
curl() {
 local url=""
 local data=""
  local expect_url="https://api.openai.com/v1/chat/completions"

 # Parse arguments
 while [[ $# -gt 0 ]]; do
 case "$1" in
   -d)
    data="$2"
  shift 2
   ;;
  http*)
   url="$1"
  shift
   ;;
  *)
  shift
   ;;
  esac
  done

 # Verify endpoint construction
  if [[ "$url" != "$expect_url" ]]; then
  echo '{"error":"wrong endpoint"}'
  echo '400'
   return 1
 fi

 # Return mock response based on data
  echo '{"choices":[{"message":{"content":"git status"}}]}'
  echo '200'
}

# Mock jq
jq() {
 if [[ "$1" == "-r" ]]; then
 # Simple extraction of content field
  grep -o '"content":"[^"]*"' | cut -d'"' -f4
 fi
}

# Mock ls for environment context
ls() {
 if [[ "$1" == "-1" ]]; then
  echo "file1.txt"
  echo "file2.txt"
   echo "README.md"
  fi
}

# Mock git for environment context
git() {
  if [[ "$1" == "branch" ]]; then
  echo "master"
  elif [[ "$1" == "status" ]]; then
  echo "M file1.txt"
 echo "?? file2.txt"
  fi
}

echo "=========================================="
echo "AI Strategy Integration Tests"
echo "=========================================="
echo ""

# Test 1: Endpoint construction
print_test "Endpoint construction with base URL"
((TESTS_RUN++))
export ZSH_AUTOSUGGEST_AI_API_KEY="test-key"
export ZSH_AUTOSUGGEST_AI_ENDPOINT="https://api.openai.com/v1"
result=$(_zsh_autosuggest_strategy_ai "test" 2>&1)
if [[ $? -eq 0 ]]; then
 print_pass "Base URL correctly constructs full endpoint"
else
   print_fail "Endpoint construction failed"
fi

# Test 2: Custom base URL
print_test "Custom base URL endpoint construction"
((TESTS_RUN++))
export ZSH_AUTOSUGGEST_AI_ENDPOINT="http://localhost:11434/v1"
# Override curl mock for this test
curl() {
 local url=""
  while [[ $# -gt 0 ]]; do
   case "$1" in
  http*)
     url="$1"
    shift
   ;;
   *)
   shift
    ;;
 esac
  done

 if [[ "$url" == "http://localhost:11434/v1/chat/completions" ]]; then
  echo '{"choices":[{"message":{"content":"ollama response"}}]}'
   echo '200'
 else
   echo '{"error":"wrong endpoint"}'
 echo '400'
 fi
}
result=$(_zsh_autosuggest_strategy_ai "test" 2>&1)
if [[ $? -eq 0 ]]; then
 print_pass "Custom base URL works correctly"
else
 print_fail "Custom base URL failed"
fi

# Reset curl mock
curl() {
  local url=""
  local data=""
  while [[ $# -gt 0 ]]; do
  case "$1" in
   -d)
  data="$2"
    shift 2
   ;;
  http*)
  url="$1"
   shift
    ;;
   *)
    shift
    ;;
 esac
 done
  echo '{"choices":[{"message":{"content":"git status"}}]}'
  echo '200'
}

# Test 3: Environment context gathering
print_test "Environment context gathering"
((TESTS_RUN++))
typeset -g reply
_zsh_autosuggest_strategy_ai_gather_env_context
if [[ -n "${reply[dir_contents]}" ]]; then
 print_pass "Directory contents captured: ${reply[dir_contents]}"
else
  print_fail "Directory contents not captured"
fi

# Test 4: PWD-aware history gathering
print_test "PWD-aware history gathering"
((TESTS_RUN++))
# Add some history
fc -p # Push history
print -s "git status"
print -s "ls -la"
print -s "cd /tmp"
_zsh_autosuggest_strategy_ai_gather_context
if [[ ${#reply[@]} -gt 0 ]]; then
  print_pass "History context gathered: ${#reply[@]} entries"
else
 print_fail "History gathering failed"
fi

# Test 5: Response normalization with prompt artifacts
print_test "Prompt artifact stripping"
((TESTS_RUN++))
result=$(_zsh_autosuggest_strategy_ai_normalize "$ git status" "git")
if [[ "$result" == "git status" ]]; then
  print_pass "$ prompt artifact stripped correctly"
else
 print_fail "Prompt artifact stripping failed: got '$result'"
fi

# Test 6: Response normalization with > artifact
print_test "> prompt artifact stripping"
((TESTS_RUN++))
result=$(_zsh_autosuggest_strategy_ai_normalize "> ls -la" "ls")
if [[ "$result" == "ls -la" ]]; then
  print_pass "> prompt artifact stripped correctly"
else
  print_fail "> artifact stripping failed: got '$result'"
fi

# Test 7: Minimum input length (now default 0)
print_test "Minimum input length allows empty buffer"
((TESTS_RUN++))
export ZSH_AUTOSUGGEST_AI_MIN_INPUT=0
result=$(_zsh_autosuggest_strategy_ai "" 2>&1)
# Should not fail due to length check
if [[ $? -eq 0 ]] || [[ "$result" != *"too short"* ]]; then
 print_pass "Empty buffer allowed with MIN_INPUT=0"
else
  print_fail "Empty buffer rejected incorrectly"
fi

# Test 8: JSON escaping
print_test "JSON escaping for special characters"
((TESTS_RUN++))
result=$(_zsh_autosuggest_strategy_ai_json_escape 'test "quote" and \backslash')
if [[ "$result" == *'\"'* ]] && [[ "$result" == *'\\'* ]]; then
  print_pass "Special characters escaped correctly"
else
 print_fail "JSON escaping failed: got '$result'"
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run:  $TESTS_RUN"
echo "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${GREEN}✓ All tests passed!${NC}"
 exit 0
else
 echo "${RED}✗ Some tests failed${NC}"
 exit 1
fi
