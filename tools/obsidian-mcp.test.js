const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { setTimeout: delay } = require("node:timers/promises");

const {
  TOOL_HANDLERS,
  listAttachmentFiles,
  listMarkdownFiles,
  parseSyncedVaultsOutput,
  patchHeadingSection,
  resetVaultCaches,
  resolveNotePath,
  resolveSourceAttachmentPath,
  resolveVaultPath,
  searchMarkdownFiles,
} = require("./obsidian-mcp.js");

function withVault(setup, run) {
  const vaultPath = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-mcp-"));
  const cliPath = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-cli-"));
  const previousPath = process.env.PATH;
  const previousTestVaultPath = process.env.OBSIDIAN_TEST_VAULT_PATH;
  process.env.OBSIDIAN_TEST_VAULT_PATH = vaultPath;
  process.env.PATH = `${cliPath}:${previousPath || ""}`;
  fs.writeFileSync(
    path.join(cliPath, "obsidian"),
    [
      "#!/bin/sh",
      'if [ "$1" = "--help" ]; then',
      '  echo "obsidian help"',
      '  exit 0',
      "fi",
      'if [ "$1" = "vault" ] && [ "$2" = "info=path" ]; then',
      '  printf "%s\\n" "$OBSIDIAN_TEST_VAULT_PATH"',
      '  exit 0',
      "fi",
      'if [ "$1" = "vault=$OBSIDIAN_VAULT_NAME" ] && [ "$2" = "vault" ] && [ "$3" = "info=path" ]; then',
      '  printf "%s\\n" "$OBSIDIAN_TEST_VAULT_PATH"',
      '  exit 0',
      "fi",
      'echo "unsupported args" >&2',
      "exit 1",
      "",
    ].join("\n"),
    { mode: 0o755 },
  );

  try {
    setup(vaultPath);
    return run(vaultPath);
  } finally {
    resetVaultCaches();

    if (previousTestVaultPath === undefined) {
      delete process.env.OBSIDIAN_TEST_VAULT_PATH;
    } else {
      process.env.OBSIDIAN_TEST_VAULT_PATH = previousTestVaultPath;
    }

    process.env.PATH = previousPath;

    fs.rmSync(cliPath, { recursive: true, force: true });
    fs.rmSync(vaultPath, { recursive: true, force: true });
  }
}

async function withVaultAsync(setup, run) {
  const vaultPath = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-mcp-"));
  const cliPath = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-cli-"));
  const previousPath = process.env.PATH;
  const previousTestVaultPath = process.env.OBSIDIAN_TEST_VAULT_PATH;
  process.env.OBSIDIAN_TEST_VAULT_PATH = vaultPath;
  process.env.PATH = `${cliPath}:${previousPath || ""}`;
  fs.writeFileSync(
    path.join(cliPath, "obsidian"),
    [
      "#!/bin/sh",
      'if [ "$1" = "--help" ]; then',
      '  echo "obsidian help"',
      '  exit 0',
      "fi",
      'if [ "$1" = "vault" ] && [ "$2" = "info=path" ]; then',
      '  printf "%s\\n" "$OBSIDIAN_TEST_VAULT_PATH"',
      '  exit 0',
      "fi",
      'if [ "$1" = "vault=$OBSIDIAN_VAULT_NAME" ] && [ "$2" = "vault" ] && [ "$3" = "info=path" ]; then',
      '  printf "%s\\n" "$OBSIDIAN_TEST_VAULT_PATH"',
      '  exit 0',
      "fi",
      'echo "unsupported args" >&2',
      "exit 1",
      "",
    ].join("\n"),
    { mode: 0o755 },
  );

  try {
    await setup(vaultPath);
    return await run(vaultPath);
  } finally {
    resetVaultCaches();

    if (previousTestVaultPath === undefined) {
      delete process.env.OBSIDIAN_TEST_VAULT_PATH;
    } else {
      process.env.OBSIDIAN_TEST_VAULT_PATH = previousTestVaultPath;
    }

    process.env.PATH = previousPath;

    fs.rmSync(cliPath, { recursive: true, force: true });
    fs.rmSync(vaultPath, { recursive: true, force: true });
  }
}

function writeNote(vaultPath, relativePath, content) {
  const noteFile = path.join(vaultPath, relativePath);
  fs.mkdirSync(path.dirname(noteFile), { recursive: true });
  fs.writeFileSync(noteFile, content, "utf8");
}

