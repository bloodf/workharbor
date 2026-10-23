<p align="center"><img src="images/banner-pt-BR.png" alt="WorkHarbor — Suas agendas. Em sintonia." /></p>

[English](../README.md) · Português · [Español](README.es.md)

# WorkHarbor

Um lugar tranquilo para suas agendas, direto na barra de menu do macOS.

Veja próximos eventos e sincronize as agendas já configuradas no Calendário da Apple. Sem e-mail, navegador embutido, contas de IA ou senhas adicionais.

> **Prévia em desenvolvimento.** Não é uma versão de produção notarizada. Testes sintéticos não comprovam compatibilidade com todos os provedores. Revise as alterações antes de autorizar sincronização automática.

## Uma prévia do menu

<p align="center"><img src="images/agenda-pt-BR-light.png" width="320" alt="WorkHarbor light" /> <img src="images/agenda-pt-BR-dark.png" width="320" alt="WorkHarbor dark" /></p>

Interface nativa renderizada no macOS com eventos fictícios. Nenhum dado privado de agenda.

## O essencial, bem perto

- Menu nativo SwiftUI com eventos futuros, cores por agenda, eventos em andamento e grupos por dia.
- Janela separada apenas para configurações.
- Cópias **Busy** que compartilham somente horários, com intervalos opcionais antes e depois.
- Cópias com detalhes completos quando você autoriza compartilhar títulos, notas e locais.
- Automação por regra, vinculada à origem, destino, modo e intervalos aprovados.
- Limpeza revisável de duplicatas identificadas, preservando a cópia rastreada atualizada.
- Interface em inglês, português brasileiro e espanhol.

## Funcionamento

As contas do Calendário da Apple fazem a sincronização com seus provedores. O WorkHarbor usa o EventKit e precisa de uma permissão própria de acesso. Restrições de conta e agendas somente leitura continuam valendo.

O menu mostra os próximos sete dias, até 80 eventos. A sincronização considera 30 dias anteriores e 180 futuros. Funciona com o aplicativo aberto e o Mac acordado, incluindo verificações após despertar e alterações no calendário. Não funciona como serviço na nuvem nem garante entrega remota imediata.

## Proteções importantes

Cópias recebem identificação do WorkHarbor e são rastreadas localmente. Título igual não comprova que um evento pertence ao aplicativo.

Uma origem ausente não é interpretada como exclusão. A sincronização em segundo plano nunca exclui eventos. A limpeza exige cópia rastreada atualizada, seleção e confirmação; não tenta adivinhar a identidade de eventos sem marcador, de outra instalação ou sem correspondência.

Ciclos, caminhos redundantes e encadeamento a partir de destinos Busy são bloqueados. Um registro persistente impede repetir gravações cujo resultado é incerto. Não apague esse registro para forçar uma nova tentativa.

A migração preserva IDs, regras e inventário. Dados e credenciais dos antigos recursos de e-mail não são carregados nem apagados pela edição de calendários.

## Compilar

macOS 14 ou superior e ferramentas Xcode/Swift 6. Sem dependências Swift externas.

```sh
./scripts/test.sh
./scripts/build-app.sh
```

O script cria aplicativo e ZIP em `dist/`, com assinatura ad hoc local, não notarização Apple. Saia da versão anterior antes de abrir outra. Não ignore avisos de segurança para executar downloads não confiáveis.

## Privacidade e estado do projeto

Sem analytics, leitura de e-mail, endpoint de IA ou servidor próprio de calendários. O macOS pode transmitir cópias aos provedores das contas de destino escolhidas. Regras de detalhes incluem títulos, notas e locais; Busy não.

Não publique eventos privados, exportações de agenda, identificadores de contas ou segredos nos relatos de problemas. Use exemplos fictícios.

O redesign está em validação. Integração com provedores, fusos e acessibilidade precisam de testes contínuos. Artes promocionais são ilustrações, não comprovantes de funcionalidades em execução.

A licença ainda não foi escolhida. Não há licença de redistribuição implícita.
