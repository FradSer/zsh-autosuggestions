describe 'the `ai` strategy debug logging' do
  let(:options) { ["ZSH_AUTOSUGGEST_STRATEGY=(ai)"] }

  context 'when debug is enabled' do
    let(:options) do
      [
        "ZSH_AUTOSUGGEST_STRATEGY=(ai)",
        "ZSH_AUTOSUGGEST_AI_DEBUG=1"
      ]
    end

    it 'logs why AI suggestion is skipped when API key is missing' do
      session.send_string('brew')
      wait_for { session.content }.to match(/\[zsh-autosuggestions ai\] API key not set/)
    end
  end

  context 'when debug is disabled by default' do
    it 'does not print AI debug logs' do
      session.send_string('brew')
      sleep 0.2
      expect(session.content).not_to match(/\[zsh-autosuggestions ai\]/)
    end
  end
end
