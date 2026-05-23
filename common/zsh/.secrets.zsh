# export OPENROUTER_API_KEY=$(gopass show -o apis/openrouter)

export AZURE_OPENAI_BASE_URL=$(security find-generic-password -a "azure-openai" -s "azure-openai-endpoint" -w 2>/dev/null)
export AZURE_RESOURCE_NAME=$(security find-generic-password -s "resource_name" -w 2>/dev/null)
export AZURE_OPENAI_API_KEY=$(security find-generic-password -a "azure-openai" -s "azure-openai-api-key" -w 2>/dev/null)

# claude code to 
export ANTHROPIC_FOUNDRY_API_KEY=$(security find-generic-password -a "azure-openai" -s "azure-openai-api-key" -w 2>/dev/null)
export CLAUDE_CODE_USE_FOUNDRY=1
export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-7'
export ANTHROPIC_DEFAULT_SONNET_MODEL='claude-sonnet-4-6'
export ANTHROPIC_DEFAULT_HAIKU_MODEL='claude-haiku-4-5'