function writeAttachment(vaultPath, relativePath, content) {
  const attachmentFile = path.join(vaultPath, relativePath);
  fs.mkdirSync(path.dirname(attachmentFile), { recursive: true });
  fs.writeFileSync(attachmentFile, content);
}

function withTempFile(content, run) {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-attachment-source-"));
  const sourcePath = path.join(tempDir, "source.bin");
  fs.writeFileSync(sourcePath, content);

  try {
    return run(sourcePath);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
}

function parseToolResult(result) {
  return JSON.parse(result.content[0].text);
}

async function waitFor(assertion, timeoutMs = 1_000) {
  const startedAt = Date.now();

  while (true) {
    try {
      return assertion();
    } catch (error) {
      if (Date.now() - startedAt >= timeoutMs) {
        throw error;
      }
      await delay(25);
    }
  }
}

test("upsert links to an existing related note outside the capture folder", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "Knowledge/SQLite.md", "# SQLite\n");
    },
    () => {
      const result = TOOL_HANDLERS.obsidian_upsert_knowledge_note({
        title: "Cache Notes",
        summary: "Summary",
        details: "Details",
        related: ["SQLite"],
      });

      const payload = parseToolResult(result);
      assert.equal(payload.note_path, "Captured/Cache Notes.md");
      assert.deepEqual(payload.related_links, ["[[Knowledge/SQLite]]"]);
    },
  );
});

test("upsert fails when a related title does not exist", () => {
  withVault(
    () => {},
    () => {
      assert.throws(
        () =>
          TOOL_HANDLERS.obsidian_upsert_knowledge_note({
            title: "Cache Notes",
            summary: "Summary",
            details: "Details",
            related: ["SQLite"],
          }),
        /Related note not found: SQLite/,
      );
    },
  );
});

test("upsert fails when a related title is ambiguous", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "Knowledge/SQLite.md", "# SQLite\n");
      writeNote(vaultPath, "Databases/SQLite.md", "# SQLite\n");
    },
    () => {
      assert.throws(
        () =>
          TOOL_HANDLERS.obsidian_upsert_knowledge_note({
            title: "Cache Notes",
            summary: "Summary",
            details: "Details",
            related: ["SQLite"],
          }),
        /Related note title is ambiguous: SQLite/,
      );
    },
  );
});

test("upsert preserves only links from the Related section", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "Knowledge/Caching.md", "# Caching\n");
      writeNote(vaultPath, "Knowledge/SQLite.md", "# SQLite\n");
      writeNote(
        vaultPath,
        "Captured/Cache Notes.md",
        [
          "---",
          'title: "Cache Notes"',
          "---",
          "",
          "# Cache Notes",
          "",
          "## Summary",
          "Uses [[SQLite]] for local storage.",
          "",
          "## Details",
          "Compare with [[SQLite]] in more detail.",
          "",
          "## Related",
          "- [[Knowledge/Caching]]",
          "",
        ].join("\n"),
      );
    },
    (vaultPath) => {
      const result = TOOL_HANDLERS.obsidian_upsert_knowledge_note({
        title: "Cache Notes",
        summary: "Updated summary with [[SQLite]] inline.",
        details: "Updated details.",
        related: ["SQLite"],
      });

      const payload = parseToolResult(result);
      assert.deepEqual(payload.related_links.sort(), ["[[Knowledge/Caching]]", "[[Knowledge/SQLite]]"]);

      const content = fs.readFileSync(path.join(vaultPath, "Captured/Cache Notes.md"), "utf8");
      const relatedSection = content.split("## Related\n")[1];
      assert.match(relatedSection, /\[\[Knowledge\/Caching\]\]/);
      assert.match(relatedSection, /\[\[Knowledge\/SQLite\]\]/);
      assert.doesNotMatch(relatedSection, /^- \[\[SQLite\]\]$/m);
    },
  );
});

test("upsert rejects slug collisions with a different existing title", () => {
  withVault(
    (vaultPath) => {
      writeNote(
        vaultPath,
        "Captured/Foo Bar.md",
        [
          "---",
          'title: "Foo: Bar"',
          "---",
          "",
          "# Foo: Bar",
          "",
        ].join("\n"),
      );
    },
    () => {
      assert.throws(
        () =>
          TOOL_HANDLERS.obsidian_upsert_knowledge_note({
            title: "Foo / Bar",
            summary: "Summary",
            details: "Details",
          }),
        /Knowledge note path collision: Captured\/Foo Bar.md already belongs to "Foo: Bar"/,
      );
    },
  );
});

