gcloud-set-project() {
  SELECTED_PROJECT=$(gcloud projects list --format="table(projectId, name)" | fzf | awk '{print $1}')
  if [ -n "$SELECTED_PROJECT" ]; then
    gcloud config set project "$SELECTED_PROJECT"
    echo "Default project set to: $SELECTED_PROJECT"
  else
    echo "No project selected."
  fi
}