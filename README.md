# 🧰 linux-proxy-settings

A Bash script to easily enable or disable system-wide proxy settings for various Linux tools and environments.

---

## 📦 Installation

1. Clone or download this repository.
2. Make the script executable (optional):

   ```bash
   chmod +x setupProxy.sh
   ```

3. Run the script in interactive mode:

   ```bash
   ./setupProxy.sh
   ```

---

## 🚀 Usage

You can run the script in both **interactive** and **non-interactive** modes.

---

### 🧑‍💻 Interactive mode

Just run the script without any arguments:

```bash
./setupProxy.sh
```

You will be prompted for the following:

- Whether to **enable** or **disable** the proxy
- Whether to run in **dry-run** mode (show changes without applying)
- Whether to apply proxy settings to **all components** or only **specific components**

#### ✅ Example interaction:

```
Do you want to [E]nable or [D]isable proxy? E
Dry-run mode? (y/N): y
Do you want to set up proxy only for specific components (e.g. env, apt, docker, bashrc)? (y/N): y
Enter comma-separated component names (e.g. env,docker,bashrc): env,bashrc,curlrc
```

---

### ⚙️ Non-interactive mode

Use command-line options to apply or remove proxy without prompts.

#### ➕ Enable proxy for all components:

```bash
./setupProxy.sh --enable
```

#### ➖ Disable proxy for all components:

```bash
./setupProxy.sh --disable
```

#### 🧪 Dry-run mode (test what would happen):

```bash
./setupProxy.sh --enable --dry-run
./setupProxy.sh --disable --dry-run
```

#### 🎯 Apply proxy only to selected components:

```bash
./setupProxy.sh --enable --only=env,bashrc,curlrc
```

You can also combine with dry-run:

```bash
./setupProxy.sh --enable --only=apt,docker --dry-run
```

---

## 🧩 Available Components

You can apply proxy settings to the following components:

| Component | Description |
|-----------|-------------|
| `env`     | Adds proxy to `/etc/environment` and session environment variables |
| `apt`     | Sets APT proxy via `/etc/apt/apt.conf.d/98proxy.conf` |
| `docker`  | Sets Docker proxy in systemd config |
| `bashrc`  | Adds export lines to `~/.bashrc` |
| `zshrc`   | Adds export lines to `~/.zshrc` |
| `npmrc`   | Configures proxy in `~/.npmrc` |
| `wgetrc`  | Adds proxy settings to `~/.wgetrc` |
| `curlrc`  | Adds proxy settings to `~/.curlrc` |
| `gradle`  | Configures proxy in `~/.gradle/gradle.properties` |

---

## 🔐 Permissions

Some files require **root privileges** to modify:

- `/etc/environment`
- `/etc/apt/apt.conf.d/98proxy.conf`
- `/etc/systemd/system/docker.service.d/proxy.conf`

The script will automatically use `sudo` where necessary.

---

## 🛠️ To Do

- [x] Create repository with proxy settings 🎉 🤣  
- [x] Write Bash script  
- [x] Add "disable proxy" option  
- [ ] Create script to install my favorite apps and configs 😄  

---

## 💡 Tip: Create shell aliases

You can add aliases to your `.bashrc` or `.zshrc` for quick usage:

```bash
alias proxy-on="~/linux-proxy-settings/setupProxy.sh --enable"
alias proxy-off="~/linux-proxy-settings/setupProxy.sh --disable"
```

Reload your shell config:

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

Now you can just run:

```bash
proxy-on
proxy-off
```

---

## 📄 License

MIT – feel free to copy, adapt, and use this script as you wish.
