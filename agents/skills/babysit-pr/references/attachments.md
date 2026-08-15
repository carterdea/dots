# Attaching images and video

`gh` has no attach command, but the upload endpoint behind the browser's drag-and-drop takes a `gh auth token`:

```bash
FILE=shot.png
NAME=$(printf %s "$(basename "$FILE")" | jq -sRr @uri)
MIME=$(printf %s "$(file --mime-type -b "$FILE")" | jq -sRr @uri)
REPO_ID=$(gh api "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)" --jq .id)

printf 'Authorization: Bearer %s\n' "$(gh auth token)" | curl -sS --fail-with-body -X POST \
  --connect-timeout 15 --max-time 300 \
  "https://uploads.github.com/user-attachments/assets?name=$NAME&content_type=$MIME&repository_id=$REPO_ID" \
  -H @- \
  -H "Accept: application/json" \
  --data-binary "@$FILE"
```

`MIME` is encoded because `image/svg+xml` arrives as `image/svg xml` otherwise — `+` is a space in a query value. The token goes in over stdin so it never lands in `curl`'s arguments, where any process on the machine could read it.

The JSON response carries a `github.com/user-attachments/assets/...` URL. Embed images as `![](url)`; post a video URL bare and GitHub renders a player. These URLs are scoped to the repository, so they work on private repos.

The endpoint is undocumented and could break. If it returns an error, say so and post the finding without the image rather than dropping the reply.
