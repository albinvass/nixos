require('neorg').setup{
  load = {
    ["core.defaults"] = {},
    ["core.norg.concealer"] = {},
    ["core.norg.dirman"] = {
      config = {
        workspaces = {
          notes = "~/.local/share/norg/notes",
        }
      },
    },
  }
}
