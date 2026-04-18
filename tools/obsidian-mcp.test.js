const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { setTimeout: delay } = require("node:timers/promises");

const {
  TOOL_HANDLERS,
  listMarkdownFiles,
  parseSyncedVaultsOutput,
  patchHeadingSection,
  resetVaultCaches,
  resolveNotePath,
  searchMarkdownFiles,
} = require("./obsidian-mcp.js");

function withVault(setup, run) {
  const vaultPath = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-mcp-"));
  const previousVaultPath = process.env.OBSIDIAN_VAULT_PATH;
  process.env.OBSIDIAN_VAULT_PATH = vaultPath;

  try {
    setup(vaultPath);
    return run(vaultPath);
  } finally {
    resetVaultCaches();

    if (previousVaultPath === undefined) {
      delete process.env.OBSIDIAN_VAULT_PATH;
    } else {
      process.env.OBSIDIAN_VAULT_PATH = previousVaultPath;
    }

    fs.rmSync(vaultPath, { recursive: true, force: true });
  }
}

async function withVaultAsync(setup, run) {
  const vaultPath = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-mcp-"));
  const previousVaultPath = process.env.OBSIDIAN_VAULT_PATH;
  process.env.OBSIDIAN_VAULT_PATH = vaultPath;

  try {
    await setup(vaultPath);
    return await run(vaultPath);
  } finally {
    resetVaultCaches();

    if (previousVaultPath === undefined) {
      delete process.env.OBSIDIAN_VAULT_PATH;
    } else {
      process.env.OBSIDIAN_VAULT_PATH = previousVaultPath;
    }

    fs.rmSync(vaultPath, { recursive: true, force: true });
  }
}

function writeNote(vaultPath, relativePath, content) {
  const noteFile = path.join(vaultPath, relativePath);
  fs.mkdirSync(path.dirname(noteFile), { recursive: true });
  fs.writeFileSync(noteFile, content, "utf8");
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
  const vaultPath = "/tmp/vault";

  assert.throws(() => resolveNotePath(vaultPath, "/tmp/file.md"), /must be relative/);
  assert.throws(() => resolveNotePath(vaultPath, "../file.md"), /escapes the vault root/);
  assert.throws(() => resolveNotePath(vaultPath, ".obsidian/file.md"), /Hidden note paths are not allowed/);
  assert.throws(() => resolveNotePath(vaultPath, "note.txt"), /must end with \.md/);
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
