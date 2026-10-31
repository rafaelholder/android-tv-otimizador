# Funcoes compartilhadas pelos scripts do android-tv-otimizador.
# Compativel com Windows PowerShell 5.1 e PowerShell 7.
# Mantenha este arquivo em ASCII: o PowerShell 5.1 le .ps1/.psm1 sem BOM como ANSI.

$script:Raiz = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Write-Etapa {
    param([string]$Texto)
    Write-Host ""
    Write-Host "== $Texto" -ForegroundColor Cyan
}

function Write-Ok    { param([string]$Texto) Write-Host "  [ok] $Texto" -ForegroundColor Green }
function Write-Aviso { param([string]$Texto) Write-Host "  [!]  $Texto" -ForegroundColor Yellow }
function Write-Erro  { param([string]$Texto) Write-Host "  [x]  $Texto" -ForegroundColor Red }
function Write-Info  { param([string]$Texto) Write-Host "       $Texto" }

function Get-RaizProjeto { $script:Raiz }

function Get-AdbPath {
    # 1) adb no PATH
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # 2) instalado pelo winget (Google.PlatformTools)
    $winget = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path $winget) {
        $achado = Get-ChildItem $winget -Directory -Filter "Google.PlatformTools*" -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName "platform-tools\adb.exe" } |
            Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($achado) { return $achado }
    }

    # 3) Android SDK
    $sdk = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $sdk) { return $sdk }

    throw "adb nao encontrado. Instale com:  winget install --id Google.PlatformTools -e   (veja docs/02-instalar-adb.md)"
}

function Test-PortaAberta {
    param([string]$Ip, [int]$Porta, [int]$TimeoutMs = 2000)
    $c = New-Object System.Net.Sockets.TcpClient
    try {
        $ok = $c.ConnectAsync($Ip, $Porta).Wait($TimeoutMs) -and $c.Connected
        return [bool]$ok
    } catch { return $false } finally { $c.Dispose() }
}

function Split-Endereco {
    param([string]$Endereco)
    if ($Endereco -match '^(.+):(\d+)$') { return @{ Ip = $Matches[1]; Porta = [int]$Matches[2] } }
    return @{ Ip = $Endereco; Porta = 5555 }
}

function Connect-Tv {
    <#
      Conecta via ADB pela rede e espera a autorizacao na tela da TV.
      Retorna o serial (ip:porta) pronto para uso.
    #>
    param(
        [Parameter(Mandatory)][string]$Endereco,
        [int]$TimeoutSeg = 120
    )
    $adb = Get-AdbPath
    $e = Split-Endereco $Endereco
    $serial = "$($e.Ip):$($e.Porta)"

    if (-not (Test-PortaAberta -Ip $e.Ip -Porta $e.Porta)) {
        throw ("A porta {0} de {1} esta fechada. Ative a Depuracao USB no aparelho " +
               "(docs/01-preparar-o-aparelho.md). Se ja ativou, desligue e ligue a opcao de novo " +
               "ou reinicie o aparelho. Uma VPN ligada no PC tambem pode bloquear a rede local.") -f $e.Porta, $e.Ip
    }

    & $adb connect $serial | Out-Null
    $avisou = $false
    $inicio = Get-Date
    $ultimaReconexao = Get-Date
    while (((Get-Date) - $inicio).TotalSeconds -lt $TimeoutSeg) {
        $estado = (& $adb -s $serial get-state 2>$null)
        if ($estado -eq 'device') { return $serial }
        if (-not $avisou) {
            Write-Aviso "Aceite o aviso 'Permitir depuracao USB?' na TV (marque 'Sempre permitir deste computador')."
            $avisou = $true
        }
        Start-Sleep -Seconds 3
        # Depois de aceito, uma conexao 'unauthorized' antiga pode ficar presa: reinicia o servidor adb a cada 20s.
        if (((Get-Date) - $ultimaReconexao).TotalSeconds -ge 20) {
            & $adb kill-server 2>$null | Out-Null
            & $adb connect $serial 2>$null | Out-Null
            $ultimaReconexao = Get-Date
        }
    }
    throw "O aparelho nao autorizou a conexao em $TimeoutSeg segundos."
}

