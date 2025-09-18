#!/bin/bash

############################################################################################################
# User Variables
# If you want to use username and pass add this to proxy e.g. proxy="username:password@mydomain.com:8080"
############################################################################################################
proxy="proxy.mydomain.com:8080"
noproxyList="127.0.0.0/8,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,*.mydomain.com"

############################################################################################################
# UI Functions
############################################################################################################
success() { echo -e "\033[0;32m$1\033[0m"; }
warning() { echo -e "\033[0;33m$1\033[0m"; }
danger()  { echo -e "\033[0;31m$1\033[0m"; }
info()    { echo -e "\033[0;34m$1\033[0m"; }

############################################################################################################
# Global Flags
############################################################################################################
DRY_RUN=false
ONLY_COMPONENTS=()

############################################################################################################
# Helpers
############################################################################################################
ensureTrailingNewline() {
    local file="$1"
    local use_sudo="${2:-false}"

    if [ -f "$file" ] && [ -s "$file" ]; then
        if ! tail -n 1 "$file" | grep -q '^$'; then
            if [[ "$use_sudo" == true ]]; then
                echo | sudo tee -a "$file" > /dev/null
            else
                echo >> "$file"
            fi
        fi
    fi
}

proxyConfigured() {
    local file="$1"
    local pattern="$2"
    [ -f "$file" ] && grep -Fq "$pattern" "$file"
}

appendProxyBlockIfMissing() {
    local file="$1"
    local content="$2"
    local use_sudo="${3:-false}"

    ensureTrailingNewline "$file" "$use_sudo"

    if proxyConfigured "$file" "HTTP_PROXY=\"http://$proxy\"" ; then
        warning "⚠️  Proxy is already configured in $file"
        return
    fi

    if $DRY_RUN; then
        info "[DRY-RUN] Would append proxy block to $file"
        echo "------------------------"
        echo "$content"
        echo "------------------------"
    else
        if [[ "$use_sudo" == true ]]; then
            if echo "$content" | sudo tee -a "$file" > /dev/null; then
                success "✅ Proxy block added to $file"
            else
                danger "❌ Failed to add proxy block to $file"
            fi
        else
            if echo "$content" >> "$file"; then
                success "✅ Proxy block added to $file"
            else
                danger "❌ Failed to add proxy block to $file"
            fi
        fi
    fi
}

