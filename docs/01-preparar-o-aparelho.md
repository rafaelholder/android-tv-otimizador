# 1. Preparar o aparelho

Os scripts conversam com a TV pelo **ADB pela rede**, por isso o aparelho precisa estar com a **Depuração USB** ligada. Não é preciso cabo USB nenhum: nesses aparelhos, a opção também libera a conexão pela rede, na porta 5555.

## 1.1 Liberar as Opções do desenvolvedor

O caminho muda um pouco conforme o sistema:

| Sistema | Caminho |
|---|---|
| **Android TV 9/10** (Mi TV Stick 1ª geração) | Configurações → Preferências do dispositivo → Sobre → **Build** |
| **Android TV 11** (TCL e outras TVs) | Configurações → Sistema → Sobre → **Build do SO do Android TV** |
| **Google TV** (Xiaomi TV Stick 4K e outros) | Configurações → Sistema → Sobre → **Build do SO do Android TV** |

Clique **7 vezes seguidas** na linha indicada até aparecer *"Agora você é um desenvolvedor!"*.

## 1.2 Ativar a Depuração USB

1. Volte um nível (Preferências do dispositivo ou Sistema). Agora aparece **Opções do desenvolvedor**.
2. Na seção **Depuração**, ative a **Depuração USB** e confirme com **OK**.
3. Se existir **"Depuração ADB pela rede"** ou **"Depuração pela rede"**, ative também.

> **Não tem "Depuração sem fio"?** É normal. A Depuração USB já abre a porta 5555 nesses aparelhos.

> **Ativou e mesmo assim não conecta?** Desligue e ligue a opção de novo, ou tire o aparelho da tomada por 10 segundos. Em vários sticks, a porta só abre depois disso.

## 1.3 Descobrir o IP do aparelho

Você tem duas opções:

- Pelo aparelho: **Configurações → Rede e Internet → (sua rede)**, campo *Endereço IP*.
- Pelo PC, com o script, que procura sozinho e mostra o nome de cada aparelho (ex.: "TV da sala"):
  ```powershell
  .\Procurar-TV.ps1
  ```

## 1.4 Rede: cuidados

- **O PC e a TV precisam se enxergar.** Se o PC está ligado num roteador que, por sua vez, está ligado no modem, os aparelhos podem estar em redes diferentes (por exemplo, `192.168.1.x` e `192.168.0.x`). Isso normalmente funciona, porque o PC consegue "sair" para a rede do modem. O `Procurar-TV.ps1` já testa as duas redes mais comuns.
- **VPN ligada no PC bloqueia a rede local.** Desconecte a VPN, ou ative a opção *"Permitir conexões LAN"* dela, enquanto usa os scripts.

## 1.5 Autorizar o PC

Na primeira conexão aparece na TV o aviso **"Permitir depuração USB?"**:

- Marque **"Sempre permitir deste computador"**.
- Escolha **OK**.

Se você aceitar e o script continuar dizendo que não foi autorizado, espere uns segundos: ele reconecta sozinho.

Próximo passo: [Instalar o ADB](02-instalar-adb.md)
