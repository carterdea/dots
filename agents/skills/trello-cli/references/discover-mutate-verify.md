# Discover, Mutate, Verify

Use this protocol for every Trello write: comments, moves, attachments, checklist updates, member changes, labels, custom fields, archiving, or card creation.

## Protocol

1. **Discover**
   - Verify auth with `trello auth status` before resource commands.
   - Fetch the current card, board, list, checklist, attachment, member, label, or custom-field state needed for the write.
   - Resolve names to IDs. Do not pass a guessed board, list, card, member, label, checklist, or custom-field ID.
   - Record the pre-mutation state that proves a change is needed, such as `idList`, checklist item state, attachment count, assignee IDs, or existing comments.

2. **Mutate**
   - Run the smallest CLI command that performs the intended change.
   - Use IDs from the discover step.
   - For attachments, validate the local file exists before `attachments add-file`.
   - For comments, include the exact PR, preview, Customizer, Figma, QA, or blocker fields the parent workflow requires.

3. **Verify**
   - Re-fetch the changed resource after every mutation that affects delivery state.
   - Compare the returned state to the intended state:
     - card move: `idList` equals the target list ID
     - comment: newest relevant comment exists and contains the required links/body
     - attachment: expected attachment filename/count is present
     - checklist: target items are checked or unchecked as intended
     - member change: expected member ID is present or absent
   - If verification fails, retry discovery once to rule out stale state. If it still fails, stop and report the exact mutation that could not be verified.

## Completion Criteria

A Trello mutation is not complete until the verify step proves the remote Trello state changed. A successful CLI response alone is insufficient.

For multi-write handoffs, complete every required write and verify each one before declaring the parent skill complete:

- required comment exists with the expected fields
- required screenshots or repro files are attached
- required checklist state is updated when the card uses a checklist
- required card move has the expected `idList`
- required reassignment has the expected member state

If any required Trello write cannot be verified, the parent workflow ends blocked, with the failed command, expected state, actual state, and card URL in the final response.