addProxyBlock() {
    local file="$1"
    local block="$2"

    if [[ "$file" == /etc/* ]]; then
        appendProxyBlockIfMissing "$file" "$block" true
    else
        appendProxyBlockIfMissing "$file" "$block" false
    fi
}

removeProxySection() {
    local file="$1"
    local start_marker="# setupProxy - start"
    local end_marker="# setupProxy - end"

    if [ ! -f "$file" ]; then
        danger "[ERROR] File $file does not exist"
        return
    fi

    if ! grep -q "$start_marker" "$file"; then
        warning "⚠️  Proxy section not found in $file"
        return
    fi

    if $DRY_RUN; then
        info "[DRY-RUN] Would remove proxy section from $file"
    else
        if [[ "$file" == /etc/* || "$file" == /usr/* ]]; then
            sudo sed -i "/$start_marker/,/$end_marker/d" "$file"
        else
            sed -i "/$start_marker/,/$end_marker/d" "$file"
        fi
        success "✅ Proxy section removed from $file"
    fi
}

restartDocker() {
    if $DRY_RUN; then
        info "[DRY-RUN] Would restart Docker"
        return
    fi
    if systemctl list-units --type=service | grep -q docker; then
        sudo systemctl daemon-reexec
        sudo systemctl daemon-reload
        sudo systemctl restart docker
    else
        warning "⚠️  Docker service not found or inactive, skipping restart."
    fi
}

shouldRun() {
    if [[ ${#ONLY_COMPONENTS[@]} -eq 0 ]]; then
        return 0
    fi

    local comp="$1"
    for c in "${ONLY_COMPONENTS[@]}"; do
        if [[ "$c" == "$comp" ]]; then
            return 0
        fi
    done

    return 1
}

############################################################################################################
# Proxy Logic
############################################################################################################
enableProxy() {
    export HTTPS_PROXY="http://$proxy"
    export HTTP_PROXY="http://$proxy"
    export http_proxy="http://$proxy"
    export https_proxy="http://$proxy"
    export all_proxy="http://$proxy"
    export ftp_proxy="http://$proxy"
    export dns_proxy="http://$proxy"
    export rsync_proxy="http://$proxy"
    export no_proxy="$noproxyList"

    if echo "$noproxyList" | grep -Eq '(\*|/[0-9]+)'; then
        warning "⚠️  Docker may not support wildcards or CIDR in NO_PROXY."
    fi

    local blockEnv=$(cat <<EOF
# setupProxy - start
HTTPS_PROXY="http://$proxy"
HTTP_PROXY="http://$proxy"
http_proxy="http://$proxy"
https_proxy="http://$proxy"
all_proxy="http://$proxy"
ftp_proxy="http://$proxy"
dns_proxy="http://$proxy"
rsync_proxy="http://$proxy"
no_proxy="$noproxyList"
# setupProxy - end
EOF
)

    local blockApt=$(cat <<EOF
# setupProxy - start
Acquire::http::Proxy "http://$proxy";
Acquire::https::Proxy "http://$proxy";
# setupProxy - end
EOF
)

    local blockDocker=$(cat <<EOF
# setupProxy - start
Environment="HTTP_PROXY=http://$proxy"
Environment="HTTPS_PROXY=http://$proxy"
Environment="NO_PROXY=$noproxyList"
# setupProxy - end
EOF
)

    local blockNpm=$(cat <<EOF
# setupProxy - start
proxy=http://$proxy
https-proxy=http://$proxy
registry=http://registry.npmjs.org/
# setupProxy - end
EOF
)

    local blockWget=$(cat <<EOF
# setupProxy - start
http_proxy=http://$proxy
https_proxy=http://$proxy
# setupProxy - end
EOF
)

    local blockCurl=$(cat <<EOF
# setupProxy - start
proxy = $proxy
# setupProxy - end
EOF
)

    local gradleProps="$HOME/.gradle/gradle.properties"
    mkdir -p "$(dirname "$gradleProps")"
    [ -f "$gradleProps" ] || touch "$gradleProps"

    local blockGradle=$(cat <<EOF
# setupProxy - start
systemProp.http.proxyHost=$(echo $proxy | cut -d':' -f1)
systemProp.http.proxyPort=$(echo $proxy | cut -d':' -f2)
systemProp.https.proxyHost=$(echo $proxy | cut -d':' -f1)
systemProp.https.proxyPort=$(echo $proxy | cut -d':' -f2)
systemProp.http.nonProxyHosts=$(echo $noproxyList | sed 's/,/|/g')
# setupProxy - end
EOF
)

    shouldRun "env"    && addProxyBlock "/etc/environment" "$blockEnv"
    shouldRun "apt"    && addProxyBlock "/etc/apt/apt.conf.d/98proxy.conf" "$blockApt"
    shouldRun "docker" && addProxyBlock "/etc/systemd/system/docker.service.d/proxy.conf" "$blockDocker"
    shouldRun "bashrc" && addProxyBlock "$HOME/.bashrc" "$blockEnv"
    shouldRun "zshrc"  && addProxyBlock "$HOME/.zshrc" "$blockEnv"
    shouldRun "npmrc"  && addProxyBlock "$HOME/.npmrc" "$blockNpm"
    shouldRun "wgetrc" && addProxyBlock "$HOME/.wgetrc" "$blockWget"
    shouldRun "curlrc" && addProxyBlock "$HOME/.curlrc" "$blockCurl"
    shouldRun "gradle" && addProxyBlock "$gradleProps" "$blockGradle"

    restartDocker
}

disableProxy() {
    shouldRun "env"    && removeProxySection "/etc/environment"
    shouldRun "apt"    && removeProxySection "/etc/apt/apt.conf.d/98proxy.conf"
    shouldRun "docker" && removeProxySection "/etc/systemd/system/docker.service.d/proxy.conf"
    shouldRun "bashrc" && removeProxySection "$HOME/.bashrc"
    shouldRun "zshrc"  && sremoveProxySection "$HOME/.zshrc"
    shouldRun "npmrc"  && removeProxySection "$HOME/.npmrc"
    shouldRun "wgetrc" && removeProxySection "$HOME/.wgetrc"
    shouldRun "curlrc" && removeProxySection "$HOME/.curlrc"
    shouldRun "gradle" && removeProxySection "$HOME/.gradle/gradle.properties"
    success "✅ Proxy has been disabled successfully."
    restartDocker
}

############################################################################################################
# Entry Point
############################################################################################################

case "$1" in
    --enable)
        shift
        [[ "$1" == "--dry-run" ]] && DRY_RUN=true && shift
        if [[ "$1" == --only=* ]]; then
            IFS=',' read -ra ONLY_COMPONENTS <<< "${1#--only=}"
            shift
        fi
        enableProxy
        ;;
    --disable)
        shift
        [[ "$1" == "--dry-run" ]] && DRY_RUN=true && shift
        if [[ "$1" == --only=* ]]; then
            IFS=',' read -ra ONLY_COMPONENTS <<< "${1#--only=}"
            shift
        fi
        disableProxy
        ;;
    *)
    read -p "Do you want to [E]nable or [D]isable proxy? " action
    read -p "Dry-run mode? (y/N): " dry
    [[ "$dry" =~ ^[Yy]$ ]] && DRY_RUN=true

    read -p "Do you want to set up proxy only for specific components (env, apt, docker, bashrc, zshrc, npmrc, wgetrc, curlrc, gradle)? (y/N): " comp
    if [[ "$comp" =~ ^[Yy]$ ]]; then
        read -p "Enter comma-separated component names (e.g. env, docker, bashrc): " input_components
        IFS=',' read -ra entered_components <<< "$input_components"

        valid_components=("env" "apt" "docker" "bashrc" "zshrc" "npmrc" "wgetrc" "curlrc" "gradle")
        ONLY_COMPONENTS=()

        for comp in "${entered_components[@]}"; do
            comp_trimmed="$(echo "$comp" | xargs)"  # Trim whitespace
            if [[ " ${valid_components[*]} " =~ " $comp_trimmed " ]]; then
                ONLY_COMPONENTS+=("$comp_trimmed")
            else
                danger "❌ Invalid component: '$comp_trimmed'"
                exit 1
            fi
        done
    fi

    if [[ "$action" =~ ^[Ee]$ ]]; then
        enableProxy
    elif [[ "$action" =~ ^[Dd]$ ]]; then
        disableProxy
    else
        danger "❌ Invalid option"
        exit 1
    fi
    ;;
esac
