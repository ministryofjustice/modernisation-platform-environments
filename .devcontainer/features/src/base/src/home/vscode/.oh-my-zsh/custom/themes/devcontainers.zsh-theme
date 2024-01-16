# Oh My Zsh! theme - partly inspired by https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme
# Source: https://github.com/devcontainers/features/blob/main/src/common-utils/scripts/devcontainers.zsh-theme

__zsh_prompt() {
    local prompt_username
    if [ ! -z "${GITHUB_USER}" ]; then 
        prompt_username="@${GITHUB_USER}"
    else
        prompt_username="%n"
    fi
    PROMPT="%{$fg[green]%}${prompt_username} %(?:%{$reset_color%}➜ :%{$fg_bold[red]%}➜ )" # User/exit code arrow
    PROMPT+='%{$fg_bold[blue]%}%(5~|%-1~/…/%3~|%4~)%{$reset_color%} ' # cwd
    PROMPT+='`\
        if [ "$(git config --get devcontainers-theme.hide-status 2>/dev/null)" != 1 ] && [ "$(git config --get codespaces-theme.hide-status 2>/dev/null)" != 1 ]; then \
            export BRANCH=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks rev-parse --short HEAD 2>/dev/null); \
            if [ "${BRANCH}" != "" ]; then \
                echo -n "%{$fg_bold[cyan]%}(%{$fg_bold[red]%}${BRANCH}" \
                && if [ "$(git config --get devcontainers-theme.show-dirty 2>/dev/null)" = 1 ] && \
                    git --no-optional-locks ls-files --error-unmatch -m --directory --no-empty-directory -o --exclude-standard ":/*" > /dev/null 2>&1; then \
                        echo -n " %{$fg_bold[yellow]%}✗"; \
                fi \
                && echo -n "%{$fg_bold[cyan]%})%{$reset_color%} "; \
            fi; \
        fi`'

    # Terraform
    if command -v terraform &> /dev/null; then
      PROMPT+='`\
          terraformVersion=$(terraform -version | grep Terraform | cut -d " " -f 2 | sed "s/v//"); \
          echo -n "[ terraform: %{$fg[blue]%}${terraformVersion}%{$reset_color%} ] " \
      `'
    fi

    # AWS SSO
    if command -v aws-sso &> /dev/null; then
      PROMPT+='`\
          if [[ ${AWS_SSO_PROFILE} == *"development"* || ${AWS_SSO_PROFILE} == *"test"* ]]; then \
            echo -n "[ aws: %{$fg[green]%}${AWS_SSO_PROFILE}@${AWS_DEFAULT_REGION}%{$reset_color%} ] "; \
          elif [[ ${AWS_SSO_PROFILE} == *"preproduction"* ]]; then \
            echo -n "[ aws: %{$fg[yellow]%}${AWS_SSO_PROFILE}@${AWS_DEFAULT_REGION}%{$reset_color%} ] "; \
          elif [[ ${AWS_SSO_PROFILE} == *"production"* ]]; then \
            echo -n "[ aws: %{$fg[red]%}${AWS_SSO_PROFILE}@${AWS_DEFAULT_REGION}%{$reset_color%} ] "; \
          elif [[ ! -z ${AWS_SSO_PROFILE} ]]; then \
            echo -n "[ aws: %{$fg[blue]%}${AWS_SSO_PROFILE}@${AWS_DEFAULT_REGION}%{$reset_color%} ] "; \
          fi`'
    fi

    PROMPT+='%{$fg[white]%}$ %{$reset_color%}'
    unset -f __zsh_prompt
}
__zsh_prompt
