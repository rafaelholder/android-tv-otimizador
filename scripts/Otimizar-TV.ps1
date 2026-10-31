<#
.SYNOPSIS
  Otimiza uma Android TV / Google TV pela rede usando ADB, sem root.

.DESCRIPTION
  1. Conecta no aparelho (e espera voce aceitar o aviso na TV).
  2. Identifica o modelo e escolhe o perfil em perfis\*.json.
  3. Mostra o plano e pede confirmacao.
  4. Salva um backup do estado em backups\ (usado pelo Restaurar-TV.ps1).
  5. Aplica: animacoes 0,5x, protetor de tela "Cores", desativa telemetria/apps inuteis
     e remove do usuario os apps que voltam sozinhos.
  6. Confere se algum app voltou a ficar ativo e, se sim, remove do usuario.
  7. (opcional) Troca o launcher pelo Projectivy Launcher.
  8. (opcional) Desliga a Depuracao USB no final.

  Nada e apagado do sistema: tudo pode ser desfeito com Restaurar-TV.ps1 ou com um reset de fabrica.

.PARAMETER Endereco
  IP do aparelho (ex.: 192.168.1.50) ou IP:porta. Use Procurar-TV.ps1 para descobrir.
.PARAMETER Perfil
  Nome do perfil (arquivo em perfis\ sem .json). Sem ele, o perfil e escolhido pelo modelo.
.PARAMETER Manter
  Pacotes do perfil que NAO devem ser mexidos neste aparelho.
.PARAMETER IncluirMiracast
  Desativa tambem o Miracast (espelhar tela do PC/celular sem Chromecast).
.PARAMETER IncluirStreaming
  Desativa tambem os apps de streaming listados como opcionais no perfil (ex.: Netflix, Prime Video).
.PARAMETER TrocarLauncher
  Troca a tela inicial pelo Projectivy Launcher (precisa de conta Google na Play Store do aparelho).
.PARAMETER DesligarDepuracao
  Desliga a Depuracao USB ao terminar.
.PARAMETER Simular
  So mostra o plano, sem mudar nada.
.PARAMETER Sim
  Nao pede confirmacao.

.EXAMPLE
  .\Otimizar-TV.ps1 -Endereco 192.168.1.50 -Simular
.EXAMPLE
  .\Otimizar-TV.ps1 -Endereco 192.168.1.50 -TrocarLauncher -DesligarDepuracao
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Endereco,
    [string]$Perfil,
    [string[]]$Manter = @(),
    [switch]$IncluirMiracast,
    [switch]$IncluirStreaming,
    [switch]$TrocarLauncher,
    [switch]$DesligarDepuracao,
    [switch]$Simular,
    [switch]$Sim
)

Import-Module (Join-Path $PSScriptRoot "lib\AdbTv.psm1") -Force

$ProjectivyPacote = 'com.spocky.projengmenu'
$ChavesAnimacao = 'window_animation_scale', 'transition_animation_scale', 'animator_duration_scale'
$ProtetorCores = 'com.android.dreams.basic/.Colors'

# ---------------------------------------------------------------- conexao
Write-Etapa "Conectando em $Endereco"
try { $serial = Connect-Tv -Endereco $Endereco } catch { Write-Erro $_.Exception.Message; exit 1 }
$info = Get-TvInfo -Serial $serial
Write-Ok ("{0} {1} - Android {2}" -f $info.Fabricante, $info.Modelo, $info.Android)

$perfilObj = Find-TvPerfil -Info $info -Nome $Perfil
if (-not $perfilObj) {
    Write-Erro "Nenhum perfil para o modelo '$($info.Modelo)' ($($info.Fabricante))."
    Write-Info "Use -Perfil <nome> com um perfil parecido, ou crie um novo em perfis\ (veja docs/06-criar-um-perfil.md)."
    exit 1
}
Write-Ok "Perfil: $($perfilObj.nome) [$($perfilObj.arquivo)]"

# ---------------------------------------------------------------- plano
$protegidos = Get-Protegidos
$pacotes = Get-TvPacotes -Serial $serial

$paraDesativar = @($perfilObj.desativar)
if ($IncluirMiracast -and $perfilObj.opcionais.miracast)   { $paraDesativar += @($perfilObj.opcionais.miracast) }
if ($IncluirStreaming -and $perfilObj.opcionais.streaming) { $paraDesativar += @($perfilObj.opcionais.streaming) }
$paraRemover = @($perfilObj.remover)

