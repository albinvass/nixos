#!/usr/bin/env node

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const debugLogPath = process.env.OBSIDIAN_MCP_DEBUG_LOG;
const DEFAULT_CACHE_TTL_MS = 2_000;
const DEFAULT_ATTACHMENT_MAX_BYTES = 25 * 1024 * 1024;
let cachedVaultConfigKey = null;
let cachedVaultPath = null;
const vaultIndexCache = new Map();

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
    name: "obsidian_list_attachments",
    description: "List non-markdown files in the configured Obsidian vault, excluding hidden dotfolders such as .obsidian and .trash.",
    inputSchema: {
      type: "object",
      properties: {
        prefix: {
          type: "string",
          description: "Only include attachment paths whose relative path starts with this prefix.",
        },
        limit: {
          type: "integer",
          minimum: 1,
          maximum: 1000,
          description: "Maximum number of attachment paths to return.",
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
    name: "obsidian_save_attachment",
    description: "Copy an attachment from a local file path into the configured Obsidian vault with parent directory creation and overwrite protection.",
    inputSchema: {
      type: "object",
      properties: {
        vault_path: {
          type: "string",
          description: "Path to the attachment relative to the vault root.",
        },
        source_path: {
          type: "string",
          description: "Local file path to copy into the vault.",
        },
        overwrite: {
          type: "boolean",
          description: "Replace the attachment if it already exists.",
        },
      },
      required: ["vault_path", "source_path"],
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
    name: "obsidian_delete_attachment",
    description: "Delete a non-markdown attachment from the configured Obsidian vault and report the removed file size.",
    inputSchema: {
      type: "object",
      properties: {
        vault_path: {
          type: "string",
          description: "Path to the attachment relative to the vault root.",
        },
      },
      required: ["vault_path"],
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
  const configKey = JSON.stringify({
    vaultName: process.env.OBSIDIAN_VAULT_NAME || null,
  });

  if (cachedVaultConfigKey === configKey && cachedVaultPath) {
    return cachedVaultPath;
  }

  const vaultName = process.env.OBSIDIAN_VAULT_NAME;
  let resolvedVaultPath;

  if (vaultName) {
    resolvedVaultPath = resolveVaultPathFromName(vaultName);
  } else {
    resolvedVaultPath = getActiveVaultPath();
  }

  cachedVaultConfigKey = configKey;
  cachedVaultPath = resolvedVaultPath;
  return resolvedVaultPath;
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
      "Could not find the Obsidian CLI. Enable the command-line interface in Obsidian settings so the `obsidian` command is available on PATH.",
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
  const activePath = runObsidianCli(["vault", "info=path"]);

  if (activePath) {
    return validateVaultPath(activePath);
  }

  throw new Error(
    "Could not determine the active Obsidian vault. Open a vault in Obsidian and make sure the command-line interface is enabled in settings.",
  );
}

function ensurePathInsideVault(vaultPath, candidatePath, rawPath) {
  const relative = path.relative(vaultPath, candidatePath);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw new Error(`Path escapes the vault root: ${rawPath}`);
  }
}

function resolveVaultPath(vaultPath, targetPath) {
  if (typeof targetPath !== "string" || targetPath.length === 0) {
    throw new Error("vault_path is required.");
  }

  if (targetPath.includes("\0")) {
    throw new Error("vault_path must not contain null bytes.");
  }

  if (path.isAbsolute(targetPath)) {
    throw new Error("vault_path must be relative to the vault root.");
  }

  const resolvedVaultPath = fs.realpathSync.native(vaultPath);
  const normalizedTargetPath = path.normalize(targetPath);
  const resolvedPath = path.resolve(resolvedVaultPath, normalizedTargetPath);
  ensurePathInsideVault(resolvedVaultPath, resolvedPath, targetPath);

  const parts = path.relative(resolvedVaultPath, resolvedPath).split(path.sep).filter(Boolean);
  let currentPath = resolvedVaultPath;

  for (let index = 0; index < parts.length; index += 1) {
    const nextPath = path.join(currentPath, parts[index]);
    const exists = fs.existsSync(nextPath);

    if (!exists) {
      currentPath = nextPath;
      continue;
    }

    const stats = fs.lstatSync(nextPath);
    const realPath = stats.isSymbolicLink() ? fs.realpathSync.native(nextPath) : nextPath;
    ensurePathInsideVault(resolvedVaultPath, realPath, targetPath);

    if (index < parts.length - 1 && !fs.statSync(realPath).isDirectory()) {
      throw new Error(`Parent path is not a directory: ${targetPath}`);
    }

    currentPath = realPath;
  }

  return currentPath;
}

function resolveNotePath(vaultPath, notePath) {
  if (typeof notePath !== "string" || notePath.length === 0) {
    throw new Error("note_path is required.");
  }

  if (notePath.includes("\0")) {
    throw new Error("note_path must not contain null bytes.");
  }

  if (!notePath.endsWith(".md")) {
    throw new Error("note_path must end with .md");
  }

  if (path.isAbsolute(notePath)) {
    throw new Error("note_path must be relative to the vault root.");
  }

  const parts = notePath.split(/[\\/]+/).filter(Boolean);
  if (parts.some((part) => part !== "." && part !== ".." && part.startsWith("."))) {
    throw new Error(`Hidden note paths are not allowed: ${notePath}`);
  }

  try {
    return resolveVaultPath(vaultPath, notePath);
  } catch (error) {
    if (error.message === "vault_path is required.") {
      throw new Error("note_path is required.");
    }
    if (error.message === "vault_path must not contain null bytes.") {
      throw new Error("note_path must not contain null bytes.");
    }
    if (error.message === "vault_path must be relative to the vault root.") {
      throw new Error("note_path must be relative to the vault root.");
    }
    throw error;
  }
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

function listAttachmentFiles(rootPath) {
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

      if (entry.isFile() && !entry.name.endsWith(".md")) {
        results.push(fullPath);
      }
    }
  }

  results.sort((left, right) => left.localeCompare(right));
  return results;
}

function getAttachmentMaxBytes() {
  const parsed = Number.parseInt(process.env.OBSIDIAN_MCP_ATTACHMENT_MAX_BYTES || "", 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : DEFAULT_ATTACHMENT_MAX_BYTES;
}

function resolveSourceAttachmentPath(sourcePath, maxBytes = getAttachmentMaxBytes()) {
  if (typeof sourcePath !== "string" || sourcePath.length === 0) {
    throw new Error("source_path is required.");
  }

  if (sourcePath.includes("\0")) {
    throw new Error("source_path must not contain null bytes.");
  }

  const resolvedSourcePath = path.resolve(expandHome(sourcePath));
  if (!fs.existsSync(resolvedSourcePath)) {
    throw new Error(`Source file does not exist: ${sourcePath}`);
  }

  const stats = fs.statSync(resolvedSourcePath);
  if (!stats.isFile()) {
    throw new Error(`Source path is not a file: ${sourcePath}`);
  }

  if (stats.size > maxBytes) {
    throw new Error(`Attachment exceeds maximum size of ${maxBytes} bytes.`);
  }

  return { resolvedSourcePath, bytes: stats.size };
}

function writeFileAtomic(targetPath, content) {
  const directory = path.dirname(targetPath);
  const tempPath = path.join(
    directory,
    `.tmp-obsidian-mcp-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  );

  try {
    fs.writeFileSync(tempPath, content);
    fs.renameSync(tempPath, targetPath);
  } catch (error) {
    if (fs.existsSync(tempPath)) {
      fs.rmSync(tempPath, { force: true });
    }
    throw error;
  }
}

function copyFileAtomic(sourcePath, targetPath) {
  const directory = path.dirname(targetPath);
  const tempPath = path.join(
    directory,
    `.tmp-obsidian-mcp-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  );

  try {
    fs.copyFileSync(sourcePath, tempPath);
    fs.renameSync(tempPath, targetPath);
  } catch (error) {
    if (fs.existsSync(tempPath)) {
      fs.rmSync(tempPath, { force: true });
    }
    throw error;
  }
}

function getCacheTtlMs() {
  const parsed = Number.parseInt(process.env.OBSIDIAN_MCP_CACHE_TTL_MS || "", 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : DEFAULT_CACHE_TTL_MS;
}

function closeVaultWatchers(entry) {
  for (const watcher of entry?.watchers || []) {
    watcher.close();
  }
}

function getWatchedDirectories(vaultPath, markdownFiles) {
  const directories = new Set([vaultPath]);

  for (const filePath of markdownFiles) {
    let current = path.dirname(filePath);
    while (current.startsWith(vaultPath)) {
      directories.add(current);
      if (current === vaultPath) {
        break;
      }
      current = path.dirname(current);
    }
  }

  return [...directories].sort((left, right) => left.localeCompare(right));
}

function markVaultIndexStale(vaultPath) {
  const entry = vaultIndexCache.get(vaultPath);
  if (entry) {
    entry.stale = true;
  }
}

function createVaultWatchers(vaultPath, markdownFiles) {
  const watchers = [];

  for (const directory of getWatchedDirectories(vaultPath, markdownFiles)) {
    try {
      const watcher = fs.watch(directory, () => {
        markVaultIndexStale(vaultPath);
      });
      watcher.on("error", () => {
        markVaultIndexStale(vaultPath);
      });
      watchers.push(watcher);
    } catch (error) {
      debugLog(`watch setup failed for ${directory}: ${error.message}`);
      markVaultIndexStale(vaultPath);
    }
  }

  return watchers;
}

function buildVaultIndex(vaultPath) {
  const markdownFiles = listMarkdownFiles(vaultPath);
  const titleToPaths = new Map();

  for (const filePath of markdownFiles) {
    const relativePath = path.relative(vaultPath, filePath);
    const title = path.basename(relativePath, ".md").trim().toLowerCase();

    if (!titleToPaths.has(title)) {
      titleToPaths.set(title, []);
    }

    titleToPaths.get(title).push(relativePath);
  }

  return {
    markdownFiles,
    titleToPaths,
    builtAt: Date.now(),
    stale: false,
    watchers: createVaultWatchers(vaultPath, markdownFiles),
  };
}

function getVaultIndex(vaultPath) {
  const cachedEntry = vaultIndexCache.get(vaultPath);
  if (cachedEntry) {
    const expired = Date.now() - cachedEntry.builtAt > getCacheTtlMs();
    if (!cachedEntry.stale && !expired) {
      return cachedEntry;
    }

    closeVaultWatchers(cachedEntry);
  }

  if (!vaultIndexCache.has(vaultPath) || cachedEntry) {
    vaultIndexCache.set(vaultPath, buildVaultIndex(vaultPath));
  }

  return vaultIndexCache.get(vaultPath);
}

function invalidateVaultIndex(vaultPath) {
  const entry = vaultIndexCache.get(vaultPath);
  closeVaultWatchers(entry);
  vaultIndexCache.delete(vaultPath);
}

function resetVaultCaches() {
  cachedVaultConfigKey = null;
  cachedVaultPath = null;

  for (const entry of vaultIndexCache.values()) {
    closeVaultWatchers(entry);
  }

  vaultIndexCache.clear();
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

function findVaultNotesByTitle(vaultPath, title, markdownFiles) {
  const normalizedTitle = String(title || "").trim().toLowerCase();

  if (!normalizedTitle) {
    throw new Error("title is required.");
  }

  if (markdownFiles === undefined) {
    return [...(getVaultIndex(vaultPath).titleToPaths.get(normalizedTitle) || [])];
  }

  return markdownFiles
    .map((filePath) => path.relative(vaultPath, filePath))
    .filter((relativePath) => path.basename(relativePath, ".md").trim().toLowerCase() === normalizedTitle);
}

function searchMarkdownFiles(vaultPath, query, caseSensitive, limit) {
  const args = [
    "-n",
    "-H",
    "-F",
    "--color",
    "never",
    "--glob",
    "*.md",
    "--glob",
    "!node_modules/**",
  ];

  if (!caseSensitive) {
    args.push("-i");
  }

  args.push(query, ".");

  const result = spawnSync("rg", args, {
    cwd: vaultPath,
    encoding: "utf8",
  });

  if (result.error && result.error.code === "ENOENT") {
    throw new Error("ripgrep (`rg`) is required for obsidian_search_notes.");
  }

  if (![0, 1].includes(result.status)) {
    const stderr = (result.stderr || "").trim();
    const stdout = (result.stdout || "").trim();
    throw new Error(stderr || stdout || `rg search failed with exit code ${result.status}`);
  }

  return String(result.stdout || "")
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const match = /^(.*?):(\d+):(.*)$/.exec(line);
      if (!match) {
        return null;
      }

      const notePath = match[1].replace(/^\.\//, "");
      const pathParts = notePath.split(/[\\/]+/).filter(Boolean);
      if (pathParts.some((part) => part.startsWith("."))) {
        return null;
      }

      return {
        note_path: notePath,
        line: Number(match[2]),
        text: match[3],
      };
    })
    .filter(Boolean)
    .sort((left, right) => {
      const pathComparison = left.note_path.localeCompare(right.note_path);
      if (pathComparison !== 0) {
        return pathComparison;
      }

      return left.line - right.line;
    })
    .slice(0, limit);
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
    let activeVaultPath = null;
    const obsidianCliInstalled = spawnSync("obsidian", ["--help"], { encoding: "utf8" }).status === 0;

    try {
      activeVaultPath = runObsidianCli(["vault", "info=path"]);
    } catch (error) {
      debugLog(`server info active vault lookup failed: ${error.message}`);
    }

    const obInstalled = spawnSync("ob", ["--help"], { encoding: "utf8" }).status === 0;

    return textResult({
      active_vault_path: activeVaultPath,
      obsidian_cli_installed: obsidianCliInstalled,
      obsidian_headless_installed: obInstalled,
      note: "This MCP only operates on the active Obsidian vault resolved through the Obsidian CLI.",
    });
  },

  obsidian_list_notes(args) {
    const vaultPath = getVaultPath();
    const prefix = args.prefix || "";
    const limit = args.limit || 200;
    const notes = getVaultIndex(vaultPath).markdownFiles
      .map((filePath) => path.relative(vaultPath, filePath))
      .filter((relativePath) => relativePath.startsWith(prefix))
      .slice(0, limit);

    return textResult({ vault_path: vaultPath, notes, returned: notes.length });
  },

  obsidian_list_attachments(args) {
    const vaultPath = getVaultPath();
    const prefix = args.prefix || "";
    const limit = args.limit || 100;
    const attachments = listAttachmentFiles(vaultPath)
      .map((filePath) => path.relative(vaultPath, filePath))
      .filter((relativePath) => relativePath.startsWith(prefix))
      .slice(0, limit);

    return textResult({ vault_path: vaultPath, attachments, returned: attachments.length });
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

  obsidian_save_attachment(args) {
    const vaultPath = getVaultPath();
    const attachmentFile = resolveVaultPath(vaultPath, args.vault_path);
    const { resolvedSourcePath, bytes } = resolveSourceAttachmentPath(args.source_path);

    if (fs.existsSync(attachmentFile) && !args.overwrite) {
      throw new Error(`Attachment already exists: ${args.vault_path}`);
    }

    fs.mkdirSync(path.dirname(attachmentFile), { recursive: true });
    copyFileAtomic(resolvedSourcePath, attachmentFile);

    return textResult({
      vault_path: vaultPath,
      attachment_path: args.vault_path,
      resolved_path: attachmentFile,
      source_path: resolvedSourcePath,
      bytes,
      updated: true,
    });
  },

  obsidian_search_notes(args) {
    const vaultPath = getVaultPath();
    const query = args.query;
    const limit = args.limit || 50;
    const matches = searchMarkdownFiles(vaultPath, query, args.case_sensitive, limit);

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
    invalidateVaultIndex(vaultPath);

    return textResult({ vault_path: vaultPath, note_path: args.note_path, updated: true });
  },

  obsidian_append_note(args) {
    const vaultPath = getVaultPath();
    const noteFile = resolveNotePath(vaultPath, args.note_path);

    if (!fs.existsSync(noteFile)) {
      throw new Error(`Note does not exist: ${args.note_path}`);
    }

    fs.appendFileSync(noteFile, args.content, "utf8");
    invalidateVaultIndex(vaultPath);

    return textResult({ vault_path: vaultPath, note_path: args.note_path, updated: true });
  },

  obsidian_delete_attachment(args) {
    const vaultPath = getVaultPath();
    const attachmentFile = resolveVaultPath(vaultPath, args.vault_path);

    if (args.vault_path.endsWith(".md")) {
      throw new Error(`Refusing to delete markdown note with attachment tool: ${args.vault_path}`);
    }

    if (!fs.existsSync(attachmentFile)) {
      throw new Error(`Attachment does not exist: ${args.vault_path}`);
    }

    const stats = fs.statSync(attachmentFile);
    if (!stats.isFile()) {
      throw new Error(`Attachment path is not a file: ${args.vault_path}`);
    }

    fs.rmSync(attachmentFile);

    return textResult({
      vault_path: vaultPath,
      attachment_path: args.vault_path,
      deleted_path: attachmentFile,
      bytes: stats.size,
    });
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
    invalidateVaultIndex(vaultPath);

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
    const { markdownFiles } = getVaultIndex(vaultPath);
    const notePath = getKnowledgeNotePath(vaultPath, args.title, folder, markdownFiles);
    const noteFile = resolveNotePath(vaultPath, notePath);
    assertKnowledgeNotePathDoesNotCollide(vaultPath, notePath, args.title);
    const created = !fs.existsSync(noteFile);
    const existingContent = created ? null : fs.readFileSync(noteFile, "utf8");
    const relatedPaths = uniqueStrings(args.related || []).map((title) => resolveExistingNotePathByTitle(vaultPath, title, markdownFiles));
    const relatedLinks = formatWikiLinks(relatedPaths);
    const existingLinks = created
      ? []
      : formatWikiLinks(extractSectionWikiLinks(existingContent, "Related"));
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
    invalidateVaultIndex(vaultPath);

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

      if (updatedRelatedNotes.length > 0) {
        invalidateVaultIndex(vaultPath);
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
  listAttachmentFiles,
  listMarkdownFiles,
  searchMarkdownFiles,
  parseSyncedVaultsOutput,
  patchHeadingSection,
  resetVaultCaches,
  resolveSourceAttachmentPath,
  resolveVaultPath,
  resolveNotePath,
  resolveExistingNotePathByTitle,
  startServer,
};

if (require.main === module) {
  startServer();
}