test("patchHeadingSection appends and preserves trailing newline", () => {
  const document = ["# Note", "", "## Related", "- [[One]]", ""].join("\n");
  const updated = patchHeadingSection(document, "Related", "append", "- [[Two]]");

  assert.equal(updated, ["# Note", "", "## Related", "- [[One]]", "- [[Two]]", ""].join("\n"));
});

test("patchHeadingSection throws when the heading is missing", () => {
  assert.throws(
    () => patchHeadingSection("# Note\n", "Related", "replace", "content"),
    /Heading not found: Related/,
  );
});

test("resolveNotePath rejects absolute, escaping, and non-markdown paths", () => {
  withVault(
    () => {},
    (vaultPath) => {
      assert.throws(() => resolveNotePath(vaultPath, "/tmp/file.md"), /must be relative/);
      assert.throws(() => resolveNotePath(vaultPath, "../file.md"), /escapes the vault root/);
      assert.throws(() => resolveNotePath(vaultPath, ".obsidian/file.md"), /Hidden note paths are not allowed/);
      assert.throws(() => resolveNotePath(vaultPath, "note.txt"), /must end with \.md/);
    },
  );
});

test("resolveVaultPath rejects empty, absolute, escaping, and null-byte paths", () => {
  withVault(
    () => {},
    (vaultPath) => {
      assert.throws(() => resolveVaultPath(vaultPath, ""), /vault_path is required/);
      assert.throws(() => resolveVaultPath(vaultPath, "/tmp/file.pdf"), /must be relative/);
      assert.throws(() => resolveVaultPath(vaultPath, "../file.pdf"), /escapes the vault root/);
      assert.throws(() => resolveVaultPath(vaultPath, `bad\0file.pdf`), /must not contain null bytes/);
    },
  );
});

test("listMarkdownFiles skips hidden directories and node_modules", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "visible.md", "# Visible\n");
      writeNote(vaultPath, ".obsidian/config.md", "# Hidden\n");
      writeNote(vaultPath, ".trash/discarded.md", "# Hidden\n");
      writeNote(vaultPath, "node_modules/pkg/readme.md", "# Hidden\n");
      writeNote(vaultPath, "notes/kept.md", "# Kept\n");
    },
    (vaultPath) => {
      const files = listMarkdownFiles(vaultPath).map((filePath) => path.relative(vaultPath, filePath));
      assert.deepEqual(files, ["notes/kept.md", "visible.md"]);
    },
  );
});

test("listAttachmentFiles skips markdown files and dotfolders", () => {
  withVault(
    (vaultPath) => {
      writeAttachment(vaultPath, "files/paper.pdf", Buffer.from("pdf"));
      writeAttachment(vaultPath, "files/image.png", Buffer.from("png"));
      writeNote(vaultPath, "files/summary.md", "# Summary\n");
      writeAttachment(vaultPath, ".obsidian/workspace.json", Buffer.from("{}"));
      writeAttachment(vaultPath, ".trash/deleted.pdf", Buffer.from("pdf"));
    },
    (vaultPath) => {
      const files = listAttachmentFiles(vaultPath).map((filePath) => path.relative(vaultPath, filePath));
      assert.deepEqual(files, ["files/image.png", "files/paper.pdf"]);
    },
  );
});

test("resolveSourceAttachmentPath rejects missing, invalid, and oversized sources", () => {
  assert.throws(() => resolveSourceAttachmentPath(""), /source_path is required/);
  assert.throws(() => resolveSourceAttachmentPath(`bad\0file`), /must not contain null bytes/);
  assert.throws(() => resolveSourceAttachmentPath("/tmp/does-not-exist.pdf"), /Source file does not exist/);

  withTempFile(Buffer.from("abcd"), (sourcePath) => {
    assert.deepEqual(resolveSourceAttachmentPath(sourcePath, 10), {
      resolvedSourcePath: sourcePath,
      bytes: 4,
    });
    assert.throws(() => resolveSourceAttachmentPath(sourcePath, 3), /maximum size of 3 bytes/);
  });
});

test("searchMarkdownFiles finds case-insensitive matches and skips hidden notes", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "visible.md", "Alpha\nmatch me\n");
      writeNote(vaultPath, ".obsidian/hidden.md", "match me\n");
      writeNote(vaultPath, "nested/other.md", "MATCH ME\n");
    },
    (vaultPath) => {
      const matches = searchMarkdownFiles(vaultPath, "match me", false, 10)
        .sort((left, right) => left.note_path.localeCompare(right.note_path));
      assert.deepEqual(matches, [
        { note_path: "nested/other.md", line: 1, text: "MATCH ME" },
        { note_path: "visible.md", line: 2, text: "match me" },
      ]);
    },
  );
});

