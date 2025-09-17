#!/bin/bash
############################################################################################################
# User Variables (Please change me!)
# If you want to use username and pass add this to proxy e.g. proxy="username:password@mydomain.com:8080"
############################################################################################################
proxy="mydomain.com:8080"
noproxyList="127.0.0.10/8, localhost, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, *.mydomain.com"

############################################################################################################
# Additional functions
############################################################################################################
success() { echo -e "\033[0;32m$1\033[0m"; }
warning() { echo -e "\033[0;33m$1\033[0m"; }
danger()  { echo -e "\033[0;31m$1\033[0m"; }
info()    { echo -e "\033[0;34m$1\033[0m"; }

fileExists() {
    local file="$1"
    if [ -f "$file" ]; then
        success "✅ $file already exists"
        return 0
    else
        danger "❌ $file does not exist"
        return 1
    fi
}

ensureTrailingNewline() {
    local file="$1"
    if [ -f "$file" ] && [ -s "$file" ]; then
        tail -n 1 "$file" | grep -q '^$' || echo >> "$file"
    fi
}

############################################################################################################
info "# Environment Variables Settings..."
############################################################################################################
export proxy="$proxy"
export HTTPS_PROXY="http://$proxy"
export HTTP_PROXY="http://$proxy"
export http_proxy="http://$proxy"
export https_proxy="http://$proxy"
export all_proxy="http://$proxy"
export ftp_proxy="http://$proxy"
export dns_proxy="http://$proxy"
export rsync_proxy="http://$proxy"
export no_proxy="$noproxyList"

envFile="/etc/environment"
if fileExists "$envFile" && ! sudo grep -q "HTTP_PROXY=" "$envFile"; then
    sudo ensureTrailingNewline "$envFile"
    echo "HTTPS_PROXY=\"http://$proxy\"" | sudo tee -a "$envFile" > /dev/null
    echo "HTTP_PROXY=\"http://$proxy\"" | sudo tee -a "$envFile" > /dev/null
    echo "http_proxy=\"http://$proxy\"" | sudo tee -a "$envFile" > /dev/null
    echo "https_proxy=\"http://$proxy\"" | sudo tee -a "$envFile" > /dev/null
    echo "all_proxy=\"http://$proxy\"" | sudo tee -a "$envFile" > /dev/null
    echo "ftp_proxy=\"http://$proxy\"" | sudo tee -a "$envFile" > /dev/null
    echo "dns_proxy=\"http://$proxy\"" | sudo tee -a "$envFile" > /dev/null
    echo "rsync_proxy=\"http://$proxy\"" | sudo tee -a "$envFile" > /dev/null
    echo "no_proxy=\"$noproxyList\"" | sudo tee -a "$envFile" > /dev/null
else
    warning "[SKIPPED] Proxy is already configurated in $envFile"
fi

############################################################################################################
info "# ~/.bashrc Settings..."
############################################################################################################
bashrc="$HOME/.bashrc"
if fileExists "$bashrc" && ! grep -q "export HTTP_PROXY=" "$bashrc"; then
    ensureTrailingNewline "$bashrc"
    {
        echo "export HTTPS_PROXY=\"http://$proxy\""
        echo "export HTTP_PROXY=\"http://$proxy\""
        echo "export http_proxy=\"http://$proxy\""
        echo "export https_proxy=\"http://$proxy\""
        echo "export all_proxy=\"http://$proxy\""
        echo "export ftp_proxy=\"http://$proxy\""
        echo "export dns_proxy=\"http://$proxy\""
        echo "export rsync_proxy=\"http://$proxy\""
        echo "export no_proxy=\"$noproxyList\""
    } >> "$bashrc"
else
    warning "[SKIPPED] Proxy is already configured in $bashrc"
fi

############################################################################################################
info "# ~/.npmrc Settings..."
############################################################################################################
npmrc="$HOME/.npmrc"
if fileExists "$npmrc" && ! grep -q "proxy=" "$npmrc"; then
    ensureTrailingNewline "$npmrc"
    {
        echo "proxy=http://$proxy"
        echo "http-proxy=http://$proxy"
        echo "http_proxy=http://$proxy"
        echo "https_proxy=http://$proxy"
        echo "https-proxy=http://$proxy"
    } >> "$npmrc"
else
    warning "[SKIPPED] Proxy is already configured in $npmrc"
