gcloud-set-project() {
  CACHE_FILE="$HOME/.cache/gcloud_projects_list"
  CACHE_TTL=3600  # Cache for 1 hour

  # Get the current timestamp and the cache file's last modification time
  NOW=$(date +%s)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD stat)
    CACHE_MOD_TIME=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null || echo 0)
  else
    # Linux (GNU stat)
    CACHE_MOD_TIME=$(stat -c "%Y" "$CACHE_FILE" 2>/dev/null || echo 0)
  fi

  # Check if the cache needs updating
  if [ ! -f "$CACHE_FILE" ] || [ $((NOW - CACHE_MOD_TIME)) -gt $CACHE_TTL ]; then
    echo "Updating project list cache..." >&2
    gcloud projects list --format="table(projectId, name)" > "$CACHE_FILE"
  fi

  SELECTED_PROJECT=$(cat "$CACHE_FILE" | fzf | awk '{print $1}')
  if [ -n "$SELECTED_PROJECT" ]; then
    gcloud config set project "$SELECTED_PROJECT"
    echo "Default project set to: $SELECTED_PROJECT"
  else
    echo "No project selected."
  fi
}

gcloud-find-project() {
  CACHE_FILE="$HOME/.cache/gcloud_projects_list"
  CACHE_TTL=3600  # Cache for 1 hour

  # Get the current timestamp and the cache file's last modification time
  NOW=$(date +%s)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD stat)
    CACHE_MOD_TIME=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null || echo 0)
  else
    # Linux (GNU stat)
    CACHE_MOD_TIME=$(stat -c "%Y" "$CACHE_FILE" 2>/dev/null || echo 0)
  fi

  # Check if the cache needs updating
  if [ ! -f "$CACHE_FILE" ] || [ $((NOW - CACHE_MOD_TIME)) -gt $CACHE_TTL ]; then
    echo "Updating project list cache..." >&2
    gcloud projects list --format="table(projectId, name)" > "$CACHE_FILE"
  fi

  SELECTED_PROJECT=$(cat "$CACHE_FILE" | fzf | awk '{print $1}')
  if [ -n "$SELECTED_PROJECT" ]; then
    echo -n "$SELECTED_PROJECT" | pbcopy
    echo "Copied project ID: $SELECTED_PROJECT to clipboard." >&2
  else
    echo "No project selected." >&2
  fi
}