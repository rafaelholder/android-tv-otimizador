# Android TV Otimizador

Scripts em PowerShell e um guia passo a passo para deixar **Android TVs e sticks (Xiaomi, TCL e outros) mais leves e com menos rastreamento**: sem root, pela rede, usando o ADB oficial do Google.

Tudo o que os scripts fazem **pode ser desfeito**. Nada é apagado do sistema, e um reset de fábrica também volta tudo ao original.

## O que ele faz

- **Desativa telemetria e apps inúteis de fábrica**: estatísticas da Xiaomi, rastreamento de anúncios (Alphonso), canais de recomendação, apps descontinuados do Google e assim por diante.
- **Remove do usuário** os apps que o sistema reativa sozinho. Exemplos: Alexa da TCL, Xiaomi TV/PatchWall e Text-to-Speech.
- **Animações em 0,5x**: os menus respondem mais rápido.
- **Protetor de tela "Cores"** no lugar do protetor "ambiente", que baixa fotos e ocupa memória.
- **Troca opcional do launcher** pelo [Projectivy Launcher](https://play.google.com/store/apps/details?id=com.spocky.projengmenu), que é leve e sem anúncios. Se o novo launcher não abrir, o original volta automaticamente.
- **Limpeza de armazenamento** dos apps desativados, sem tocar nos apps que você usa.
- **Backup automático** do estado do aparelho e **restauração** com um comando.

### Resultados nos aparelhos testados

| Aparelho | Sistema | RAM livre antes | RAM livre depois |
|---|---|---|---|
| Xiaomi TV Stick 4K | Google TV (Android 14) | ~285 MB | ~330 MB |
| Xiaomi Mi TV Stick (1ª geração) | Android TV 9 | ~195 MB | ~265 MB |
| Xiaomi Mi TV Stick (1ª geração) | Android TV 10 | ~106 MB | ~239 MB |
| TCL Android TV | Android TV 11 | — | launcher de ~200 MB trocado por um de ~110 MB |

A limpeza de armazenamento levou um dos sticks de **758 MB para 1,3 GB livres**.

## Aparelhos com perfil pronto

| Perfil | Modelos |
|---|---|
| `xiaomi-mi-stick-gen1` | Xiaomi Mi TV Stick 1ª geração (`MiTV-AESP0`), Android TV 9 e 10 |
| `xiaomi-tv-stick-4k-googletv` | Xiaomi TV Stick 4K com Google TV (`MiTV-AXTU0`), Android 14 |
| `tcl-android-tv` | TVs TCL com Android TV 11 |

O script escolhe o perfil pelo modelo. Para outros aparelhos, veja [Criar um perfil](docs/06-criar-um-perfil.md).

## Início rápido

> Precisa de um PC com Windows 10/11 na mesma rede da TV.

1. **Prepare o aparelho**: libere as Opções do desenvolvedor e ative a **Depuração USB** → [guia](docs/01-preparar-o-aparelho.md)
2. **Instale o ADB** no PC:
   ```powershell
   winget install --id Google.PlatformTools -e
   ```
3. **Baixe este projeto** (botão *Code → Download ZIP*, ou `git clone`) e abra o PowerShell na pasta `scripts`.
4. **Ache a TV na rede:**
   ```powershell
   .\Procurar-TV.ps1
   ```
5. **Veja o que vai ser feito**, sem mudar nada:
   ```powershell
   .\Otimizar-TV.ps1 -Endereco 192.168.1.50 -Simular
   ```
6. **Otimize.** Aceite o aviso "Permitir depuração USB?" que aparece na TV:
   ```powershell
   .\Otimizar-TV.ps1 -Endereco 192.168.1.50 -TrocarLauncher -DesligarDepuracao
   ```
7. Faça os **ajustes pelo controle remoto** que não dá para automatizar: anúncios, uso e diagnóstico, Modo somente apps e leveza do Projectivy → [guia](docs/04-ajustes-manuais.md)

Se o Windows bloquear os scripts, veja [Solução de problemas](docs/solucao-de-problemas.md#o-windows-nao-deixa-rodar-os-scripts).

## Scripts

| Script | Para que serve |
|---|---|
| `Procurar-TV.ps1` | Lista os aparelhos da rede, com nome e status do ADB |
| `Otimizar-TV.ps1` | Aplica o perfil: desativa, remove do usuário, ajusta animações e protetor, e troca o launcher se você pedir |
| `Limpar-Armazenamento.ps1` | Libera espaço dos apps desativados e mostra quem ocupa mais |
| `Restaurar-TV.ps1` | Desfaz tudo usando o backup salvo em `backups/` |
| `Desligar-Depuracao.ps1` | Desliga a Depuração USB e confere se a porta fechou |

Principais opções do `Otimizar-TV.ps1`:

| Opção | Efeito |
|---|---|
| `-Simular` | Só mostra o plano |
| `-Perfil <nome>` | Força um perfil (nome do arquivo em `perfis/`, sem `.json`) |
| `-Manter <pacote>,<pacote>` | Não mexe nesses pacotes |
| `-IncluirMiracast` | Desativa também o espelhamento de tela (Miracast) |
| `-IncluirStreaming` | Desativa também os apps de streaming opcionais do perfil (ex.: Netflix, Prime Video) |
| `-TrocarLauncher` | Instala e ativa o Projectivy Launcher |
| `-DesligarDepuracao` | Desliga a Depuração USB no final |
| `-Sim` | Não pede confirmação |

Todos os scripts têm ajuda: `Get-Help .\Otimizar-TV.ps1 -Full`.

## Segurança

- **Lista de protegidos** ([`perfis/protegidos.json`](perfis/protegidos.json)): os scripts nunca desativam pacotes essenciais, como interface do sistema, configurações, entradas HDMI, controle remoto, Bluetooth, Play Store, Google Play Services e teclado.
- **Desativar ≠ apagar.** `pm disable-user` e `pm uninstall -k --user 0` só escondem o app do usuário. O app continua no sistema e volta com `Restaurar-TV.ps1` ou com um reset de fábrica.
- **Conferência pós-ajuste.** Alguns firmwares reativam apps sozinhos. O script verifica e trata esses casos.
- **Launcher com segurança.** Se o botão Home não abrir o novo launcher, o original é reativado na hora.
- **Depuração desligada no final.** Com a depuração ligada, qualquer aparelho da rede que você autorizar pode controlar a TV.

## Desfazer

```powershell
.\Restaurar-TV.ps1 -Endereco 192.168.1.50
```

Detalhes e o que desfazer pelo controle remoto: [Restaurar e desligar](docs/05-restaurar-e-desligar.md).

## Guia completo

1. [Preparar o aparelho](docs/01-preparar-o-aparelho.md)
2. [Instalar o ADB](docs/02-instalar-adb.md)
3. [Otimizar](docs/03-otimizar.md)
4. [Ajustes manuais (controle remoto)](docs/04-ajustes-manuais.md)
5. [Restaurar e desligar a depuração](docs/05-restaurar-e-desligar.md)
6. [Criar um perfil para outro aparelho](docs/06-criar-um-perfil.md)
7. [Solução de problemas](docs/solucao-de-problemas.md)

## Aviso

Use por sua conta e risco e só em aparelhos que são seus. O projeto não tem relação com Google, Xiaomi ou TCL. Os nomes de pacotes podem mudar entre versões de firmware, então rode sempre com `-Simular` antes.

## Licença

[MIT](LICENSE)
