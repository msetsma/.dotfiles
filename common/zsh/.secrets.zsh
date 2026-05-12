# export OPENROUTER_API_KEY=$(gopass show -o apis/openrouter)

export AZURE_OPENAI_BASE_URL=$(security find-generic-password -a "azure-openai" -s "azure-openai-endpoint" -w 2>/dev/null)
export AZURE_RESOURCE_NAME=$(security find-generic-password -s "resource_name" -w 2>/dev/null)
export AZURE_OPENAI_API_KEY=$(security find-generic-password -a "azure-openai" -s "azure-openai-api-key" -w 2>/dev/null)