function Invoke-TvShell {
    # Executa um comando 'adb shell' e devolve as linhas de saida.
    param([Parameter(Mandatory)][string]$Serial, [Parameter(Mandatory)][string[]]$Argumentos)
    $adb = Get-AdbPath
    & $adb -s $Serial shell @Argumentos 2>&1 | ForEach-Object { "$_" }
}

function Get-TvInfo {
    param([Parameter(Mandatory)][string]$Serial)
    $p = { param($k) (Invoke-TvShell $Serial @('getprop', $k) | Select-Object -First 1).Trim() }
    $telaInicial = Invoke-TvShell $Serial @('cmd','package','resolve-activity','--brief','-a','android.intent.action.MAIN','-c','android.intent.category.HOME') |
        Select-Object -Last 1
    [pscustomobject]@{
        Serial      = $Serial
        Modelo      = & $p 'ro.product.model'
        Fabricante  = & $p 'ro.product.manufacturer'
        Android     = & $p 'ro.build.version.release'
        Sdk         = [int](& $p 'ro.build.version.sdk')
        Build       = & $p 'ro.build.fingerprint'
        Launcher    = "$telaInicial".Trim()
    }
}

function Get-TvPacotes {
    # Retorna listas de pacotes: todos (do usuario 0) e desativados.
    param([Parameter(Mandatory)][string]$Serial)
    $todos = Invoke-TvShell $Serial @('pm','list','packages') | ForEach-Object { $_ -replace '^package:', '' } | Where-Object { $_ }
    $desat = Invoke-TvShell $Serial @('pm','list','packages','-d') | ForEach-Object { $_ -replace '^package:', '' } | Where-Object { $_ }
    [pscustomobject]@{ Todos = @($todos); Desativados = @($desat) }
}

function Get-TvConfig {
    param([string]$Serial, [string]$Tabela, [string]$Chave)
    $v = (Invoke-TvShell $Serial @('settings','get',$Tabela,$Chave) | Select-Object -First 1)
    if ($null -eq $v) { return $null }
    $v = "$v".Trim()
    if ($v -eq 'null' -or $v -eq '') { return $null }
    return $v
}

function Set-TvConfig {
    param([string]$Serial, [string]$Tabela, [string]$Chave, $Valor)
    if ($null -eq $Valor) { Invoke-TvShell $Serial @('settings','delete',$Tabela,$Chave) | Out-Null }
    else { Invoke-TvShell $Serial @('settings','put',$Tabela,$Chave,"$Valor") | Out-Null }
}

function Read-Json {
    param([string]$Caminho)
    Get-Content -Path $Caminho -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-Protegidos {
    $arq = Join-Path (Get-RaizProjeto) "perfis\protegidos.json"
    @((Read-Json $arq).pacotes)
}

function Get-Perfis {
    $pasta = Join-Path (Get-RaizProjeto) "perfis"
    Get-ChildItem $pasta -Filter *.json | Where-Object { $_.Name -ne 'protegidos.json' } | ForEach-Object {
        $j = Read-Json $_.FullName
        $j | Add-Member -NotePropertyName arquivo -NotePropertyValue $_.BaseName -Force
        $j
    }
}

function Find-TvPerfil {
    param([Parameter(Mandatory)]$Info, [string]$Nome)
    $perfis = @(Get-Perfis)
    if ($Nome) {
        $p = $perfis | Where-Object { $_.arquivo -eq $Nome } | Select-Object -First 1
        if (-not $p) { throw "Perfil '$Nome' nao existe. Disponiveis: $(($perfis | ForEach-Object arquivo) -join ', ')" }
        return $p
    }
    foreach ($p in $perfis) {
        $modeloOk = @($p.modelos) -contains $Info.Modelo
        $fabOk = (-not $p.fabricantes) -or (@($p.fabricantes) -contains $Info.Fabricante)
        if ($modeloOk -and $fabOk) { return $p }
    }
    return $null
}

function Get-PastaBackups {
    $pasta = Join-Path (Get-RaizProjeto) "backups"
    if (-not (Test-Path $pasta)) { New-Item -ItemType Directory -Path $pasta | Out-Null }
    $pasta
}

function Confirm-Acao {
    param([string]$Pergunta, [switch]$Sim)
    if ($Sim) { return $true }
    $r = Read-Host "$Pergunta [s/N]"
    return ($r -match '^(s|sim|y|yes)$')
}

Export-ModuleMember -Function *
