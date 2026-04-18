const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const {
  TOOL_HANDLERS,
  listMarkdownFiles,
  parseSyncedVaultsOutput,
  patchHeadingSection,
  resolveNotePath,
} = require("./obsidian-mcp.js");

function withVault(setup, run) {
  const vaultPath = fs.mkdtempSync(path.join(os.tmpdir(), "obsidian-mcp-"));
  const previousVaultPath = process.env.OBSIDIAN_VAULT_PATH;
  process.env.OBSIDIAN_VAULT_PATH = vaultPath;

  try {
    setup(vaultPath);
    return run(vaultPath);
  } finally {
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

test("parseSyncedVaultsOutput parses tab and spaced formats", () => {
  assert.deepEqual(parseSyncedVaultsOutput("Work\t/home/me/work\nPersonal  /home/me/personal\nunknown\n"), [
    { name: "Work", path: "/home/me/work", raw: "Work\t/home/me/work" },
    { name: "Personal", path: "/home/me/personal", raw: "Personal  /home/me/personal" },
    { raw: "unknown" },
  ]);
});
