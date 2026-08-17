# Pi + OpenRouter SBX

Disposable Windows sandboxes for Pi with OpenRouter.

## Requirements

* Windows 11
* Windows Hypervisor Platform
* `sbx`
* **Docker Desktop** — only needed to build the custom Pi template
* OpenRouter API key

`sbx` itself does **not** require Docker Desktop, Docker Engine, or WSL. Docker Desktop is required here because we use `docker build` to create the Pi template. ([docs.docker.com](https://docs.docker.com/ai/sandboxes/customize/templates/?utm_source=chatgpt.com))

## 1. Enable virtualization

Open **PowerShell as Administrator**:

```powershell id="9qiqi9"
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All
```

Reboot.

## 2. Install Docker Desktop

Install Docker Desktop for Windows and start it.

Docker Desktop is only used to build the Pi template; `sbx` does not depend on Docker Desktop at runtime.

## 3. Install `sbx`

Install the current Windows `sbx` release.

Then:

```powershell id="f683tm"
sbx version
sbx login
```

## 4. Build the Pi template

```powershell id="t2a8f0"
.\scripts\build.ps1
```

The script should:

1. Build the Dockerfile.
2. Save the resulting image to a `.tar`.
3. Load the image into the SBX runtime with `sbx template load`.

For example:

```powershell id="pb292w"
docker build -t pi-sbx:local .
docker image save pi-sbx:local -o pi-sbx.tar
sbx template load pi-sbx.tar
```

SBX can use locally loaded images as templates without pulling them from a registry. ([docs.docker.com](https://docs.docker.com/ai/sandboxes/customize/templates/?utm_source=chatgpt.com))

## 5. Configure OpenRouter

```powershell id="uszrlx"
sbx secret set -g openrouter
```

The API key is stored outside the sandbox and injected by the SBX credential proxy. ([docs.docker.com](https://docs.docker.com/reference/cli/sbx/secret/?utm_source=chatgpt.com))

## 6. Run Pi

```powershell id="co69xp"
.\scripts\run.ps1 C:\code\my-project
```

Each invocation creates a **fresh sandbox** from the Pi template:

* Pi is already installed
* project is mounted read/write
* OpenRouter is available
* no Pi/npm installation occurs
* sandbox state is disposable

SBX supports custom templates with `--template`, and workspace directories are mounted into the sandbox. ([docs.docker.com](https://docs.docker.com/reference/cli/sbx/create/?utm_source=chatgpt.com))

## 7. Network

The sandbox should use a deny-by-default policy with **only OpenRouter allowed**.

Because Pi is baked into the template, the sandbox does not need npm access at runtime.

## 8. Cleanup

`run.ps1` destroys the sandbox when Pi exits.

For an interrupted session:

```powershell id="lhhu0l"
.\scripts\cleanup.ps1
```

## Files

```text id="ie3id7"
README.md
Dockerfile
spec.yaml
scripts/
  build.ps1
  run.ps1
  cleanup.ps1
```

## Lifecycle

```text id="tgafux"
Dockerfile
    ↓
Docker Desktop: docker build
    ↓
pi-sbx.tar
    ↓
sbx template load
    ↓
┌─────────────────┐
│ fresh sandbox   │
│ Pi preinstalled │
│ project mounted │
│ OpenRouter only │
└────────┬────────┘
         ↓
      Pi exits
         ↓
   sandbox deleted
```

The **template persists**; each **sandbox does not**. ([docs.docker.com](https://docs.docker.com/reference/cli/sbx/template/save/?utm_source=chatgpt.com))
