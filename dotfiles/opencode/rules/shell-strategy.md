# Shell Non-Interactive Strategy

1, Shell environment is strictly **non-interactive**. It lacks a TTY/PTY, meaning any command that waits for user input will hang indefinitely and timeout.
2. Eliminate "human-in-the-loop" dependency during task execution.
3. Never stop after a tool output to "wait for instructions" unless the task is complete.
4. Assume a headless CI environment where any prompt = failure. Strictly avoid editors, pagers, and interactive modes.

## 1. Core Mandates

1. Use `CI=true` to act as if running in a headless CI/CD pipeline.
3. Always preemptively supply "yes" or "force" flags.
4. `Read`/`Write`/`Edit` tools over shell manipulation (`sed`, `echo`, `cat`).
5. Never use `-i` or `-p` flags that require user input.
4. For node modue, use `npm i --yes`, `pnpm install --yes`
5. For git use command like `git commit -m "msg"`, `git merge --no-edit branch`, `git pull --no-edit`
6. For system & files, use `rm -f`, `cp -f`, `mv -f`, `unzip -o`, `ssh -o BatchMode=yes -o StrictHostKeyChecking=no host`, `curl -fsSL url`, `wget -q url`
7. For pyhton use `python -c "code"` or `python script.py`


## 2. Handling Prompts

When a command doesn't have a non-interactive flag:

### The "Yes" Pipe
```bash
yes | ./install_script.sh
```

### Heredoc Input
```bash
./configure.sh <<EOF
option1
option2
EOF
```

### Echo Pipe
```bash
echo "password" | sudo -S command
```

### Timeout Wrapper (last resort)
```bash
timeout 30 ./potentially_hanging_script.sh || echo "Timed out"
```

## 3. Best Practices

1. **Check man pages** (via web search) for `-y`, `--yes`, `--non-interactive`, `-f`, `--force` flags
2. **Use `--help`** to discover non-interactive options: `cmd --help | grep -i "non-interactive\|force\|yes"`
3. **Prefer OpenCode tools** over shell commands for file operations
4. **Set timeout** for any command that might unexpectedly prompt
