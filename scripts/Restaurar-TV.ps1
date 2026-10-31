<#
.SYNOPSIS
  Desfaz o que o Otimizar-TV.ps1 fez, usando o backup salvo em backups\.

.DESCRIPTION
  - Reativa os apps desativados.
  - Reinstala (para o usuario) os apps removidos.
  - Reativa o launcher original, se ele foi trocado.
  - Volta as animacoes e o protetor de tela para os valores de antes.
  Sem -Backup, usa o backup mais recente deste aparelho.

.EXAMPLE
  .\Restaurar-TV.ps1 -Endereco 192.168.1.50
.EXAMPLE
  .\Restaurar-TV.ps1 -Endereco 192.168.1.50 -Backup ..\backups\MiTV-AESP0_192-168-1-50-5555_20261031-010203.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Endereco,
    [string]$Backup,
    [switch]$Sim
)

Import-Module (Join-Path $PSScriptRoot "lib\AdbTv.psm1") -Force

Write-Etapa "Conectando em $Endereco"
try { $serial = Connect-Tv -Endereco $Endereco } catch { Write-Erro $_.Exception.Message; exit 1 }
$info = Get-TvInfo -Serial $serial
Write-Ok ("{0} {1} - Android {2}" -f $info.Fabricante, $info.Modelo, $info.Android)

if (-not $Backup) {
    $prefixo = "{0}_{1}_" -f ($info.Modelo -replace '[^\w-]', '_'), ($serial -replace '[^\w]', '-')
    $Backup = Get-ChildItem (Get-PastaBackups) -Filter "$prefixo*.json" | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
    if (-not $Backup) {
        # O IP pode ter mudado: tenta pelo modelo.
        $Backup = Get-ChildItem (Get-PastaBackups) -Filter "$($info.Modelo -replace '[^\w-]', '_')_*.json" |
            Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
        if ($Backup) { Write-Aviso "Nenhum backup com este IP; usando o mais recente deste modelo." }
    }
}
if (-not $Backup -or -not (Test-Path $Backup)) { Write-Erro "Nenhum backup encontrado em backups\. Use -Backup <arquivo>."; exit 1 }

$b = Read-Json $Backup
Write-Ok "Backup: $Backup (criado em $($b.criadoEm))"
if ($b.modelo -ne $info.Modelo) { Write-Aviso "O backup e do modelo '$($b.modelo)', mas este aparelho e '$($info.Modelo)'." }

$acoes = @($b.acoes)
[array]::Reverse($acoes)
Write-Etapa "Vai desfazer"
$acoes | ForEach-Object { Write-Info ("{0,-9} {1}" -f $_.tipo, $_.pacote) }
Write-Info "e voltar animacoes/protetor de tela aos valores anteriores."
if (-not (Confirm-Acao -Pergunta "Restaurar?" -Sim:$Sim)) { Write-Aviso "Cancelado."; exit 0 }

Write-Etapa "Restaurando apps"
foreach ($a in $acoes) {
    switch ($a.tipo) {
        'remover'   { $r = (Invoke-TvShell $serial @('cmd','package','install-existing',$a.pacote)) -join ' ' }
        default     { $r = (Invoke-TvShell $serial @('pm','enable',$a.pacote)) -join ' ' }   # desativar / launcher
    }
    if ($r -match 'installed|enabled|Success') { Write-Ok $a.pacote } else { Write-Aviso "$($a.pacote): $r" }
}

Write-Etapa "Restaurando configuracoes"
foreach ($p in $b.configAntes.PSObject.Properties) {
    $tabela, $chave = $p.Name -split '/', 2
    Set-TvConfig $serial $tabela $chave $p.Value
    Write-Ok ("{0} = {1}" -f $p.Name, $(if ($null -eq $p.Value) { '(padrao)' } else { $p.Value }))
}

Invoke-TvShell $serial @('input','keyevent','KEYCODE_HOME') | Out-Null
Write-Etapa "Pronto"
Write-Info "Ajustes feitos pelo controle remoto (anuncios, uso e diagnostico, Modo somente apps) nao sao desfeitos aqui:"
Write-Info "veja docs/05-restaurar-e-desligar.md."
