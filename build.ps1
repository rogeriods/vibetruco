# build.ps1 — gera o executavel Windows fusionado (LÖVE + jogo) em dist/.
# Uso: powershell -ExecutionPolicy Bypass -File .\build.ps1
param(
  [string]$LoveDir = "C:\Program Files\LOVE",
  [string]$OutDir = "dist"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$loveExe = Join-Path $LoveDir "love.exe"
if (-not (Test-Path $loveExe)) { throw "love.exe nao encontrado em $LoveDir" }

$stage = Join-Path $root "build\stage"
$build = Join-Path $root "build"
$dist = Join-Path $root $OutDir
Remove-Item $stage, $dist -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $stage, $dist | Out-Null

# 1) apenas o que o jogo precisa (sem tests, .git, docs)
Copy-Item (Join-Path $root "main.lua") $stage
Copy-Item (Join-Path $root "conf.lua") $stage
Copy-Item (Join-Path $root "src") $stage -Recurse
Copy-Item (Join-Path $root "assets") $stage -Recurse

# 2) empacota o .love (zip com main.lua na raiz)
$loveFile = Join-Path $build "truco.love"
$tmpZip = "$loveFile.zip"
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $tmpZip -Force
Move-Item $tmpZip $loveFile -Force

# 3) funde love.exe + .love num unico executavel
$exe = Join-Path $dist "VibeTruco.exe"
$out = [System.IO.File]::Open($exe, [System.IO.FileMode]::Create)
try {
  foreach ($f in @($loveExe, $loveFile)) {
    $in = [System.IO.File]::OpenRead($f)
    try { $in.CopyTo($out) } finally { $in.Close() }
  }
} finally { $out.Close() }

# 4) DLLs exigidas pelo runtime
$dlls = @("love.dll", "lua51.dll", "mpg123.dll", "msvcp120.dll", "msvcr120.dll", "OpenAL32.dll", "SDL2.dll")
foreach ($d in $dlls) {
  $p = Join-Path $LoveDir $d
  if (Test-Path $p) { Copy-Item $p $dist }
}
Copy-Item (Join-Path $LoveDir "license.txt") $dist -ErrorAction SilentlyContinue

# 5) instrucoes para o amigo
$readme = @"
TRUCO BALATRO 1.0
=================

COMO RODAR
1. Extraia esta pasta inteira (nao rode o .exe de dentro do .zip).
2. Abra VibeTruco.exe.
3. Se o Windows mostrar "O Windows protegeu o computador":
   clique em "Mais informacoes" e depois em "Executar assim mesmo".
   (O aviso aparece porque o .exe nao tem assinatura digital paga.)

CONTROLES
- Mouse/toque: clique na carta para jogar.
- Teclas: 1/2/3 jogam a carta, T pede truco, Enter avanca, Esc sai.

JOGAR COM UM AMIGO (LAN)
1. Os dois na mesma rede Wi-Fi/roteador.
2. Um clica em "CRIAR SALA (LAN)" e ve o IP na tela.
3. O outro clica em "ENTRAR EM SALA", digita esse IP e conecta.
4. Na primeira vez, o firewall do Windows pode pedir permissao:
   marque "Redes privadas" e permita.

REQUISITOS
- Windows 10/11 64 bits.
- Nao precisa instalar nada (Love2D ja esta embutido).
"@
Set-Content -Path (Join-Path $dist "LEIA-ME.txt") -Value $readme -Encoding UTF8

# 6) zip final para enviar
$zip = Join-Path $dist "VibeTruco-Windows.zip"
Compress-Archive -Path (Join-Path $dist "*") -DestinationPath $zip -Force

$exeSize = [math]::Round((Get-Item $exe).Length / 1MB, 2)
$zipSize = [math]::Round((Get-Item $zip).Length / 1MB, 2)
Write-Host "OK: $exe ($exeSize MB)"
Write-Host "OK: $zip ($zipSize MB)"
