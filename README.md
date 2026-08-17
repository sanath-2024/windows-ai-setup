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

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All
```

Reboot.

## 2. Install Docker Desktop

Install Docker Desktop for Windows and start it. You can use WSL2 as the backend.

Under "Settings" / "General", un-check "Send usage statistics".

Under "Settings" / "AI", un-check "Enable Gordon".

Docker Desktop is only used to build the Pi template; `sbx` does not depend on Docker Desktop at runtime.

## 3. Install `sbx`

Install the current Windows `sbx` release.

Then:

```powershell
sbx version
sbx login
setx SBX_NO_TELEMETRY 1
```

## 4. Build the Pi template

```powershell
.\scripts\build.ps1
```

SBX can use locally loaded images as templates without pulling them from a registry. ([docs.docker.com](https://docs.docker.com/ai/sandboxes/customize/templates/?utm_source=chatgpt.com))

## 5. Configure OpenRouter

Sign up for OpenRouter, and under "Preferences" / "Privacy", turn on Zero Data Retention for all providers. Un-check "Allow free endpoints that train on request data".

On OpenRouter, select "Get API Key", and enter a sufficiently small key limit such as $20. You can set a reset schedule for the credit limit, such as monthly.

Note: you must copy your key immediately as you are generating it. If you forget to do so, no big deal - just create another one.

It is good practice to set an expiry on your key.

```powershell
sbx secret set openrouter
```

The API key is stored outside the sandbox and injected by the SBX credential proxy. ([docs.docker.com](https://docs.docker.com/reference/cli/sbx/secret/?utm_source=chatgpt.com))

## 6. Run Pi

```powershell
.\scripts\run.ps1 C:\code\my-project
```

Use the "Locked Down" network policy to deny all network traffic by default, unless explicitly allowed.

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

```powershell
.\scripts\cleanup.ps1
```

## Files

```text
README.md
Dockerfile
spec.yaml
scripts/
  build.ps1
  run.ps1
  cleanup.ps1
```

## Lifecycle

```text
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
