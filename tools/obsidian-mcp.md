# Obsidian MCP

This repo ships a local MCP server at `tools/obsidian-mcp.js`.

What it does:
- reads and writes notes directly from the current Obsidian vault
- can copy, list, and delete binary attachments in the vault from local file paths for inline embeds such as `![[paper.pdf]]`
- optionally runs `ob sync` and `ob sync-status` when `obsidian-headless` is installed
- can create or update structured captured notes with related links to existing notes

What `obsidian-headless` is used for:
- syncing a local vault with Obsidian Sync
- not direct note reads or writes

What the Obsidian app CLI is used for:
- resolving `OBSIDIAN_VAULT_NAME` to a vault path
- resolving the active vault when `OBSIDIAN_VAULT_NAME` is not set
- this is the `obsidian` command exposed by the Obsidian desktop app when you enable the command-line interface in Obsidian settings

Setup:
1. Install `obsidian-headless` with `npm install -g obsidian-headless`
2. Run `ob login`
3. Configure your local vault with `ob sync-setup --vault <vault-name> --path <vault-path>`
4. Enable the command-line interface in the Obsidian desktop app settings so the `obsidian` command is available on `PATH`

Vault resolution order:
- `OBSIDIAN_VAULT_NAME`
- active vault from the Obsidian app CLI (`obsidian`)

Captured note workflow:
- use `obsidian_search_notes` and `obsidian_read_note` to inspect existing notes
- use `obsidian_upsert_knowledge_note` to keep a canonical structured note in `Captured/`
- captured notes are agent-owned and are rewritten from the tool arguments on update
- generated captured notes include `agent_owned: true` in frontmatter to make that ownership explicit
- `related` entries must resolve to exactly one existing note in the vault; missing or ambiguous titles return an error
- related notes are written as wiki links and existing related notes can be linked back automatically
- only links already under `## Related` are preserved on update; manual edits to frontmatter, summary, details, or other sections may be lost

OpenCode is configured through `home-manager/modules/devtools/opencode/opencode.json` to run the local server from this repo.

If the `obsidian` command is unavailable, the MCP will fail and tell you to enable the command-line interface in Obsidian settings.
