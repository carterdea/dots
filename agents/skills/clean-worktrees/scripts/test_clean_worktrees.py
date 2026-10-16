"""Leftover scan over a shared root must never claim another repo's worktree."""

import tempfile
import unittest
from pathlib import Path

import clean_worktrees as cw


def make_worktree(path: Path) -> Path:
    path.mkdir(parents=True)
    (path / ".git").write_text("gitdir: /elsewhere/.git/worktrees/x\n")
    return path


class LeftoverScanTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.root = self.tmp / "worktrees"
        self.audit = self.tmp / "audit"
        self.audit.mkdir()

    def leftovers(self, registered: set[Path] = frozenset()) -> list[str]:
        cw.move_leftovers([self.root], self.audit, self.tmp / "trash", False, set(registered))
        lines = (self.audit / "leftover-directories.tsv").read_text().splitlines()
        return sorted(Path(line.split("\t")[1]).name for line in lines)

    def test_other_repos_worktrees_are_not_leftovers(self):
        make_worktree(self.root / "abcd" / "other-repo")
        make_worktree(self.root / "direct-other-repo")
        self.assertEqual(self.leftovers(), [])

    def test_empty_codex_shell_is_a_leftover(self):
        shell = self.root / "feb8"
        shell.mkdir(parents=True)
        (shell / ".codex-worktree-name").write_text("feb8")
        self.assertEqual(self.leftovers(), ["feb8"])

    def test_registered_worktree_is_not_a_leftover(self):
        own = self.root / "mine"
        own.mkdir(parents=True)
        self.assertEqual(self.leftovers({own.resolve()}), [])

    def test_apply_moves_only_leftovers(self):
        other = make_worktree(self.root / "abcd" / "other-repo")
        (self.root / "feb8").mkdir()
        cw.move_leftovers([self.root], self.audit, self.tmp / "trash", True, set())
        self.assertTrue(other.exists())
        self.assertFalse((self.root / "feb8").exists())


if __name__ == "__main__":
    unittest.main()
