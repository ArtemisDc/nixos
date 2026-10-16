{ config, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    neovim
    #plugin dependencies
    tree-sitter
    gnutar
    curl
    gcc
    texliveMedium
    ripgrep
    #lsp dependencies
    clang-tools
    neocmakelsp
  ];
}
