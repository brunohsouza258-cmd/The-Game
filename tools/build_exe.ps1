# Gera build/LanternasDePapel.exe + build/LanternasDePapel.pck sem precisar dos export templates.
# O .exe é o próprio Godot (mesmo nome do .pck): ao abrir, ele roda o jogo direto.
# Uso: powershell -File tools/build_exe.ps1 -Godot "C:\caminho\Godot_v4.x-stable_win64.exe"
param([Parameter(Mandatory = $true)][string]$Godot)
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "build"
New-Item -ItemType Directory -Force $out | Out-Null
& $Godot --headless --path $root --import | Out-Null
& $Godot --headless --path $root --export-pack "Windows Desktop" (Join-Path $out "LanternasDePapel.pck")
Copy-Item $Godot (Join-Path $out "LanternasDePapel.exe") -Force
Write-Host "Pronto: $out\LanternasDePapel.exe (mantenha o .pck na mesma pasta)"
