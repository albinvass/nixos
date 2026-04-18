# Obsidian MCP

This repo now ships a local MCP server at `tools/obsidian-mcp.js`.

What it does:
- reads and writes notes directly from the current Obsidian vault
- optionally runs `ob sync` and `ob sync-status` when `obsidian-headless` is installed
- can create or update structured captured notes with related links

What `obsidian-headless` is used for:
- syncing a local vault with Obsidian Sync
- not direct note reads or writes

Setup:
1. Install `obsidian-headless` with `npm install -g obsidian-headless`
2. Run `ob login`
3. Configure your local vault with `ob sync-setup --vault <vault-name> --path <vault-path>`
4. Optional: set `OBSIDIAN_VAULT_PATH` if you want a fixed vault for the MCP server

Vault resolution order:
- `OBSIDIAN_VAULT_PATH`
- active vault from `obsidian-cli`

Captured note workflow:
- use `obsidian_search_notes` and `obsidian_read_note` to inspect existing notes
- use `obsidian_upsert_knowledge_note` to keep a canonical structured note in `Captured/`
- related notes are written as wiki links and existing related notes can be linked back automatically

Claude Code is configured through `.mcp.json` to run the local server from this repo.

To remove the old third-party user-scoped server:
`claude mcp remove obsidian -s user`
