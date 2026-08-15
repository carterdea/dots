# Attaching images and video

`gh` has no attach command, but the upload endpoint behind the browser's drag-and-drop takes a `gh auth token`:

```bash
FILE=shot.png
NAME=$(printf %s "$(basename "$FILE")" | jq -sRr @uri)
MIME=$(file --mime-type -b "$FILE")
REPO_ID=$(gh api "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)" --jq .id)

curl -sS --fail-with-body -X POST \
  "https://uploads.github.com/user-attachments/assets?name=$NAME&content_type=$MIME&repository_id=$REPO_ID" \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/json" \
  --data-binary "@$FILE"
```

The JSON response carries a `github.com/user-attachments/assets/...` URL. Embed images as `![](url)`; post a video URL bare and GitHub renders a player. These URLs are scoped to the repository, so they work on private repos.

The endpoint is undocumented and could break. If it returns an error, say so and post the finding without the image rather than dropping the reply.
