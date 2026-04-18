#!/usr/bin/env node

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const debugLogPath = process.env.OBSIDIAN_MCP_DEBUG_LOG;

function debugLog(line) {
  if (!debugLogPath) {
    return;
  }

  fs.appendFileSync(debugLogPath, `${new Date().toISOString()} ${line}\n`, "utf8");
}

debugLog("server started");

const TOOL_DEFINITIONS = [
  {
    name: "obsidian_get_server_info",
    description:
      "Show the current vault path and whether the obsidian-headless CLI is installed.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_list_notes",
    description: "List markdown notes in the configured Obsidian vault.",
    inputSchema: {
      type: "object",
      properties: {
        prefix: {
          type: "string",
          description: "Only include notes whose relative path starts with this prefix.",
        },
        limit: {
          type: "integer",
          minimum: 1,
          maximum: 1000,
          description: "Maximum number of note paths to return.",
        },
      },
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_read_note",
    description: "Read a note from the configured vault.",
    inputSchema: {
      type: "object",
      properties: {
        note_path: {
          type: "string",
          description: "Path to the note relative to the vault root.",
        },
      },
      required: ["note_path"],
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_search_notes",
    description: "Search markdown notes in the configured vault for plain text.",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Plain-text search query.",
        },
        case_sensitive: {
          type: "boolean",
          description: "Whether the search should match case exactly.",
        },
        limit: {
          type: "integer",
          minimum: 1,
          maximum: 200,
          description: "Maximum number of matches to return.",
        },
      },
      required: ["query"],
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_create_note",
    description: "Create a note in the configured vault.",
    inputSchema: {
      type: "object",
      properties: {
        note_path: {
          type: "string",
          description: "Path to the note relative to the vault root.",
        },
        content: {
          type: "string",
          description: "Initial note content.",
        },
        overwrite: {
          type: "boolean",
          description: "Replace the note if it already exists.",
        },
      },
      required: ["note_path", "content"],
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_append_note",
    description: "Append text to an existing note in the configured vault.",
    inputSchema: {
      type: "object",
      properties: {
        note_path: {
          type: "string",
          description: "Path to the note relative to the vault root.",
        },
        content: {
          type: "string",
          description: "Text to append.",
        },
      },
      required: ["note_path", "content"],
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_patch_heading",
    description: "Append, prepend, or replace the content under a markdown heading.",
    inputSchema: {
      type: "object",
      properties: {
        note_path: {
          type: "string",
          description: "Path to the note relative to the vault root.",
        },
        heading: {
          type: "string",
          description: "Heading text to target, without leading # characters.",
        },
        operation: {
          type: "string",
          enum: ["append", "prepend", "replace"],
          description: "How to apply the content inside the heading section.",
        },
        content: {
          type: "string",
          description: "Content to insert into the heading section.",
        },
      },
      required: ["note_path", "heading", "operation", "content"],
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_sync_status",
    description: "Show obsidian-headless sync status for the configured vault.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_sync_now",
    description: "Run a one-shot obsidian-headless sync for the configured vault.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_list_synced_vaults",
    description: "List local vaults configured for obsidian-headless sync.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
  },
  {
    name: "obsidian_upsert_knowledge_note",
    description: "Create or update a structured captured note and maintain related links.",
    inputSchema: {
      type: "object",
      properties: {
        title: {
          type: "string",
          description: "Canonical note title.",
        },
        summary: {
          type: "string",
          description: "Short summary of the finding.",
        },
        details: {
          type: "string",
          description: "Detailed durable notes, decisions, or caveats.",
        },
        related: {
          type: "array",
          items: { type: "string" },
          description: "Related note titles to link from this note.",
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Additional tags to store in frontmatter.",
        },
        aliases: {
          type: "array",
          items: { type: "string" },
          description: "Additional aliases to store in frontmatter.",
        },
        folder: {
          type: "string",
          description: "Captured note folder relative to the vault root. Defaults to Captured.",
        },
        reciprocal_links: {
          type: "boolean",
          description: "Update existing related notes to link back to this note. Defaults to true.",
        },
      },
      required: ["title", "summary", "details"],
      additionalProperties: false,
    },
  },
];

function writeMessage(message) {
  const payload = JSON.stringify(message);
  debugLog(`outgoing: ${payload}`);
  process.stdout.write(`${payload}\n`);
}

function makeError(code, message, data) {
  return {
    code,
    message,
    ...(data === undefined ? {} : { data }),
  };
}

function expandHome(inputPath) {
  if (!inputPath) {
    return inputPath;
  }

  if (inputPath === "~") {
    return os.homedir();
  }

  if (inputPath.startsWith("~/")) {
    return path.join(os.homedir(), inputPath.slice(2));
  }

  return inputPath;
}

function getVaultPath() {
  const rawVaultPath = process.env.OBSIDIAN_VAULT_PATH;

  if (rawVaultPath) {
    return validateVaultPath(rawVaultPath);
  }

  const vaultName = process.env.OBSIDIAN_VAULT_NAME;

  if (vaultName) {
    return resolveVaultPathFromName(vaultName);
  }

  return getActiveVaultPath();
}

function validateVaultPath(rawVaultPath) {
  const resolved = path.resolve(expandHome(rawVaultPath));

  if (!fs.existsSync(resolved)) {
    throw new Error(`Vault path does not exist: ${resolved}`);
  }

  if (!fs.statSync(resolved).isDirectory()) {
    throw new Error(`Vault path is not a directory: ${resolved}`);
  }

  return resolved;
}

function runObsidianCli(args = []) {
  const result = spawnSync("obsidian", args, {
    encoding: "utf8",
  });

  if (result.error && result.error.code === "ENOENT") {
    throw new Error(
      "Obsidian CLI is not installed or not enabled. Enable the command-line interface in Obsidian settings, or set OBSIDIAN_VAULT_PATH.",
    );
  }

  if (result.status !== 0) {
    const stderr = (result.stderr || "").trim();
    const stdout = (result.stdout || "").trim();
    throw new Error(stderr || stdout || `obsidian ${args.join(" ")} failed with exit code ${result.status}`);
  }

  return (result.stdout || "").trim();
}

function resolveVaultPathFromName(vaultName) {
  const resolved = runObsidianCli([`vault=${vaultName}`, "vault", "info=path"]);

  if (!resolved) {
    throw new Error(`Could not resolve vault path for vault name: ${vaultName}`);
  }

  return validateVaultPath(resolved);
}

function getActiveVaultPath() {
  try {
    const activePath = runObsidianCli(["vault", "info=path"]);

    if (activePath) {
      return validateVaultPath(activePath);
    }
  } catch (error) {
    debugLog(`active vault lookup failed: ${error.message}`);
  }

  throw new Error(
    "No vault configured. Set OBSIDIAN_VAULT_PATH or open a vault in Obsidian.",
  );
}

function resolveNotePath(vaultPath, notePath) {
  if (!notePath) {
    throw new Error("note_path is required.");
  }

  if (path.isAbsolute(notePath)) {
    throw new Error("note_path must be relative to the vault root.");
  }

  if (!notePath.endsWith(".md")) {
    throw new Error("note_path must end with .md");
  }

  const resolved = path.resolve(vaultPath, notePath);
  const relative = path.relative(vaultPath, resolved);

  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw new Error(`Path escapes the vault root: ${notePath}`);
  }

  const parts = notePath.split(/[\\/]+/).filter(Boolean);
  if (parts.some((part) => part !== "." && part !== ".." && part.startsWith("."))) {
    throw new Error(`Hidden note paths are not allowed: ${notePath}`);
  }

  return resolved;
}

function listMarkdownFiles(rootPath) {
  const results = [];
  const stack = [rootPath];

  while (stack.length > 0) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name.startsWith(".") || entry.name === "node_modules") {
        continue;
      }

      const fullPath = path.join(current, entry.name);

      if (entry.isDirectory()) {
        stack.push(fullPath);
        continue;
      }

      if (entry.isFile() && entry.name.endsWith(".md")) {
        results.push(fullPath);
      }
    }
  }

  results.sort((left, right) => left.localeCompare(right));
  return results;
}

