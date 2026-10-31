<#
.SYNOPSIS
  Procura TVs e sticks Android na rede local.

.DESCRIPTION
  Testa as portas 5555 (ADB pela rede) e 8008 (Chromecast embutido) em cada endereco
  das redes informadas e mostra o nome que o aparelho anuncia (ex.: "TV da sala").
  Sem -Redes, usa a rede de cada placa do PC com gateway e tambem 192.168.0.x e 192.168.1.x
  (util quando o PC fica atras de um segundo roteador).

.EXAMPLE
  .\Procurar-TV.ps1
.EXAMPLE
  .\Procurar-TV.ps1 -Redes 192.168.15
#>
[CmdletBinding()]
param(
    [string[]]$Redes
)

Import-Module (Join-Path $PSScriptRoot "lib\AdbTv.psm1") -Force

if (-not $Redes) {
    $Redes = @(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.IPv4Address } | ForEach-Object {
        ($_.IPv4Address.IPAddress -split '\.')[0..2] -join '.'
    })
    $Redes = @($Redes + '192.168.0' + '192.168.1') | Select-Object -Unique
}

$vpn = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'TAP|TUN|WireGuard|Wintun|VPN' }
if ($vpn) { Write-Aviso "Ha uma VPN ativa ($($vpn.Name -join ', ')). Se nada aparecer, desconecte a VPN ou libere 'conexoes LAN' nela." }

$achados = @()
foreach ($rede in $Redes) {
    Write-Etapa "Procurando em $rede.1-254"
    $testes = foreach ($i in 1..254) {
        foreach ($porta in 5555, 8008) {
            $c = New-Object System.Net.Sockets.TcpClient
            [pscustomobject]@{ Ip = "$rede.$i"; Porta = $porta; Cliente = $c; Tarefa = $c.ConnectAsync("$rede.$i", $porta) }
        }
    }
    Start-Sleep -Milliseconds 3000
    $abertos = $testes | Where-Object { $_.Tarefa.IsCompleted -and -not $_.Tarefa.IsFaulted -and $_.Cliente.Connected }
    $testes | ForEach-Object { $_.Cliente.Dispose() }

    foreach ($ip in ($abertos | ForEach-Object Ip | Select-Object -Unique)) {
        $portas = @($abertos | Where-Object { $_.Ip -eq $ip } | ForEach-Object Porta)
        $nome = '-'
        if ($portas -contains 8008) {
            try { $nome = (Invoke-RestMethod -Uri "http://${ip}:8008/setup/eureka_info?params=name" -TimeoutSec 3).name } catch { }
        }
        $achados += [pscustomobject]@{
            Endereco       = $ip
            Nome           = $nome
            'ADB (5555)'   = if ($portas -contains 5555) { 'aberta' } else { 'fechada' }
            'Cast (8008)'  = if ($portas -contains 8008) { 'sim' } else { 'nao' }
        }
    }
}

Write-Host ""
if ($achados) {
    $achados | Format-Table -AutoSize
    Write-Info "ADB 'fechada' = a Depuracao USB ainda nao esta ativa nesse aparelho."
    Write-Info "Proximo passo:  .\Otimizar-TV.ps1 -Endereco <endereco>"
} else {
    Write-Aviso "Nenhum aparelho encontrado. Confira se ele esta ligado e na mesma rede."
}