fi

############################################################################################################
info "# ~/.wgetrc Settings..."
############################################################################################################
wgetrc="$HOME/.wgetrc"
if fileExists "$wgetrc" && ! grep -q "https_proxy =" "$wgetrc"; then
    ensureTrailingNewline "$wgetrc"
    {
        echo "https_proxy = http://$proxy/"
        echo "http_proxy = http://$proxy/"
        echo "ftp_proxy = http://$proxy/"
        echo "use_proxy = on"
    } > "$wgetrc"
else
    warning "[SKIPPED] Proxy is already configured in $wgetrc"
fi

############################################################################################################
info "# ~/.curlrc Settings..."
############################################################################################################
curlrc="$HOME/.curlrc"
if fileExists "$curlrc" && ! grep -q "proxy=" "$curlrc"; then
    ensureTrailingNewline "$curlrc"
    echo "proxy=http://$proxy" > "$curlrc"
else
    warning "[SKIPPED] Proxy is already configured in $curlrc"
fi

############################################################################################################
info "# GNOME Settings..."
############################################################################################################
gsettings set org.gnome.system.proxy mode 'auto'
gsettings set org.gnome.system.proxy autoconfig-url 'http://172.31.33.93/proxy.pac'
success "[INFO] Proxy for Gnome settings has been configured"

############################################################################################################
info "# Gradle Proxy Settings..."
############################################################################################################
gradleProps="$HOME/.gradle/gradle.properties"
if fileExists "$gradleProps" && ! grep -q "systemProp.http.proxyHost=" "$gradleProps" 2>/dev/null; then
    mkdir -p "$HOME/.gradle"
    ensureTrailingNewline "$gradleProps"
    {
        echo "systemProp.http.proxyHost=$(echo "$proxy" | cut -d':' -f1)"
        echo "systemProp.http.proxyPort=$(echo "$proxy" | cut -d':' -f2)"
        echo "systemProp.https.proxyHost=$(echo "$proxy" | cut -d':' -f1)"
        echo "systemProp.https.proxyPort=$(echo "$proxy" | cut -d':' -f2)"
        echo "systemProp.http.nonProxyHosts=$noproxyList"
    } >> "$gradleProps"
else
    warning "[SKIPPED] Proxy is already configured in $gradleProps"
fi

############################################################################################################
info "# Docker Proxy Settings..."
############################################################################################################
dockerProxyFile="/etc/systemd/system/docker.service.d/proxy.conf"
if fileExists "$dockerProxyFile" && \
    ! grep -q "Environment=\"HTTP_PROXY=" "$dockerProxyFile" 2>/dev/null; then

    sudo mkdir -p "/etc/systemd/system/docker.service.d"
    {
        echo "[Service]"
        echo "Environment=\"HTTP_PROXY=http://$proxy\""
        echo "Environment=\"HTTPS_PROXY=http://$proxy\""
        echo "Environment=\"NO_PROXY=$noproxyList\""
    } | sudo tee "$dockerProxyFile" > /dev/null
    sudo systemctl daemon-reload > /dev/null
    sudo systemctl restart docker > /dev/null
    success "[INFO] Docker has been restarted"
else
    warning "[SKIPPED] Proxy is already configured in $dockerProxyFile"
fi

############################################################################################################
# APT Proxy Config (Optional)
############################################################################################################
read -p "Do you want to add configuration for APT (Debian-based)? (Y/N): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    aptProxyFile="/etc/apt/apt.conf.d/98proxy.conf"
    if grep -q "Acquire::http::Proxy" "$aptProxyFile" 2>/dev/null; then
        warning "[INFO] APT proxy is already configured"
    else
        {
            echo "Acquire::http::Proxy \"http://$proxy\";"
            echo "Acquire::https::Proxy \"http://$proxy\";"
        } | sudo tee "$aptProxyFile" > /dev/null
        success "[INFO] APT proxy has been configured"
    fi
fi

############################################################################################################
# Final message and loading variables
############################################################################################################
success "[INFO] Loading environment variables to current session..."
while IFS= read -r line; do
    if [[ "$line" =~ ^[A-Z_]+= ]]; then
        eval "export $line"
    fi
done < /etc/environment

success "[INFO] Configuration has beed done successfully"
warning "[WARNING] Please restart your computer to successfully load new configuration"