test("searchMarkdownFiles respects case sensitivity and limit", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "one.md", "Match me\nmatch me\n");
      writeNote(vaultPath, "two.md", "match me\n");
    },
    (vaultPath) => {
      assert.deepEqual(searchMarkdownFiles(vaultPath, "Match me", true, 10), [
        { note_path: "one.md", line: 1, text: "Match me" },
      ]);

      assert.deepEqual(searchMarkdownFiles(vaultPath, "match me", false, 2), [
        { note_path: "one.md", line: 1, text: "Match me" },
        { note_path: "one.md", line: 2, text: "match me" },
      ]);
    },
  );
});

test("list notes cache is invalidated after creating a note", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "one.md", "# One\n");
    },
    () => {
      const initial = parseToolResult(TOOL_HANDLERS.obsidian_list_notes({}));
      assert.deepEqual(initial.notes, ["one.md"]);

      TOOL_HANDLERS.obsidian_create_note({
        note_path: "two.md",
        content: "# Two\n",
      });

      const updated = parseToolResult(TOOL_HANDLERS.obsidian_list_notes({}));
      assert.deepEqual(updated.notes, ["one.md", "two.md"]);
    },
  );
});

test("save attachment writes a file and creates parent directories", () => {
  withVault(
    () => {},
    (vaultPath) => {
      withTempFile(Buffer.from("%PDF-1.4\n% test\n", "utf8"), (sourcePath) => {
        const content = fs.readFileSync(sourcePath);
        const result = parseToolResult(
          TOOL_HANDLERS.obsidian_save_attachment({
            vault_path: "Science/attachments/paper.pdf",
            source_path: sourcePath,
          }),
        );

        assert.equal(result.attachment_path, "Science/attachments/paper.pdf");
        assert.equal(result.bytes, content.length);
        assert.equal(result.source_path, sourcePath);
        assert.equal(result.resolved_path, path.join(vaultPath, "Science/attachments/paper.pdf"));
        assert.deepEqual(fs.readFileSync(path.join(vaultPath, "Science/attachments/paper.pdf")), content);
      });
    },
  );
});

test("save attachment refuses overwrite unless requested", () => {
  withVault(
    (vaultPath) => {
      writeAttachment(vaultPath, "files/paper.pdf", Buffer.from("old"));
    },
    (vaultPath) => {
      withTempFile(Buffer.from("new"), (sourcePath) => {
        assert.throws(
          () =>
            TOOL_HANDLERS.obsidian_save_attachment({
              vault_path: "files/paper.pdf",
              source_path: sourcePath,
            }),
          /Attachment already exists: files\/paper.pdf/,
        );

        assert.equal(fs.readFileSync(path.join(vaultPath, "files/paper.pdf"), "utf8"), "old");
      });
    },
  );
});

test("save attachment allows overwrite when requested", () => {
  withVault(
    (vaultPath) => {
      writeAttachment(vaultPath, "files/paper.pdf", Buffer.from("old"));
    },
    (vaultPath) => {
      withTempFile(Buffer.from("new"), (sourcePath) => {
        const result = parseToolResult(
          TOOL_HANDLERS.obsidian_save_attachment({
            vault_path: "files/paper.pdf",
            source_path: sourcePath,
            overwrite: true,
          }),
        );

        assert.equal(result.bytes, 3);
        assert.equal(fs.readFileSync(path.join(vaultPath, "files/paper.pdf"), "utf8"), "new");
      });
    },
  );
});

test("save attachment rejects traversal and symlink escapes", () => {
  withVault(
    (vaultPath) => {
      const outsideDir = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-outside-"));
      fs.symlinkSync(outsideDir, path.join(vaultPath, "escape"));
    },
    (vaultPath) => {
      withTempFile(Buffer.from("payload"), (sourcePath) => {
        assert.throws(
          () => TOOL_HANDLERS.obsidian_save_attachment({ vault_path: "../outside.pdf", source_path: sourcePath }),
          /escapes the vault root/,
        );
        assert.throws(
          () => TOOL_HANDLERS.obsidian_save_attachment({ vault_path: "/tmp/outside.pdf", source_path: sourcePath }),
          /must be relative/,
        );
        assert.throws(
          () => TOOL_HANDLERS.obsidian_save_attachment({ vault_path: "escape/outside.pdf", source_path: sourcePath }),
          /escapes the vault root/,
        );

        fs.rmSync(path.join(vaultPath, "escape"), { force: true });
      });
    },
  );
});

