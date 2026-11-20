# Dotfiles bare repo — manage tracked configs with: config <git-command>
DISABLE_CORRECT="config"
function config() {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}



# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/.config/zsh/cachyos-config.zsh  # was /usr/share/cachyos-zsh-config (CachyOS package)

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/home/zpt/.bun/_bun" ] && source "/home/zpt/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias notifs='dunstctl history | jq -r ".data[][] | \"\(.summary.data): \(.body.data)\""'
alias upgrade='yay -Syyu && flatpak upgrade'
alias cb='/usr/bin/gt'  # Codeberg CLI (Arch gitea-cli ships tea as gt)
