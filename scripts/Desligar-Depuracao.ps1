<#
.SYNOPSIS
  Desliga a Depuracao USB do aparelho e confirma que a porta do ADB fechou.

.DESCRIPTION
  Em alguns firmwares (ex.: Xiaomi TV Stick com Google TV) a porta 5555 so fecha depois
  de reiniciar. Se ela continuar aberta, o script reinicia o aparelho e testa de novo.

.EXAMPLE
  .\Desligar-Depuracao.ps1 -Endereco 192.168.1.50
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Endereco)

Import-Module (Join-Path $PSScriptRoot "lib\AdbTv.psm1") -Force

$adb = Get-AdbPath
$e = Split-Endereco $Endereco
$serial = "$($e.Ip):$($e.Porta)"

Write-Etapa "Desligando a Depuracao USB de $serial"
if (-not (Test-PortaAberta -Ip $e.Ip -Porta $e.Porta)) { Write-Ok "A porta ja esta fechada."; exit 0 }

try { $serial = Connect-Tv -Endereco $Endereco } catch { Write-Erro $_.Exception.Message; exit 1 }
Invoke-TvShell $serial @('input','keyevent','KEYCODE_HOME') | Out-Null
Invoke-TvShell $serial @('settings','put','global','adb_enabled','0') | Out-Null
Start-Sleep -Seconds 5

if (Test-PortaAberta -Ip $e.Ip -Porta $e.Porta) {
    Write-Aviso "A porta continua aberta; reiniciando o aparelho para aplicar..."
    & $adb -s $serial reboot 2>$null | Out-Null
    & $adb disconnect $serial 2>$null | Out-Null
    Start-Sleep -Seconds 80
}
& $adb disconnect $serial 2>$null | Out-Null

if (Test-PortaAberta -Ip $e.Ip -Porta $e.Porta) {
    Write-Erro "A porta 5555 continua aberta. Desligue a Depuracao USB pelo controle remoto (docs/05-restaurar-e-desligar.md)."
    exit 1
}
Write-Ok "Depuracao desligada: a porta 5555 esta fechada."