test("save attachment rejects oversized and invalid source paths before writing", () => {
  withVault(
    () => {},
    (vaultPath) => {
      const previousMaxBytes = process.env.OBSIDIAN_MCP_ATTACHMENT_MAX_BYTES;
      process.env.OBSIDIAN_MCP_ATTACHMENT_MAX_BYTES = "4";

      try {
        withTempFile(Buffer.from("12345"), (sourcePath) => {
          assert.throws(
            () =>
              TOOL_HANDLERS.obsidian_save_attachment({
                vault_path: "files/large.pdf",
                source_path: sourcePath,
              }),
            /maximum size of 4 bytes/,
          );
        });
        assert.throws(
          () =>
            TOOL_HANDLERS.obsidian_save_attachment({
              vault_path: "files/missing.pdf",
              source_path: "/tmp/does-not-exist.pdf",
            }),
          /Source file does not exist/,
        );
        assert.equal(fs.existsSync(path.join(vaultPath, "files/large.pdf")), false);
        assert.equal(fs.existsSync(path.join(vaultPath, "files/missing.pdf")), false);
      } finally {
        if (previousMaxBytes === undefined) {
          delete process.env.OBSIDIAN_MCP_ATTACHMENT_MAX_BYTES;
        } else {
          process.env.OBSIDIAN_MCP_ATTACHMENT_MAX_BYTES = previousMaxBytes;
        }
      }
    },
  );
});

test("list attachments supports prefix and excludes markdown and dotfolders", () => {
  withVault(
    (vaultPath) => {
      writeAttachment(vaultPath, "Science/attachments/paper.pdf", Buffer.from("pdf"));
      writeAttachment(vaultPath, "Science/attachments/figure.png", Buffer.from("png"));
      writeAttachment(vaultPath, "Media/audio.mp3", Buffer.from("mp3"));
      writeNote(vaultPath, "Science/attachments/paper.md", "# Paper\n");
      writeAttachment(vaultPath, ".trash/old.pdf", Buffer.from("old"));
    },
    () => {
      assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_list_attachments({})).attachments, [
        "Media/audio.mp3",
        "Science/attachments/figure.png",
        "Science/attachments/paper.pdf",
      ]);
      assert.deepEqual(
        parseToolResult(TOOL_HANDLERS.obsidian_list_attachments({ prefix: "Science/attachments/", limit: 2 })).attachments,
        ["Science/attachments/figure.png", "Science/attachments/paper.pdf"],
      );
    },
  );
});

test("delete attachment refuses markdown files", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "note.md", "# Note\n");
    },
    () => {
      assert.throws(
        () => TOOL_HANDLERS.obsidian_delete_attachment({ vault_path: "note.md" }),
        /Refusing to delete markdown note with attachment tool: note.md/,
      );
    },
  );
});

test("delete attachment rejects missing files", () => {
  withVault(
    () => {},
    () => {
      assert.throws(
        () => TOOL_HANDLERS.obsidian_delete_attachment({ vault_path: "files/missing.pdf" }),
        /Attachment does not exist: files\/missing.pdf/,
      );
    },
  );
});

test("delete attachment removes the file and returns byte count", () => {
  withVault(
    (vaultPath) => {
      writeAttachment(vaultPath, "files/paper.pdf", Buffer.from("payload"));
    },
    (vaultPath) => {
      const result = parseToolResult(TOOL_HANDLERS.obsidian_delete_attachment({ vault_path: "files/paper.pdf" }));
      assert.equal(result.bytes, 7);
      assert.equal(result.attachment_path, "files/paper.pdf");
      assert.equal(fs.existsSync(path.join(vaultPath, "files/paper.pdf")), false);
    },
  );
});

