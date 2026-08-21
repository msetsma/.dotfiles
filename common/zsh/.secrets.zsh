export AZURE_OPENAI_BASE_URL=$(security find-generic-password -a "azure-openai" -s "azure-openai-endpoint" -w 2>/dev/null)
export AZURE_RESOURCE_NAME=$(security find-generic-password -s "resource_name" -w 2>/dev/null)
export AZURE_OPENAI_API_KEY=$(security find-generic-password -a "azure-openai" -s "azure-openai-api-key" -w 2>/dev/null)

# Claude Code runs on the Anthropic account, not Foundry. Unset in case an
# inherited environment still carries the old Foundry routing.
unset ANTHROPIC_FOUNDRY_API_KEY ANTHROPIC_FOUNDRY_RESOURCE CLAUDE_CODE_USE_FOUNDRY
# To go back to Foundry:
# export ANTHROPIC_FOUNDRY_API_KEY=$(security find-generic-password -a "azure-openai" -s "azure-openai-api-key" -w 2>/dev/null)
# export ANTHROPIC_FOUNDRY_RESOURCE=$(security find-generic-password -a "azure" -s "athropic-resource" -w 2>/dev/null)
# export CLAUDE_CODE_USE_FOUNDRY=1