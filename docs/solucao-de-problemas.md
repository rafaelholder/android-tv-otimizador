# Solução de problemas

## O Windows não deixa rodar os scripts

Mensagem: *"a execução de scripts foi desabilitada neste sistema"* ou *"não está assinado digitalmente"*.

```powershell
# Libera scripts locais só para o seu usuário
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# Desbloqueia os arquivos baixados como ZIP (rode na pasta do projeto)
Get-ChildItem -Recurse | Unblock-File
```

Outra opção é rodar um script pontualmente com `powershell -ExecutionPolicy Bypass -File .\Otimizar-TV.ps1 -Endereco ...`.

## "A porta 5555 está fechada"

- Confira se a **Depuração USB** está ligada ([guia](01-preparar-o-aparelho.md)).
- Desligue e ligue a opção de novo, ou reinicie o aparelho. Vários sticks só abrem a porta depois disso.
- Em alguns firmwares, ative também **"Depuração ADB pela rede"**.
- Confira o IP. Ele muda se o roteador entregar outro endereço; rode `.\Procurar-TV.ps1`.

## `Procurar-TV.ps1` não acha nada

- **VPN ligada no PC** (Proton, WireGuard e outras) desvia o tráfego. Desconecte, ou permita "conexões LAN".
- O PC e a TV podem estar em redes diferentes. Informe a rede: `.\Procurar-TV.ps1 -Redes 192.168.15`.

## Fica em "unauthorized" mesmo depois de aceitar na TV

O script reinicia o servidor adb sozinho a cada 20 segundos. Manualmente:

```powershell
adb kill-server
adb connect 192.168.1.50:5555
```

## Um app desativado voltou

Isso acontece de três formas:

- **O firmware reativa o app.** É o caso da Alexa e da Conta TCL. O `Otimizar-TV.ps1` detecta e remove do usuário.
- **A Play Store atualiza o app.** Atualizar reativa. Aconteceu com o Text-to-Speech depois do login na conta Google. Rode o `Otimizar-TV.ps1` de novo, ou mova o pacote para `remover` no perfil.
- **Remover a atualização de um app de sistema também reativa.** O `Limpar-Armazenamento.ps1` já desativa de novo.

## O launcher novo não aparece

Se o Home não abrir o Projectivy, o script reativa o launcher original na hora. Para voltar ao original de propósito, use `.\Restaurar-TV.ps1` ou ative de novo pelo adb:

```powershell
adb -s 192.168.1.50:5555 shell pm enable com.google.android.tvlauncher
```

O nome do launcher depende do aparelho: `com.google.android.tvlauncher` no Android TV e `com.google.android.apps.tv.launcherx` no Google TV.

## A Play Store pede login

Sem conta Google, a Play Store não instala nada, nem o Projectivy. Entre com uma conta pelo controle remoto. Os scripts não digitam senhas.

## Desliguei a depuração, mas a porta continua aberta

Alguns firmwares só fecham a porta depois de reiniciar. O `Desligar-Depuracao.ps1` reinicia sozinho. Pelo controle remoto: desligue a opção e reinicie o aparelho.

## Quero limpar o cache de um app que eu uso

Sem root, o Android não oferece um comando que limpe o cache de **um** app sem apagar os dados dele. Use a tela **Configurações → Apps → (app) → Limpar cache**. O comando `pm trim-caches` limpa o cache de **todos** os apps de uma vez, e por isso os scripts não o usam.

## Acentos aparecem estranhos no PowerShell

Os scripts são escritos sem acentos de propósito: o Windows PowerShell 5.1 lê arquivos sem BOM como ANSI. Se você editar algum script e usar acentos, salve em **UTF-8 com BOM**.
