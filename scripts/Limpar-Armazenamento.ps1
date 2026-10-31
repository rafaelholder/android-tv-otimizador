<#
.SYNOPSIS
  Libera armazenamento sem mexer nos apps que voce usa.

.DESCRIPTION
  Atua so em apps que JA ESTAO DESATIVADOS (por exemplo, pelo Otimizar-TV.ps1):
    - Se a Play Store instalou atualizacoes deles, volta para a versao de fabrica
      (o Android reativa o app nesse momento; o script desativa de novo).
    - Apaga os dados e o cache que eles deixaram.
  Tambem mostra os apps que mais ocupam espaco e os arquivos da pasta Download,
  mas nao apaga nada disso automaticamente.

  Apps em -Preservar e os da lista de protegidos nunca sao tocados.
  O cache dos apps ativos nao e limpo por aqui: sem root, o Android so permite limpar o cache
  de um app especifico pela tela Configuracoes > Apps > (app) > Limpar cache.

.EXAMPLE
  .\Limpar-Armazenamento.ps1 -Endereco 192.168.1.50 -Simular
.EXAMPLE
  .\Limpar-Armazenamento.ps1 -Endereco 192.168.1.50 -Preservar com.exemplo.meuapp
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Endereco,
    [string[]]$Preservar = @(),
    [switch]$Simular,
    [switch]$Sim
)

Import-Module (Join-Path $PSScriptRoot "lib\AdbTv.psm1") -Force

function Get-Livre($serial) {
    $l = (Invoke-TvShell $serial @('df','-h','/data')) | Select-Object -Last 1
    $c = "$l" -split '\s+'
    "{0} livres de {1} ({2} ocupado)" -f $c[3], $c[1], $c[4]
}

Write-Etapa "Conectando em $Endereco"
try { $serial = Connect-Tv -Endereco $Endereco } catch { Write-Erro $_.Exception.Message; exit 1 }
$info = Get-TvInfo -Serial $serial
Write-Ok ("{0} {1} - Android {2}" -f $info.Fabricante, $info.Modelo, $info.Android)
Write-Info ("Armazenamento: " + (Get-Livre $serial))

# ---------------------------------------------------------------- quem ocupa espaco
Write-Etapa "Apps que mais ocupam espaco"
$d = Invoke-TvShell $serial @('dumpsys','diskstats')
function Get-Lista($prefixo) { (($d | Where-Object { $_ -like "${prefixo}:*" }) -replace "^${prefixo}: ", '') | ConvertFrom-Json }
try {
    $nomes = Get-Lista 'Package Names'; $app = Get-Lista 'App Sizes'; $dados = Get-Lista 'App Data Sizes'; $cache = Get-Lista 'Cache Sizes'
    $linhas = for ($k = 0; $k -lt $nomes.Count; $k++) {
        [pscustomobject]@{ App = $nomes[$k]; 'App MB' = [math]::Round($app[$k] / 1MB); 'Dados MB' = [math]::Round($dados[$k] / 1MB)
                           'Cache MB' = [math]::Round($cache[$k] / 1MB); 'Total MB' = [math]::Round(($app[$k] + $dados[$k] + $cache[$k]) / 1MB) }
    }
    $linhas | Sort-Object 'Total MB' -Descending | Select-Object -First 12 | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
    Write-Info "(numeros calculados pelo Android de tempos em tempos; podem estar um pouco desatualizados)"
} catch { Write-Aviso "Nao consegui ler o dumpsys diskstats deste aparelho." }

# ---------------------------------------------------------------- plano
$protegidos = Get-Protegidos
$pacotes = Get-TvPacotes -Serial $serial
$comAtualizacao = @(Invoke-TvShell $serial @('pm','list','packages','-f','-s') | Where-Object { $_ -match '/data/app/' } |
    ForEach-Object { ($_ -split '=')[-1].Trim() })

$alvos = @($pacotes.Desativados | Where-Object { $protegidos -notcontains $_ -and $Preservar -notcontains $_ })
Write-Etapa "Apps desativados que serao limpos"
if (-not $alvos) { Write-Ok "Nenhum app desativado para limpar." }
foreach ($p in $alvos) {
    Write-Info ("{0,-45} {1}" -f $p, $(if ($comAtualizacao -contains $p) { 'voltar p/ fabrica + apagar dados' } else { 'apagar dados' }))
}

Write-Etapa "Arquivos na pasta Download (nao serao apagados)"
$dl = Invoke-TvShell $serial @('ls','-laR','/sdcard/Download') | Where-Object { $_ -match '^-' }
if ($dl) { $dl | ForEach-Object { Write-Info $_ }; Write-Info "Instaladores (.apk) ja instalados podem ser apagados com seguranca pelo gerenciador de arquivos." }
else { Write-Ok "Pasta Download vazia." }

if ($Simular) { Write-Aviso "Modo -Simular: nada foi alterado."; exit 0 }
if (-not $alvos) { exit 0 }
if (-not (Confirm-Acao -Pergunta "Limpar $($alvos.Count) apps desativados?" -Sim:$Sim)) { Write-Aviso "Cancelado."; exit 0 }

# ---------------------------------------------------------------- limpeza
Write-Etapa "Limpando"
foreach ($p in $alvos) {
    if ($comAtualizacao -contains $p) {
        $u = (Invoke-TvShell $serial @('pm','uninstall',$p)) -join ' '   # remove so a atualizacao de um app de sistema
        if ($u -notmatch 'Success') { Write-Aviso "$p : nao removeu a atualizacao ($u)" }
    }
    $c = (Invoke-TvShell $serial @('pm','clear',$p)) -join ' '
    # Remover a atualizacao reativa o app: desativa de novo.
    $r = (Invoke-TvShell $serial @('pm','disable-user','--user','0',$p)) -join ' '
    if ($r -match 'disabled-user') { Write-Ok "$p ($c)" } else { Write-Erro "$p ficou ATIVO: $r" }
}

Invoke-TvShell $serial @('input','keyevent','KEYCODE_HOME') | Out-Null
Write-Etapa "Resultado"
Write-Ok ("Armazenamento: " + (Get-Livre $serial))
