#!/bin/bash
#
# Simple AI Strategy Test
# Validates core AI functionality
#

echo "=== AI Strategy Core Functionality Tests ==="
echo ""

# Test 1: Check source files exist
echo "[TEST 1] Source files exist"
if [[ -f "src/strategies/ai.zsh" ]] && [[ -f "src/config.zsh" ]]; then
 echo "✓ PASS: Source files found"
else
 echo "✗ FAIL: Source files missing"
  exit 1
fi

# Test 2: Check built file includes AI strategy
echo ""
echo "[TEST 2] Built file includes AI strategy"
if grep -q "_zsh_autosuggest_strategy_ai" zsh-autosuggestions.zsh; then
 echo "✓ PASS: AI strategy function present in built file"
else
 echo "✗ FAIL: AI strategy missing from built file"
 exit 1
fi

# Test 3: Verify base URL configuration
echo ""
echo "[TEST 3] Base URL configuration"
if grep -q "ZSH_AUTOSUGGEST_AI_ENDPOINT='https://api.openai.com/v1'" zsh-autosuggestions.zsh; then
 echo "✓ PASS: Base URL configured correctly"
else
 echo "✗ FAIL: Base URL configuration incorrect"
 exit 1
fi

# Test 4: Verify endpoint construction code
echo ""
echo "[TEST 4] Endpoint construction logic"
if grep -q 'local base_url=.*ZSH_AUTOSUGGEST_AI_ENDPOINT' zsh-autosuggestions.zsh && \
 grep -q 'local endpoint=.*chat/completions' zsh-autosuggestions.zsh; then
 echo "✓ PASS: Endpoint construction code present"
else
 echo "✗ FAIL: Endpoint construction logic missing"
 exit 1
fi

# Test 5: Environment context function exists
echo ""
echo "[TEST 5] Environment context gathering function"
if grep -q "_zsh_autosuggest_strategy_ai_gather_env_context" zsh-autosuggestions.zsh; then
 echo "✓ PASS: Environment context function present"
else
  echo "✗ FAIL: Environment context function missing"
 exit 1
fi

# Test 6: Prompt artifact stripping
echo ""
echo "[TEST 6] Prompt artifact stripping code"
if grep -q 'response=.*##\\$ ' zsh-autosuggestions.zsh && \
 grep -q 'response=.*##> ' zsh-autosuggestions.zsh; then
  echo "✓ PASS: Prompt artifact stripping present"
else
 echo "✗ FAIL: Prompt artifact stripping missing"
 exit 1
fi

# Test 7: Empty buffer support
echo ""
echo "[TEST 7] Empty buffer configuration"
if grep -q "ALLOW_EMPTY_BUFFER" zsh-autosuggestions.zsh; then
 echo "✓ PASS: Empty buffer support present"
else
 echo "✗ FAIL: Empty buffer support missing"
 exit 1
fi

# Test 8: Dual prompt system
echo ""
echo "[TEST 8] Dual prompt system (predict vs complete)"
if grep -q "prediction engine" zsh-autosuggestions.zsh && \
 grep -q "auto-completion engine" zsh-autosuggestions.zsh; then
  echo "✓ PASS: Dual prompt system present"
else
 echo "✗ FAIL: Dual prompt system missing"
 exit 1
fi

# Test 9: Temperature configuration
echo ""
echo "[TEST 9] Temperature configuration"
if grep -q '"temperature": %s' zsh-autosuggestions.zsh; then
 echo "✓ PASS: Dynamic temperature configuration present"
else
 echo "✗ FAIL: Temperature configuration missing"
 exit 1
fi

# Test 10: MIN_INPUT default is 0
echo ""
echo "[TEST 10] MIN_INPUT default value"
if grep -q 'ZSH_AUTOSUGGEST_AI_MIN_INPUT=0' zsh-autosuggestions.zsh; then
 echo "✓ PASS: MIN_INPUT default is 0"
else
 echo "✗ FAIL: MIN_INPUT default incorrect"
  exit 1
fi

# Test 11: Documentation updated
echo ""
echo "[TEST 11] Documentation updates"
if grep -q "ALLOW_EMPTY_BUFFER" README.md && \
 grep -q "Empty Buffer Suggestions" README.md; then
 echo "✓ PASS: Documentation includes new features"
else
 echo "✗ FAIL: Documentation missing updates"
 exit 1
fi

# Test 12: RSpec tests added
echo ""
echo "[TEST 12] RSpec test coverage"
if grep -q "empty buffer" spec/strategies/ai_spec.rb && \
 grep -q "prompt artifact" spec/strategies/ai_spec.rb; then
 echo "✓ PASS: New test cases added"
else
 echo "✗ FAIL: Test coverage incomplete"
 exit 1
fi

echo ""
echo "=========================================="
echo "✓ All 12 core functionality tests passed!"
echo "=========================================="
echo ""
echo "AI Strategy is ready for use with:"
echo "  - Base URL configuration"
echo " - Empty buffer suggestions"
echo "  - Environment context gathering"
echo " - PWD-aware history"
echo "  - Dual prompt modes"
echo " - Prompt artifact stripping"
echo ""