test("attachment workflow smoke test saves, embeds, lists, and deletes a PDF", () => {
  withVault(
    () => {},
    () => {
      withTempFile(Buffer.from("%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF\n", "utf8"), (sourcePath) => {
        const pdfBytes = fs.readFileSync(sourcePath);

        const saved = parseToolResult(
          TOOL_HANDLERS.obsidian_save_attachment({
            vault_path: "Science/attachments/paper.pdf",
            source_path: sourcePath,
          }),
        );
        assert.equal(saved.bytes, pdfBytes.length);

        assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_list_attachments({ prefix: "Science/" })).attachments, [
          "Science/attachments/paper.pdf",
        ]);

        TOOL_HANDLERS.obsidian_create_note({
          note_path: "Science/paper.md",
          content: "# Paper\n\n![[attachments/paper.pdf]]\n",
        });

        const note = parseToolResult(TOOL_HANDLERS.obsidian_read_note({ note_path: "Science/paper.md" }));
        assert.match(note.content, /!\[\[attachments\/paper.pdf\]\]/);

        const deleted = parseToolResult(TOOL_HANDLERS.obsidian_delete_attachment({ vault_path: "Science/attachments/paper.pdf" }));
        assert.equal(deleted.bytes, pdfBytes.length);
        assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_list_attachments({ prefix: "Science/" })).attachments, []);
      });
    },
  );
});

test("search tool sees appended content after cache invalidation", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "note.md", "# Note\n");
    },
    () => {
      assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_search_notes({ query: "later text" })).matches, []);

      TOOL_HANDLERS.obsidian_append_note({
        note_path: "note.md",
        content: "later text\n",
      });

      assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_search_notes({ query: "later text" })).matches, [
        { note_path: "note.md", line: 2, text: "later text" },
      ]);
    },
  );
});

test("search tool sees patched heading content after cache invalidation", () => {
  withVault(
    (vaultPath) => {
      writeNote(vaultPath, "note.md", ["# Note", "", "## Related", "- [[One]]", ""].join("\n"));
    },
    () => {
      assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_search_notes({ query: "patched link" })).matches, []);

      TOOL_HANDLERS.obsidian_patch_heading({
        note_path: "note.md",
        heading: "Related",
        operation: "append",
        content: "- [[patched link]]",
      });

      assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_search_notes({ query: "patched link" })).matches, [
        { note_path: "note.md", line: 5, text: "- [[patched link]]" },
      ]);
    },
  );
});

test("list notes cache is invalidated after upsert creates a note", () => {
  withVault(
    () => {},
    () => {
      assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_list_notes({})).notes, []);

      const result = parseToolResult(
        TOOL_HANDLERS.obsidian_upsert_knowledge_note({
          title: "Captured Cache Test",
          summary: "Summary",
          details: "Details",
        }),
      );

      assert.equal(result.note_path, "Captured/Captured Cache Test.md");
      assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_list_notes({})).notes, [
        "Captured/Captured Cache Test.md",
      ]);
    },
  );
});

test("list notes cache refreshes after an external vault change", async () => {
  await withVaultAsync(
    (vaultPath) => {
      writeNote(vaultPath, "one.md", "# One\n");
    },
    async (vaultPath) => {
      const previousTtl = process.env.OBSIDIAN_MCP_CACHE_TTL_MS;
      process.env.OBSIDIAN_MCP_CACHE_TTL_MS = "50";

      try {
        assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_list_notes({})).notes, ["one.md"]);

        writeNote(vaultPath, "two.md", "# Two\n");

        await waitFor(() => {
          assert.deepEqual(parseToolResult(TOOL_HANDLERS.obsidian_list_notes({})).notes, ["one.md", "two.md"]);
        });
      } finally {
        if (previousTtl === undefined) {
          delete process.env.OBSIDIAN_MCP_CACHE_TTL_MS;
        } else {
          process.env.OBSIDIAN_MCP_CACHE_TTL_MS = previousTtl;
        }
      }
    },
  );
});

test("parseSyncedVaultsOutput parses tab and spaced formats", () => {
  assert.deepEqual(parseSyncedVaultsOutput("Work\t/home/me/work\nPersonal  /home/me/personal\nunknown\n"), [
    { name: "Work", path: "/home/me/work", raw: "Work\t/home/me/work" },
    { name: "Personal", path: "/home/me/personal", raw: "Personal  /home/me/personal" },
    { raw: "unknown" },
  ]);
});

test("tool handlers require the Obsidian CLI when no vault name is configured", () => {
  const previousPath = process.env.PATH;

  try {
    process.env.PATH = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-empty-path-"));
    resetVaultCaches();

    assert.throws(
      () => TOOL_HANDLERS.obsidian_list_notes({}),
      /Could not find the Obsidian CLI\. Enable the command-line interface in Obsidian settings so the `obsidian` command is available on PATH\./,
    );
  } finally {
    process.env.PATH = previousPath;
    resetVaultCaches();
  }
});