function textResult(value) {
  const text = typeof value === "string" ? value : JSON.stringify(value, null, 2);
  return { content: [{ type: "text", text }] };
}

function getHeadingRange(document, heading) {
  const lines = document.split("\n");
  const normalizedHeading = heading.trim();
  let startLine = -1;
  let startLevel = -1;

  for (let index = 0; index < lines.length; index += 1) {
    const match = /^(#{1,6})\s+(.*)$/.exec(lines[index]);
    if (!match) {
      continue;
    }

    if (match[2].trim() === normalizedHeading) {
      startLine = index;
      startLevel = match[1].length;
      break;
    }
  }

  if (startLine === -1) {
    throw new Error(`Heading not found: ${heading}`);
  }

  let endLine = lines.length;

  for (let index = startLine + 1; index < lines.length; index += 1) {
    const match = /^(#{1,6})\s+/.exec(lines[index]);
    if (match && match[1].length <= startLevel) {
      endLine = index;
      break;
    }
  }

  return { lines, startLine, endLine };
}

function normalizeSectionContent(content) {
  if (content.length === 0) {
    return "";
  }

  return content.endsWith("\n") ? content : `${content}\n`;
}

function patchHeadingSection(document, heading, operation, content) {
  const { lines, startLine, endLine } = getHeadingRange(document, heading);
  const sectionStart = startLine + 1;
  const existing = lines.slice(sectionStart, endLine).join("\n");
  const normalizedContent = normalizeSectionContent(content);

  let nextSection = normalizedContent;

  if (operation === "append") {
    const base = existing.length === 0 ? "" : normalizeSectionContent(existing);
    nextSection = `${base}${normalizedContent}`;
  } else if (operation === "prepend") {
    const base = existing.length === 0 ? "" : normalizeSectionContent(existing);
    nextSection = `${normalizedContent}${base}`;
  } else if (operation !== "replace") {
    throw new Error(`Unsupported operation: ${operation}`);
  }

  const replacementLines = nextSection.length === 0 ? [] : nextSection.replace(/\n$/, "").split("\n");
  const updatedLines = [
    ...lines.slice(0, sectionStart),
    ...replacementLines,
    ...lines.slice(endLine),
  ];

  return `${updatedLines.join("\n")}${document.endsWith("\n") ? "\n" : ""}`;
}

function slugifyNoteTitle(title) {
  const trimmed = String(title || "").trim();
  if (!trimmed) {
    throw new Error("title is required.");
  }

  const sanitized = trimmed
    .replace(/[<>:"/\\|?*]+/g, " ")
    .replace(/\s+/g, " ")
    .replace(/^\.+|\.+$/g, "")
    .trim();

  if (!sanitized) {
    throw new Error(`Title cannot be converted into a note path: ${title}`);
  }

  return sanitized;
}

function normalizeKnowledgeFolder(folder) {
  const candidate = String(folder || "Captured").trim().replace(/^\/+|\/+$/g, "");

  if (!candidate) {
    throw new Error("folder must not be empty.");
  }

  return candidate;
}

function uniqueStrings(values) {
  const seen = new Set();
  const result = [];

  for (const value of values || []) {
    const normalized = String(value || "").trim();
    if (!normalized) {
      continue;
    }

    const key = normalized.toLowerCase();
    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    result.push(normalized);
  }

  return result;
}

function yamlQuote(value) {
  return JSON.stringify(String(value));
}

function formatYamlList(key, values) {
  const items = uniqueStrings(values);
  return `${key}:\n${items.map((item) => `  - ${yamlQuote(item)}`).join("\n")}`;
}

function getLocalDateString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function extractWikiLinks(document) {
  const matches = document.match(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/g) || [];
  return uniqueStrings(
    matches.map((match) => match.replace(/^\[\[/, "").replace(/\]\]$/, "").split("|")[0].trim()),
  );
}

function extractSectionWikiLinks(document, heading) {
  try {
    const { lines, startLine, endLine } = getHeadingRange(document, heading);
    return extractWikiLinks(lines.slice(startLine + 1, endLine).join("\n"));
  } catch (error) {
    if (error.message === `Heading not found: ${heading}`) {
      return [];
    }

    throw error;
  }
}

function notePathToLinkTarget(notePath) {
  return notePath.replace(/\.md$/, "");
}

function formatWikiLinks(paths) {
  return uniqueStrings(paths).map((notePath) => `[[${notePathToLinkTarget(notePath)}]]`);
}

function findKnowledgeNoteByTitle(vaultPath, title, folder, markdownFiles = listMarkdownFiles(vaultPath)) {
  const normalizedTitle = String(title || "").trim().toLowerCase();
  const folderPrefix = `${normalizeKnowledgeFolder(folder)}/`;

  if (!normalizedTitle) {
    throw new Error("title is required.");
  }

  for (const filePath of markdownFiles) {
    const relativePath = path.relative(vaultPath, filePath);
    if (!relativePath.startsWith(folderPrefix)) {
      continue;
    }

    const baseName = path.basename(relativePath, ".md").trim().toLowerCase();
    if (baseName === normalizedTitle) {
      return relativePath;
    }
  }

  return null;
}

function findVaultNotesByTitle(vaultPath, title, markdownFiles = listMarkdownFiles(vaultPath)) {
  const normalizedTitle = String(title || "").trim().toLowerCase();

  if (!normalizedTitle) {
    throw new Error("title is required.");
  }

  return markdownFiles
    .map((filePath) => path.relative(vaultPath, filePath))
    .filter((relativePath) => path.basename(relativePath, ".md").trim().toLowerCase() === normalizedTitle);
}

function resolveExistingNotePathByTitle(vaultPath, title, markdownFiles = listMarkdownFiles(vaultPath)) {
  const matches = findVaultNotesByTitle(vaultPath, title, markdownFiles);

  if (matches.length === 0) {
    throw new Error(`Related note not found: ${title}`);
  }

  if (matches.length > 1) {
    throw new Error(`Related note title is ambiguous: ${title} (${matches.join(", ")})`);
  }

  return matches[0];
}

function getKnowledgeNotePath(vaultPath, title, folder, markdownFiles = listMarkdownFiles(vaultPath)) {
  const existingPath = findKnowledgeNoteByTitle(vaultPath, title, folder, markdownFiles);
  if (existingPath) {
    return existingPath;
  }

  return `${normalizeKnowledgeFolder(folder)}/${slugifyNoteTitle(title)}.md`;
}

function extractDocumentTitle(document) {
  const frontmatterMatch = /^---\n([\s\S]*?)\n---\n?/m.exec(document);
  if (frontmatterMatch) {
    const titleMatch = /^title:\s*(?:"([^"]+)"|'([^']+)'|(.+))$/m.exec(frontmatterMatch[1]);
    const title = (titleMatch?.[1] || titleMatch?.[2] || titleMatch?.[3] || "").trim();
    if (title) {
      return title;
    }
  }

  const headingMatch = /^#\s+(.+)$/m.exec(document);
  if (headingMatch) {
    return headingMatch[1].trim();
  }

  return null;
}

function assertKnowledgeNotePathDoesNotCollide(vaultPath, notePath, title) {
  const noteFile = resolveNotePath(vaultPath, notePath);
  if (!fs.existsSync(noteFile)) {
    return;
  }

  const requestedTitle = String(title || "").trim();
  const existingTitle = extractDocumentTitle(fs.readFileSync(noteFile, "utf8"))
    || path.basename(notePath, ".md");

  if (existingTitle.toLowerCase() === requestedTitle.toLowerCase()) {
    return;
  }

  throw new Error(
    `Knowledge note path collision: ${notePath} already belongs to \"${existingTitle}\". Choose a different title or rename the existing note.`,
  );
}

function ensureRelatedSection(document) {
  if (/^## Related\s*$/m.test(document)) {
    return document;
  }

  const trimmed = document.replace(/\s*$/, "");
  return `${trimmed}\n\n## Related\n`;
}

function ensureRelatedLinks(document, links) {
  const uniqueLinks = uniqueStrings(links);
  if (uniqueLinks.length === 0) {
    return ensureRelatedSection(document).replace(/\s*$/, "\n");
  }

  const withSection = ensureRelatedSection(document);
  let relatedContent = "";

  try {
    const { lines, startLine, endLine } = getHeadingRange(withSection, "Related");
    relatedContent = lines.slice(startLine + 1, endLine).join("\n");
  } catch (error) {
    throw new Error(`Failed to update Related section: ${error.message}`);
  }

  const existingLinks = new Set(extractWikiLinks(relatedContent).map((value) => value.toLowerCase()));
  const nextLines = relatedContent
    .split("\n")
    .map((line) => line.trimEnd())
    .filter((line) => line.trim().length > 0);

  for (const link of uniqueLinks) {
    const target = link.replace(/^\[\[/, "").replace(/\]\]$/, "").toLowerCase();
    if (existingLinks.has(target)) {
      continue;
    }

    nextLines.push(`- ${link}`);
    existingLinks.add(target);
  }

  return patchHeadingSection(withSection, "Related", "replace", nextLines.join("\n"));
}

function formatKnowledgeNote({ title, summary, details, tags, aliases, relatedLinks }) {
  const lines = [
    "---",
    "type: captured-note",
    "agent_owned: true",
    `title: ${yamlQuote(title)}`,
    formatYamlList("aliases", aliases),
    formatYamlList("tags", ["captured", ...(tags || [])]),
    "created_by: agent",
    `updated: ${getLocalDateString()}`,
    "---",
    "",
    `# ${title}`,
    "",
    "## Summary",
    normalizeSectionContent(summary).replace(/\n$/, ""),
    "",
    "## Details",
    normalizeSectionContent(details).replace(/\n$/, ""),
    "",
    "## Related",
  ];

  for (const link of uniqueStrings(relatedLinks)) {
    lines.push(`- ${link}`);
  }

  return `${lines.join("\n")}\n`;
}

function runObsidianHeadless(subcommand, args = []) {
  const result = spawnSync("ob", [subcommand, ...args], {
    encoding: "utf8",
  });

  if (result.error && result.error.code === "ENOENT") {
    throw new Error(
      "obsidian-headless is not installed. Install it with `npm install -g obsidian-headless` and log in with `ob login`.",
    );
  }

  if (result.status !== 0) {
    const stderr = (result.stderr || "").trim();
    const stdout = (result.stdout || "").trim();
    throw new Error(stderr || stdout || `ob ${subcommand} failed with exit code ${result.status}`);
  }

  return (result.stdout || "").trim();
}

function parseSyncedVaultsOutput(output) {
  return String(output || "")
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .map((line) => {
      const tabParts = line.split("\t").map((part) => part.trim()).filter(Boolean);
      if (tabParts.length >= 2) {
        return {
          name: tabParts[0],
          path: tabParts.slice(1).join("\t"),
          raw: line,
        };
      }

      const spacedParts = line.split(/\s{2,}/).map((part) => part.trim()).filter(Boolean);
      if (spacedParts.length >= 2) {
        return {
          name: spacedParts[0],
          path: spacedParts.slice(1).join(" "),
          raw: line,
        };
      }

      return { raw: line };
    });
}

const TOOL_HANDLERS = {
  obsidian_get_server_info() {
    const configuredVaultPath = process.env.OBSIDIAN_VAULT_PATH
      ? path.resolve(expandHome(process.env.OBSIDIAN_VAULT_PATH))
      : null;
    let activeVaultPath = null;

    try {
      activeVaultPath = runObsidianCli(["vault", "info=path"]);
    } catch (error) {
      debugLog(`server info active vault lookup failed: ${error.message}`);
    }

    const obInstalled = spawnSync("ob", ["--help"], { encoding: "utf8" }).status === 0;

    return textResult({
      configured_vault_path: configuredVaultPath,
      active_vault_path: activeVaultPath,
      obsidian_headless_installed: obInstalled,
      note: "This MCP only operates on the configured or active Obsidian vault.",
    });
  },

  obsidian_list_notes(args) {
    const vaultPath = getVaultPath();
    const prefix = args.prefix || "";
    const limit = args.limit || 200;
    const notes = listMarkdownFiles(vaultPath)
      .map((filePath) => path.relative(vaultPath, filePath))
      .filter((relativePath) => relativePath.startsWith(prefix))
      .slice(0, limit);

    return textResult({ vault_path: vaultPath, notes, returned: notes.length });
  },

  obsidian_read_note(args) {
    const vaultPath = getVaultPath();
    const noteFile = resolveNotePath(vaultPath, args.note_path);

    if (!fs.existsSync(noteFile)) {
      throw new Error(`Note does not exist: ${args.note_path}`);
    }

    return textResult({
      vault_path: vaultPath,
      note_path: args.note_path,
      content: fs.readFileSync(noteFile, "utf8"),
    });
  },

  obsidian_search_notes(args) {
    const vaultPath = getVaultPath();
    const query = args.query;
    const limit = args.limit || 50;
    const matches = [];
    const searchQuery = args.case_sensitive ? query : query.toLowerCase();

    for (const filePath of listMarkdownFiles(vaultPath)) {
      const relativePath = path.relative(vaultPath, filePath);
      const content = fs.readFileSync(filePath, "utf8");
      const lines = content.split("\n");

      for (let index = 0; index < lines.length; index += 1) {
        const haystack = args.case_sensitive ? lines[index] : lines[index].toLowerCase();
        if (!haystack.includes(searchQuery)) {
          continue;
        }

        matches.push({
          note_path: relativePath,
          line: index + 1,
          text: lines[index],
        });

        if (matches.length >= limit) {
          return textResult({ vault_path: vaultPath, query, matches, returned: matches.length });
        }
      }
    }

    return textResult({ vault_path: vaultPath, query, matches, returned: matches.length });
  },

  obsidian_create_note(args) {
    const vaultPath = getVaultPath();
    const noteFile = resolveNotePath(vaultPath, args.note_path);

    if (fs.existsSync(noteFile) && !args.overwrite) {
      throw new Error(`Note already exists: ${args.note_path}`);
    }

    fs.mkdirSync(path.dirname(noteFile), { recursive: true });
    fs.writeFileSync(noteFile, args.content, "utf8");

    return textResult({ vault_path: vaultPath, note_path: args.note_path, updated: true });
  },

  obsidian_append_note(args) {
    const vaultPath = getVaultPath();
    const noteFile = resolveNotePath(vaultPath, args.note_path);

    if (!fs.existsSync(noteFile)) {
      throw new Error(`Note does not exist: ${args.note_path}`);
    }

    fs.appendFileSync(noteFile, args.content, "utf8");

    return textResult({ vault_path: vaultPath, note_path: args.note_path, updated: true });
  },

  obsidian_patch_heading(args) {
    const vaultPath = getVaultPath();
    const noteFile = resolveNotePath(vaultPath, args.note_path);

    if (!fs.existsSync(noteFile)) {
      throw new Error(`Note does not exist: ${args.note_path}`);
    }

    const document = fs.readFileSync(noteFile, "utf8");
    const updated = patchHeadingSection(document, args.heading, args.operation, args.content);
    fs.writeFileSync(noteFile, updated, "utf8");

    return textResult({
      vault_path: vaultPath,
      note_path: args.note_path,
      heading: args.heading,
      operation: args.operation,
      updated: true,
    });
  },

  obsidian_sync_status() {
    const vaultPath = getVaultPath();
    return textResult({
      vault_path: vaultPath,
      output: runObsidianHeadless("sync-status", ["--path", vaultPath]),
    });
  },

  obsidian_sync_now() {
    const vaultPath = getVaultPath();
    return textResult({
      vault_path: vaultPath,
      output: runObsidianHeadless("sync", ["--path", vaultPath]),
    });
  },

  obsidian_list_synced_vaults() {
    const output = runObsidianHeadless("sync-list-local");
    return textResult({
      output,
      vaults: parseSyncedVaultsOutput(output),
    });
  },

  obsidian_upsert_knowledge_note(args) {
    const vaultPath = getVaultPath();
    const folder = normalizeKnowledgeFolder(args.folder);
    const markdownFiles = listMarkdownFiles(vaultPath);
    const notePath = getKnowledgeNotePath(vaultPath, args.title, folder, markdownFiles);
    const noteFile = resolveNotePath(vaultPath, notePath);
    assertKnowledgeNotePathDoesNotCollide(vaultPath, notePath, args.title);
    const created = !fs.existsSync(noteFile);
    const relatedPaths = uniqueStrings(args.related || []).map((title) => resolveExistingNotePathByTitle(vaultPath, title, markdownFiles));
    const relatedLinks = formatWikiLinks(relatedPaths);
    const existingLinks = created
      ? []
      : formatWikiLinks(extractSectionWikiLinks(fs.readFileSync(noteFile, "utf8"), "Related"));
    const mergedLinks = uniqueStrings([...existingLinks, ...relatedLinks]);
    const content = formatKnowledgeNote({
      title: args.title.trim(),
      summary: args.summary,
      details: args.details,
      tags: args.tags || [],
      aliases: args.aliases || [],
      relatedLinks: mergedLinks,
    });

    fs.mkdirSync(path.dirname(noteFile), { recursive: true });
    fs.writeFileSync(noteFile, content, "utf8");

    const updatedRelatedNotes = [];
    if (args.reciprocal_links !== false) {
      const backlink = `[[${notePathToLinkTarget(notePath)}]]`;

      for (const relatedPath of relatedPaths) {
        const relatedFile = resolveNotePath(vaultPath, relatedPath);
        if (!fs.existsSync(relatedFile)) {
          continue;
        }

        const relatedContent = fs.readFileSync(relatedFile, "utf8");
        const nextContent = ensureRelatedLinks(relatedContent, [backlink]);
        if (nextContent !== relatedContent) {
          fs.writeFileSync(relatedFile, nextContent, "utf8");
          updatedRelatedNotes.push(relatedPath);
        }
      }
    }

    return textResult({
      vault_path: vaultPath,
      note_path: notePath,
      created,
      related_links: mergedLinks,
      updated_related_notes: updatedRelatedNotes,
    });
  },
};

function handleRequest(message) {
  debugLog(`incoming: ${JSON.stringify(message)}`);

  if (message.method === "notifications/initialized") {
    return;
  }

  if (message.id === undefined) {
    return;
  }

  if (message.method === "initialize") {
    writeMessage({
      jsonrpc: "2.0",
      id: message.id,
      result: {
        protocolVersion: message.params?.protocolVersion || "2024-11-05",
        capabilities: {
          tools: {
            listChanged: false,
          },
        },
        serverInfo: {
          name: "obsidian-local",
          version: "0.1.0",
        },
      },
    });
    return;
  }

  if (message.method === "ping") {
    writeMessage({
      jsonrpc: "2.0",
      id: message.id,
      result: {},
    });
    return;
  }

  if (message.method === "tools/list") {
    writeMessage({
      jsonrpc: "2.0",
      id: message.id,
      result: {
        tools: TOOL_DEFINITIONS,
      },
    });
    return;
  }

  if (message.method === "resources/list") {
    writeMessage({
      jsonrpc: "2.0",
      id: message.id,
      result: {
        resources: [],
      },
    });
    return;
  }

  if (message.method === "prompts/list") {
    writeMessage({
      jsonrpc: "2.0",
      id: message.id,
      result: {
        prompts: [],
      },
    });
    return;
  }

  if (message.method === "tools/call") {
    const toolName = message.params?.name;
    const args = message.params?.arguments || {};
    const handler = TOOL_HANDLERS[toolName];

    if (!handler) {
      writeMessage({
        jsonrpc: "2.0",
        id: message.id,
        result: {
          content: [{ type: "text", text: `Unknown tool: ${toolName}` }],
          isError: true,
        },
      });
      return;
    }

    try {
      writeMessage({
        jsonrpc: "2.0",
        id: message.id,
        result: handler(args),
      });
    } catch (error) {
      writeMessage({
        jsonrpc: "2.0",
        id: message.id,
        result: {
          content: [{ type: "text", text: error.message }],
          isError: true,
        },
      });
    }
    return;
  }

  writeMessage({
    jsonrpc: "2.0",
    id: message.id,
    error: makeError(-32601, `Method not found: ${message.method}`),
  });
}

function startServer() {
  let buffer = Buffer.alloc(0);
  const keepAlive = setInterval(() => {}, 60_000);

  process.stdin.resume();
  process.stdin.on("end", () => {
    debugLog("stdin closed");
    clearInterval(keepAlive);
  });
  process.on("SIGTERM", () => {
    clearInterval(keepAlive);
    process.exit(0);
  });

  process.stdin.on("data", (chunk) => {
    debugLog(`raw chunk: ${JSON.stringify(chunk.toString("utf8"))}`);
    buffer = Buffer.concat([buffer, chunk]);

    while (true) {
      const newlineIndex = buffer.indexOf("\n");
      if (newlineIndex === -1) {
        return;
      }

      const payload = buffer.slice(0, newlineIndex).toString("utf8").trim();
      buffer = buffer.slice(newlineIndex + 1);

      if (payload.length === 0) {
        continue;
      }

      try {
        handleRequest(JSON.parse(payload));
      } catch (error) {
        writeMessage({
          jsonrpc: "2.0",
          error: makeError(-32700, `Invalid JSON payload: ${error.message}`),
        });
      }
    }
  });
}

module.exports = {
  TOOL_HANDLERS,
  extractSectionWikiLinks,
  findVaultNotesByTitle,
  getHeadingRange,
  getKnowledgeNotePath,
  listMarkdownFiles,
  parseSyncedVaultsOutput,
  patchHeadingSection,
  resolveNotePath,
  resolveExistingNotePathByTitle,
  startServer,
};

if (require.main === module) {
  startServer();
}