$plano = New-Object System.Collections.Generic.List[object]
function Add-Plano($acao, $item) {
    $p = $item.pacote
    $situacao = 'aplicar'
    if ($protegidos -contains $p)             { $situacao = 'protegido (ignorado)' }
    elseif ($Manter -contains $p)             { $situacao = 'mantido (-Manter)' }
    elseif ($pacotes.Todos -notcontains $p)   { $situacao = 'nao existe aqui' }
    elseif ($acao -eq 'desativar' -and $pacotes.Desativados -contains $p) { $situacao = 'ja desativado' }
    $plano.Add([pscustomobject]@{ Acao = $acao; Pacote = $p; Descricao = $item.descricao; Situacao = $situacao })
}
foreach ($i in $paraDesativar) { Add-Plano 'desativar' $i }
foreach ($i in $paraRemover)   { Add-Plano 'remover' $i }

Write-Etapa "Plano"
$plano | Format-Table Acao, Pacote, Situacao, Descricao -AutoSize | Out-String -Width 220 | Write-Host
Write-Info "Tambem: animacoes em 0,5x e protetor de tela 'Cores' (se existir no aparelho)."
if ($TrocarLauncher) { Write-Info "Tambem: trocar o launcher '$($perfilObj.launcherOriginal)' pelo Projectivy." }
if ($DesligarDepuracao) { Write-Info "No final: desligar a Depuracao USB." }

$aplicar = @($plano | Where-Object { $_.Situacao -eq 'aplicar' })
if ($Simular) { Write-Aviso "Modo -Simular: nada foi alterado."; exit 0 }
if (-not (Confirm-Acao -Pergunta "Aplicar $($aplicar.Count) mudancas de pacotes neste aparelho?" -Sim:$Sim)) { Write-Aviso "Cancelado."; exit 0 }

# ---------------------------------------------------------------- backup
$temCores = (Invoke-TvShell $serial @('pm','list','packages','com.android.dreams.basic')) -match 'com.android.dreams.basic'
$backup = [ordered]@{
    criadoEm   = (Get-Date).ToString('s')
    serial     = $serial
    modelo     = $info.Modelo
    fabricante = $info.Fabricante
    android    = $info.Android
    perfil     = $perfilObj.arquivo
    launcherOriginal = $perfilObj.launcherOriginal
    configAntes = [ordered]@{}
    acoes      = New-Object System.Collections.Generic.List[object]
}
foreach ($k in $ChavesAnimacao) { $backup.configAntes["global/$k"] = Get-TvConfig $serial 'global' $k }
$backup.configAntes['secure/screensaver_components'] = Get-TvConfig $serial 'secure' 'screensaver_components'

$nomeBackup = "{0}_{1}_{2}.json" -f ($info.Modelo -replace '[^\w-]', '_'), ($serial -replace '[^\w]', '-'), (Get-Date -Format 'yyyyMMdd-HHmmss')
$arqBackup = Join-Path (Get-PastaBackups) $nomeBackup
function Save-Backup { $backup | ConvertTo-Json -Depth 6 | Set-Content -Path $arqBackup -Encoding UTF8 }
Save-Backup
Write-Ok "Backup do estado: $arqBackup"

# ---------------------------------------------------------------- ajustes
Write-Etapa "Animacoes e protetor de tela"
foreach ($k in $ChavesAnimacao) { Set-TvConfig $serial 'global' $k '0.5' }
Write-Ok "Animacoes em 0,5x"
if ($temCores) {
    Set-TvConfig $serial 'secure' 'screensaver_components' $ProtetorCores
    Write-Ok "Protetor de tela: Cores"
} else { Write-Aviso "Protetor 'Cores' nao existe neste aparelho; mantido o atual." }

Write-Etapa "Desativando"
foreach ($item in ($aplicar | Where-Object Acao -eq 'desativar')) {
    $r = (Invoke-TvShell $serial @('pm','disable-user','--user','0',$item.Pacote)) -join ' '
    if ($r -match 'disabled-user') { Write-Ok "$($item.Pacote)  ($($item.Descricao))"; $backup.acoes.Add(@{ tipo = 'desativar'; pacote = $item.Pacote }) }
    else { Write-Erro "$($item.Pacote): $r" }
}

Write-Etapa "Removendo do usuario (o app continua no sistema e pode voltar)"
foreach ($item in ($aplicar | Where-Object Acao -eq 'remover')) {
    $r = (Invoke-TvShell $serial @('pm','uninstall','-k','--user','0',$item.Pacote)) -join ' '
    if ($r -match 'Success') { Write-Ok "$($item.Pacote)  ($($item.Descricao))"; $backup.acoes.Add(@{ tipo = 'remover'; pacote = $item.Pacote }) }
    else { Write-Erro "$($item.Pacote): $r" }
}
Save-Backup

