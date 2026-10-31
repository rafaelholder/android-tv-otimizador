# 5. Restaurar e desligar a depuração

## Desligar a Depuração USB (faça sempre ao terminar)

Com a depuração ligada, qualquer computador que você autorizar consegue controlar a TV pela rede.

```powershell
.\Desligar-Depuracao.ps1 -Endereco 192.168.1.50
```

O script desliga a opção e testa se a porta 5555 fechou. Em alguns firmwares, como o do Xiaomi TV Stick 4K, a porta só fecha depois de reiniciar. Nesses casos o script reinicia o aparelho sozinho.

Pelo controle remoto: **Opções do desenvolvedor → Depuração USB → desativar**.

> Os ajustes continuam valendo com a depuração desligada. Para mexer de novo, é só religar.

## Desfazer a otimização

Religue a Depuração USB e rode:

```powershell
.\Restaurar-TV.ps1 -Endereco 192.168.1.50
```

O script usa o backup mais recente desse aparelho, que fica em `backups\`, e:

- reativa os apps desativados;
- reinstala para o usuário os apps removidos (`cmd package install-existing`);
- reativa o launcher original, se ele foi trocado;
- volta as animações e o protetor de tela para os valores de antes.

Se o IP do aparelho mudou, o script usa o backup mais recente do mesmo modelo. Também dá para escolher o arquivo:

```powershell
.\Restaurar-TV.ps1 -Endereco 192.168.1.50 -Backup ..\backups\MiTV-AESP0_192-168-1-50-5555_20261031-010203.json
```

### O que desfazer pelo controle remoto

| Ajuste | Como voltar |
|---|---|
| Uso e diagnóstico | Ativar de novo na mesma tela |
| ID de publicidade | Privacidade → Anúncios → **Criar novo ID de publicidade** |
| Modo somente apps | Contas e perfis → (conta) → Modo somente apps → Desativar |
| Apps removidos de vez (instalados por você) | Reinstalar pela Play Store |

### Depois do `Limpar-Armazenamento.ps1`

Os apps limpos voltaram para a versão de fábrica e sem dados. Se você reativar um deles, ele abre "zerado" e a Play Store atualiza sozinha.

## Reset de fábrica

O reset de fábrica (**Configurações → Sistema/Preferências do dispositivo → Redefinir**) volta **tudo** ao original, inclusive os apps de fábrica. Ele também apaga seus apps e logins.

## Atualizações de sistema

Nos testes, uma atualização de sistema (OTA) manteve apps desativados, apps removidos, protetor de tela, privacidade e Modo somente apps. Só as **animações voltaram para 1x**. Depois de atualizar, rode o `Otimizar-TV.ps1` de novo: ele pula o que já está feito e reaplica o resto.
