# Attachment Download Workflow

Use this workflow when a Trello card's attachments may contain requirements, screenshots, mockups, PDFs, archives, or other source material.

1. List attachments with `trello attachments list --card <card-id>`.
2. Create a per-card directory under `/tmp`, using the calling workflow's prefix, for example `/tmp/<workflow-name>-<card-short-id>/`.
3. Download each accessible attachment with:

   ```bash
   mkdir -p /tmp/<workflow-name>-<card-short-id>/<attachment-id>/
   trello attachments download --card <card-id> --attachment <attachment-id> --output /tmp/<workflow-name>-<card-short-id>/<attachment-id>/
   ```

4. Keep each attachment in an attachment-id directory or use an attachment-id-prefixed explicit output path so duplicate Trello filenames cannot collide.
5. Use `--force` only when re-running and intentionally replacing a prior download.
6. Inspect downloaded attachments before deciding what to build, QA, or report:
   - Open images/screenshots visually.
   - Extract or read text from PDFs, markdown, text, CSV, JSON, or HTML files with local tooling.
   - For zips or archives, list contents first and extract only into the same `/tmp/<workflow-name>-<card-short-id>/` directory when the contents are relevant.
   - For URL attachments that download as links or external files, open/read the linked resource when accessible.
7. Record attachment findings and use them alongside the card description, comments, checklists, labels, and acceptance criteria. If an attachment cannot be downloaded or opened, record the reason and continue only if the remaining card context is sufficient.