# ---------------------------------------------------------------- conferencia
Write-Etapa "Conferindo se algum app voltou sozinho (20 s)"
Start-Sleep -Seconds 20
$desatAgora = (Get-TvPacotes -Serial $serial).Desativados
foreach ($a in @($backup.acoes | Where-Object { $_.tipo -eq 'desativar' })) {
    if ($desatAgora -notcontains $a.pacote) {
        $r = (Invoke-TvShell $serial @('pm','uninstall','-k','--user','0',$a.pacote)) -join ' '
        if ($r -match 'Success') {
            $a.tipo = 'remover'
            Write-Aviso "$($a.pacote) foi reativado pelo sistema; removido do usuario."
        } else { Write-Erro "$($a.pacote) foi reativado e nao consegui remover: $r" }
    }
}
Save-Backup
Write-Ok "Conferido."

# ---------------------------------------------------------------- launcher
if ($TrocarLauncher) {
    Write-Etapa "Trocando o launcher pelo Projectivy"
    $orig = $perfilObj.launcherOriginal
    if (-not ((Invoke-TvShell $serial @('pm','list','packages',$ProjectivyPacote)) -match $ProjectivyPacote)) {
        Write-Info "Abrindo o Projectivy Launcher na Play Store do aparelho..."
        Invoke-TvShell $serial @('am','start','-a','android.intent.action.VIEW','-d',"market://details?id=$ProjectivyPacote",'-p','com.android.vending') | Out-Null
        Write-Aviso "Na TV, clique em 'Instalar'. (Se a Play Store pedir login, entre com uma conta Google.) Esperando ate 5 min..."
        $limite = (Get-Date).AddMinutes(5)
        while ((Get-Date) -lt $limite -and -not ((Invoke-TvShell $serial @('pm','list','packages',$ProjectivyPacote)) -match $ProjectivyPacote)) { Start-Sleep -Seconds 5 }
    }
    if (-not ((Invoke-TvShell $serial @('pm','list','packages',$ProjectivyPacote)) -match $ProjectivyPacote)) {
        Write-Aviso "Projectivy nao foi instalado; o launcher original foi mantido."
    } elseif ($protegidos -contains $orig) {
        Write-Aviso "O launcher original esta na lista de protegidos; nao vou desativar."
    } else {
        $r = (Invoke-TvShell $serial @('pm','disable-user','--user','0',$orig)) -join ' '
        Invoke-TvShell $serial @('input','keyevent','KEYCODE_HOME') | Out-Null
        Start-Sleep -Seconds 6
        $foco = (Invoke-TvShell $serial @('dumpsys','window')) | Select-String 'mCurrentFocus' | Select-Object -Last 1
        if ("$foco" -match $ProjectivyPacote) {
            $backup.acoes.Add(@{ tipo = 'launcher'; pacote = $orig })
            Write-Ok "Launcher trocado. Termine as telas de boas-vindas do Projectivy na TV."
            Write-Info "Para deixa-lo mais leve, siga docs/04-ajustes-manuais.md (secao Projectivy)."
        } else {
            # Seguranca: se o Home nao abriu o Projectivy, volta o original.
            Invoke-TvShell $serial @('pm','enable',$orig) | Out-Null
            Write-Erro "O botao Home nao abriu o Projectivy ($foco). Launcher original reativado por seguranca."
        }
    }
    Save-Backup
}

# ---------------------------------------------------------------- final
Write-Etapa "Resumo"
$feitas = @($backup.acoes)
Write-Ok ("{0} desativados, {1} removidos do usuario{2}" -f
    @($feitas | Where-Object { $_.tipo -eq 'desativar' }).Count,
    @($feitas | Where-Object { $_.tipo -eq 'remover' }).Count,
    $(if (@($feitas | Where-Object { $_.tipo -eq 'launcher' }).Count) { ', launcher trocado' } else { '' }))
$mem = (Invoke-TvShell $serial @('cat','/proc/meminfo')) | Select-String 'MemAvailable' | Select-Object -First 1
if ($mem) { Write-Info ("RAM livre agora: {0} MB" -f [math]::Round(([int](("$mem" -split '\s+')[1])) / 1024)) }
Write-Info "Para desfazer:  .\Restaurar-TV.ps1 -Endereco $Endereco"
Write-Info "Faltam os ajustes feitos pelo controle remoto: docs/04-ajustes-manuais.md"

if ($DesligarDepuracao) {
    & (Join-Path $PSScriptRoot "Desligar-Depuracao.ps1") -Endereco $Endereco
}
