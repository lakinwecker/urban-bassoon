-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Pick tokyonight variant from the shared theme-mode state file written by
-- the `theme-toggle` script. Falls back to dark.
local function apply_theme_mode()
  local state = vim.fn.expand((vim.env.XDG_STATE_HOME or "~/.local/state") .. "/theme-mode")
  local mode = "dark"
  local f = io.open(state, "r")
  if f then
    local line = f:read("*l")
    if line and line ~= "" then
      mode = line
    end
    f:close()
  end
  if mode == "light" then
    vim.o.background = "light"
    pcall(vim.cmd.colorscheme, "tokyonight-day")
  else
    vim.o.background = "dark"
    pcall(vim.cmd.colorscheme, "tokyonight-storm")
  end
end

apply_theme_mode()
