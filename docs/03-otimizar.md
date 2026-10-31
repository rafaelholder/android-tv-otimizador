# 3. Otimizar

## 3.1 Abrir o PowerShell na pasta dos scripts

No Explorer, abra a pasta `scripts` do projeto. Depois clique na barra de endereço, digite `powershell` e aperte Enter.

Se o projeto foi baixado como ZIP, o Windows marca os arquivos como "vindos da internet". Desbloqueie uma vez:

```powershell
Get-ChildItem -Recurse .. | Unblock-File
```

## 3.2 Simular primeiro

```powershell
.\Otimizar-TV.ps1 -Endereco 192.168.1.50 -Simular
```

O script conecta, identifica o modelo, escolhe o perfil e mostra uma tabela com o que faria. Para cada pacote, a coluna **Situação** diz o que vai acontecer:

| Situação | Significado |
|---|---|
| `aplicar` | Vai ser desativado ou removido |
| `ja desativado` | Já estava assim |
| `nao existe aqui` | O pacote não existe neste firmware |
| `protegido (ignorado)` | Está na lista de protegidos e nunca é tocado |
| `mantido (-Manter)` | Você pediu para não mexer |

Se algum app da lista é usado na sua casa, rode de novo com `-Manter`:

```powershell
.\Otimizar-TV.ps1 -Endereco 192.168.1.50 -Simular -Manter com.google.android.youtube.tvmusic
```

## 3.3 Aplicar

```powershell
.\Otimizar-TV.ps1 -Endereco 192.168.1.50
```

O script faz as etapas nesta ordem:

1. Pede confirmação.
2. Salva o backup em `backups\<modelo>_<ip>_<data>.json`.
3. Coloca as animações em 0,5x e o protetor de tela em *Cores*.
4. Desativa e remove do usuário os pacotes do plano.
5. Espera 20 segundos e confere se o sistema reativou algum app. Se reativou, remove esse app do usuário. Isso acontece, por exemplo, com a Alexa nas TCL e com o Text-to-Speech depois de uma atualização da Play Store.
6. Mostra um resumo e a RAM livre.

### Opções úteis

```powershell
# Também desativa Miracast e os apps de streaming opcionais do perfil
.\Otimizar-TV.ps1 -Endereco 192.168.1.50 -IncluirMiracast -IncluirStreaming

# Troca o launcher pelo Projectivy e desliga a depuração no final
.\Otimizar-TV.ps1 -Endereco 192.168.1.50 -TrocarLauncher -DesligarDepuracao
```

## 3.4 Trocar o launcher (opcional, recomendado em aparelhos com 1 GB de RAM)

Com `-TrocarLauncher`:

1. Se o Projectivy não estiver instalado, o script abre a página dele na Play Store da TV. Clique em **Instalar**.
   - O aparelho precisa ter uma **conta Google**. Se a Play Store pedir login, entre pela TV.
2. Depois de instalado, o script desativa o launcher original e aperta *Home*.
3. Se a tela inicial abrir o Projectivy, ótimo. Se não abrir, **o original é reativado na hora**.
4. Na TV, passe pelas telas de boas-vindas do Projectivy.

No **Google TV**, uma alternativa sem trocar o launcher é o **Modo somente apps** ([ajustes manuais](04-ajustes-manuais.md#modo-somente-apps-google-tv)).

## 3.5 Liberar armazenamento (opcional)

```powershell
.\Limpar-Armazenamento.ps1 -Endereco 192.168.1.50 -Simular
.\Limpar-Armazenamento.ps1 -Endereco 192.168.1.50
```

O que esse script faz:

- Mostra os apps que mais ocupam espaço.
- Nos apps **já desativados**:
  - remove as atualizações que a Play Store instalou, voltando para a versão de fábrica;
  - apaga os dados que eles deixaram;
  - desativa de novo, porque remover a atualização reativa o app.
- Lista os arquivos da pasta Download, sem apagar nada.

Para garantir que um app nunca seja tocado, use `-Preservar com.exemplo.app`.

> **Cache dos apps que você usa:** sem root, o Android só deixa limpar o cache de um app específico pela tela **Configurações → Apps → (app) → Limpar cache**. O Google Play Services costuma acumular centenas de MB de cache, e limpar não desconecta a conta.

Próximo passo: [Ajustes manuais](04-ajustes-manuais.md)
