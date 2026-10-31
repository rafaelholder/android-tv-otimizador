# 6. Criar um perfil para outro aparelho

Um perfil é um arquivo JSON em `perfis/` que diz o que mexer num modelo.

## 6.1 Descobrir o modelo e os pacotes

Com a depuração ligada e o PC autorizado:

```powershell
adb connect 192.168.1.50:5555
adb -s 192.168.1.50:5555 shell getprop ro.product.model
adb -s 192.168.1.50:5555 shell getprop ro.product.manufacturer
adb -s 192.168.1.50:5555 shell pm list packages -s
```

Para ver quanto cada processo usa de memória:

```powershell
adb -s 192.168.1.50:5555 shell dumpsys meminfo
```

## 6.2 Formato

```json
{
  "nome": "Marca Modelo - Android TV 11",
  "modelos": ["VALOR_DE_ro.product.model"],
  "fabricantes": ["VALOR_DE_ro.product.manufacturer"],
  "launcherOriginal": "com.google.android.tvlauncher",
  "desativar": [
    { "pacote": "com.exemplo.telemetria", "descricao": "Telemetria do fabricante" }
  ],
  "remover": [
    { "pacote": "com.exemplo.assistente", "descricao": "Volta sozinho quando so desativado" }
  ],
  "opcionais": {
    "miracast":  [ { "pacote": "...", "descricao": "..." } ],
    "streaming": [ { "pacote": "...", "descricao": "..." } ]
  }
}
```

- `fabricantes` é opcional. Use quando o modelo tem um nome genérico, como `Smart_TV` nas TCL.
- **`desativar`**: `pm disable-user`. É a forma mais branda e a primeira escolha.
- **`remover`**: `pm uninstall -k --user 0`. Use para apps que o sistema reativa sozinho, ou que a Play Store reativa ao atualizar. O app continua no sistema e volta com `cmd package install-existing`.
- `launcherOriginal`: o pacote da tela inicial de fábrica. Ele aparece em `cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME`.

## 6.3 Como escolher o que entra

**Bons candidatos:**
- telemetria e estatísticas do fabricante;
- recomendações e canais promocionais;
- apps descontinuados (Play Filmes, Play Música);
- protetor de tela "ambiente";
- assistentes de terceiros, como a Alexa.

**Nunca coloque:**
- interface do sistema;
- configurações;
- entrada de TV/HDMI;
- serviços do controle remoto e do Bluetooth;
- Play Store e Google Play Services;
- WebView;
- teclado;
- instalador de pacotes;
- assistente de configuração.

A maioria desses itens já está em `perfis/protegidos.json`. Se o seu fabricante tiver algo essencial com outro nome, adicione lá.

**Dúvida sobre um pacote?** Deixe de fora. Atalho na tela de Apps nem sempre é o que parece: na TCL, por exemplo, o bloco "TCL HOME" vem do `com.tcl.dashboard`, e o "Quick panel" vem do `com.tcl.suspension`.

## 6.4 Testar

1. `.\Otimizar-TV.ps1 -Endereco ... -Perfil seu-perfil -Simular`
2. Aplique e teste o aparelho: Home, entradas HDMI, controle remoto, comando de voz e os apps que você usa.
3. Se algo quebrar, rode `.\Restaurar-TV.ps1 -Endereco ...`, tire o pacote do perfil e tente de novo.

Testou num aparelho novo? Abra um *pull request* com o perfil.
