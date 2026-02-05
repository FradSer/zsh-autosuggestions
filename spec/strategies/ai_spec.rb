describe 'the `ai` suggestion strategy' do
 let(:options) { ["ZSH_AUTOSUGGEST_STRATEGY=(ai history)"] }

 let(:before_sourcing) do
 -> {
 session.run_command('curl() {
  if [[ "$*" == *"max-time"* ]]; then
  cat <<EOF
{"choices":[{"message":{"content":"git status --short"}}]}
200
EOF
   fi
  }')
  }
 end

  context 'when API key is not set' do
  it 'returns no suggestion and falls through to next strategy' do
 with_history('git status --short') do
   session.send_string('git st')
  wait_for { session.content }.to eq('git status --short')
  end
 end
  end

 context 'when API key is set' do
  let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_STRATEGY=(ai history)"] }

  context 'and curl/jq are available' do
  it 'suggests completion from AI' do
  session.send_string('git st')
  wait_for { session.content }.to eq('git status --short')
  end
  end

  context 'when input is below minimum threshold' do
  let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_AI_MIN_INPUT=5", "ZSH_AUTOSUGGEST_STRATEGY=(ai history)"] }

  it 'returns no suggestion for short input' do
   with_history('git status') do
  session.send_string('git')
   wait_for { session.content }.to eq('git status')
   end
  end
  end
 end

 context 'when curl fails' do
  let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_STRATEGY=(ai history)"] }

 let(:before_sourcing) do
  -> {
  session.run_command('curl() { return 1 }')
 }
 end

 it 'falls through to next strategy' do
  with_history('git status') do
  session.send_string('git st')
  wait_for { session.content }.to eq('git status')
  end
  end
  end

 context 'when API returns HTTP error' do
  let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_STRATEGY=(ai history)"] }

 let(:before_sourcing) do
  -> {
  session.run_command('curl() {
  if [[ "$*" == *"max-time"* ]]; then
  cat <<EOF
{"error":"Unauthorized"}
401
EOF
  fi
 }')
 }
 end

 it 'falls through to next strategy' do
   with_history('git status') do
   session.send_string('git st')
  wait_for { session.content }.to eq('git status')
  end
 end
 end

 context 'when API returns malformed JSON' do
  let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_STRATEGY=(ai history)"] }

 let(:before_sourcing) do
  -> {
  session.run_command('curl() {
  if [[ "$*" == *"max-time"* ]]; then
  cat <<EOF
not valid json
200
EOF
   fi
 }')
  }
 end

 it 'falls through to next strategy' do
 with_history('git status') do
  session.send_string('git st')
  wait_for { session.content }.to eq('git status')
  end
 end
 end

 context 'response normalization' do
 let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_STRATEGY=(ai)"] }

  context 'when response has markdown code fences' do
 let(:before_sourcing) do
  -> {
  session.run_command('curl() {
  if [[ "$*" == *"max-time"* ]]; then
  cat <<EOF
{"choices":[{"message":{"content":"```\\ngit status\\n```"}}]}
200
EOF
   fi
  }')
  }
  end

  it 'strips the code fences' do
  session.send_string('git st')
  wait_for { session.content }.to eq('git status')
  end
  end

  context 'when response includes the input prefix' do
  let(:before_sourcing) do
  -> {
   session.run_command('curl() {
  if [[ "$*" == *"max-time"* ]]; then
  cat <<EOF
{"choices":[{"message":{"content":"git status --short"}}]}
200
EOF
  fi
   }')
  }
 end

  it 'uses the complete command' do
  session.send_string('git st')
  wait_for { session.content }.to eq('git status --short')
 end
  end
 end

 context 'fallback strategy' do
 let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_STRATEGY=(ai history)"] }

 let(:before_sourcing) do
 -> {
  session.run_command('curl() { return 1 }')
 }
 end

 it 'uses history when AI fails' do
 with_history('git status --long') do
  session.send_string('git st')
  wait_for { session.content }.to eq('git status --long')
 end
 end
 end
end

 context 'prompt artifact stripping' do
 let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_STRATEGY=(ai)"] }

 let(:before_sourcing) do
 -> {
 session.run_command('curl() {
 if [[ "$*" == *"max-time"* ]]; then
 cat <<EOFCURL
{"choices":[{"message":{"content":"$ git status"}}]}
200
EOFCURL
 fi
 }')
 }
 end

 it 'strips $ prompt artifact' do
 session.send_string('git st')
 wait_for { session.content }.to eq('git status')
 end
 end

 context 'empty buffer suggestions' do
 let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_ALLOW_EMPTY_BUFFER=1", "ZSH_AUTOSUGGEST_STRATEGY=(ai)"] }

 let(:before_sourcing) do
 -> {
 session.run_command('curl() {
 if [[ "$*" == *"max-time"* ]]; then
 cat <<EOFCURL
{"choices":[{"message":{"content":"git status"}}]}
200
EOFCURL
 fi
 }')
 }
 end

 it 'suggests command on empty buffer when enabled' do
 session.send_keys('C-c')
 wait_for { session.content(esc_seqs: true) }.to match(/git status/)
 end
 end

 context 'empty buffer without flag' do
 let(:options) { ["ZSH_AUTOSUGGEST_AI_API_KEY=test-key", "ZSH_AUTOSUGGEST_STRATEGY=(ai history)"] }

 let(:before_sourcing) do
 -> {
 session.run_command('curl() {
 if [[ "$*" == *"max-time"* ]]; then
 cat <<EOFCURL
{"choices":[{"message":{"content":"git status"}}]}
200
EOFCURL
 fi
 }')
 }
 end

 it 'does not suggest on empty buffer by default' do
 with_history('git status') do
 sleep 0.5
 expect(session.content).to_not match(/git status/)
 session.send_string('git')
 wait_for { session.content }.to eq('git status')
 end
 end
 end
