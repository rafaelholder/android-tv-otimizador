# 4. Ajustes manuais (pelo controle remoto)

Estes ajustes ficam em telas do Google e do fabricante, e não existe comando ADB confiável para eles. Leva uns 5 minutos.

## Uso e diagnóstico

Desliga o envio automático de dados de uso ao Google.

| Sistema | Caminho |
|---|---|
| Android TV 9/10 | Configurações → Preferências do dispositivo → **Uso e diagnóstico** → desativar |
| Android TV 11 / Google TV | Configurações → Privacidade → **Uso e diagnósticos** → desativar |

## Anúncios personalizados (ID de publicidade)

1. Abra **Configurações → Privacidade → Anúncios**. No Android TV 9/10 o caminho é **Configurações → Preferências do dispositivo → Sobre → Anúncios** ou **Contas e login → Google → Anúncios**, conforme o firmware.
2. Escolha **Excluir o ID de publicidade** e confirme.

Nas versões novas, isso substitui a antiga opção "Desativar personalização de anúncios". Para voltar atrás, use **Criar novo ID de publicidade** na mesma tela.

> Se o foco cair no link *"Saiba mais"*, uma página de ajuda abre. Volte e suba com as setas até a opção certa.

## Modo somente apps (Google TV)

Esconde as abas de filmes e séries e as recomendações. A tela inicial fica bem mais leve, sem precisar trocar de launcher.

1. Abra **Configurações → Contas e perfis → (sua conta)**.
2. Desça até **Modo somente apps** e escolha **Ativar**.

> Nesse modo, a **Pesquisa e os comandos de voz ficam desativados**. Para desfazer, volte no mesmo lugar.

## Projectivy Launcher no modo mais leve

Para abrir as configurações do Projectivy, use a engrenagem no canto superior da tela inicial e depois **Configurações de Projectivy**.

| Onde | Ajuste | Por quê |
|---|---|---|
| Aparência → **Fundo** → Papel de parede do launcher | **Nenhum** | O padrão baixa dezenas de imagens do Reddit e troca entre elas com efeito de zoom |
| Aparência → **Cartões** → Limite de repetição de ícones animados | **0** | Os ícones animados param de repetir sem fim |
| Aparência → **Cartões** → Efeito ondulatório ao pressionar | **Desativado** | É uma animação a menos |
| Aparência → Cartões → **Cartão focado** → Animação de brilho | **Nenhum** | O "pulso" padrão fica animando o tempo todo |
| Aparência → Cartões → **Cartão focado** → Efeito do cartão em foco | **Nenhum** | Sem brilho nem sombra: o cartão selecionado só aumenta de tamanho |
| Aparência → **Carregar cartões ao rolar** | **Ativado** | A rolagem responde mais rápido |

> Usar uma **imagem própria** como fundo exige a versão Premium (paga) do Projectivy. O fundo "Nenhum" é o mais leve.

## TVs TCL: privacidade

Em **Configurações → Privacidade** (ou nos termos da TCL), desative os itens de **informações de visualização / reconhecimento de conteúdo (ACR)**, se existirem no seu modelo.

Próximo passo: [Restaurar e desligar a depuração](05-restaurar-e-desligar.md)
