# Auditoria de arquitetura do Esculpo

Data da revisão: 2026-08-16

## Resumo

O aplicativo já possui boa parte das funções de um MVP, mas elas estão ligadas
diretamente às telas e a mapas dinâmicos. A migração deve ser incremental. As
telas existentes continuam ativas enquanto cada área ganha modelo, repositório
e estado próprios.

Os riscos de maior impacto encontrados foram:

1. O onboarding salvava a conclusão em
   `usuarios/{uid}/onboarding/data`, enquanto a entrada consultava
   `usuarios/{uid}.onboardingConcluido`. Isso podia repetir o onboarding.
2. A tela de login tentava cadastrar uma conta depois de senha incorreta.
3. Há 52 operações de navegação espalhadas pelas telas, sem contrato central.
4. Há duas estruturas para fotos: `fotosProgresso` e
   `usuarios/{uid}/fotos_progresso`.
5. Serviços e telas acessam Firebase diretamente, dificultando testes e mudança
   de esquema.
6. Treinos são transportados como `Map<String, dynamic>`, portanto erros de
   campo aparecem apenas em execução.
7. O volume atual soma apenas `cargaSugerida` por exercício. O volume correto é
   a soma de `carga x repetições` de cada série concluída.
8. Calorias usam fontes diferentes (`calorias`, `caloriasEstimadas` e uma
   aproximação por série), impedindo comparação consistente.
9. Providers estão duplicados para assinatura, anúncios, sugestões e imagem de
   perfil.
10. O shell com `IndexedStack` criava as quatro áreas principais. A etapa 1
    passou a criar cada aba somente na primeira visita.
11. O bundle inclui 16 imagens grandes de splash por meio de
    `assets/images/`. A remoção só deve ocorrer após confirmar quais assets ainda
    são usados.
12. Notificações usam o fuso fixo `Europe/Lisbon`; isso precisa ser substituído
    pelo fuso real do dispositivo numa etapa própria.

## Mapa de entrada e navegação

### Rotas centrais da arquitetura v2

| Rota | Destino | Observação |
| --- | --- | --- |
| `/` | `TelaSplash` | Entrada visual curta |
| `/auth` | `AuthGate` | Decide login, onboarding ou início |
| `/login` | `TelaLogin` | Login explícito |
| `/onboarding` | `TelaOnboarding` | Cadastro do perfil de treino |
| `/home` | `TelaInicial` | Shell principal |

As rotas `/tela_login`, `/tela_onboarding` e `/tela_inicial` são aliases
temporários para não quebrar chamadas antigas.

### Shell principal existente

`TelaInicial` contém quatro áreas:

| Aba | Tela | Responsabilidade atual |
| --- | --- | --- |
| Início | `TelaInicialContent` | treino do dia, calendário, sequência e métricas |
| Exercícios | `TelaExercicios` | catálogo e detalhe do exercício |
| Histórico | `TelaHistoricoTreinos` | sessões concluídas e agrupamentos |
| Perfil | `ProfileScreen` | perfil, planos, fotos, notificações e saída |

### Fluxos agregados

| Origem | Destinos |
| --- | --- |
| Início/calendário | detalhe do treino, treino ativo |
| Início/métricas | fotos de progresso |
| Exercícios | detalhe do exercício |
| Detalhe do treino | editar exercício, treino ativo |
| Treino ativo | detalhe do exercício, descanso, conclusão |
| Perfil | planos, fotos de progresso, notificações |
| Fotos | adicionar foto, detalhe, comparação |
| Medidas | registro e gráfico de peso/circunferências |

Dialogs e bottom sheets de confirmação, descanso e medidas continuam locais
por enquanto. Eles serão convertidos em componentes compartilhados quando o
respectivo fluxo for migrado.

## Sistemas e integrações

| Sistema | Implementação atual | Situação |
| --- | --- | --- |
| Autenticação | Firebase Auth | mantido; entrada centralizada na etapa 1 |
| Dados | Cloud Firestore | mantido; esquema precisa ser normalizado |
| Fotos | Firebase Storage + Image Picker | funcional, mas metadados têm dois caminhos |
| Push | Firebase Messaging | ativo |
| Alertas locais | flutter_local_notifications | ativo; rever fuso e permissões |
| Descanso | modal + timer + vibração | funcional, não persiste ao fechar/reabrir |
| Estado | Riverpod + estado local | manter Riverpod e reduzir duplicidades |
| Assinatura | In App Purchase | isolado parcialmente |
| Anúncios | Google Mobile Ads | dois providers/serviços |
| Gráficos | fl_chart | usado em histórico e medidas |
| Mídia | video/audio/webview | dependências pesadas; confirmar uso antes de remover |
| Gamificação | streak e pontos simples | ainda não existe catálogo persistente de medalhas |

## Dados atuais no Firestore

| Caminho | Uso |
| --- | --- |
| `usuarios/{uid}` | perfil resumido, assinatura, tokens, métricas simples |
| `usuarios/{uid}/onboarding/data` | respostas completas do onboarding |
| `usuarios/{uid}/planos_treino/personalized` | plano semanal gerado |
| `usuarios/{uid}/treinos/{dateId}` | agenda e progresso parcial |
| `usuarios/{uid}/historico_concluido/{id}` | sessões finalizadas |
| `usuarios/{uid}/medidas/{id}` | peso e circunferências |
| `exercicios/{id}` | catálogo global |
| `fotosProgresso/{id}` | fotos atuais com campo `usuarioId` |
| `usuarios/{uid}/fotos_progresso/{id}` | caminho antigo usado por um gráfico |

## O que já existia e deve ser reutilizado

- Onboarding com nome, nascimento, gênero, peso, altura, meta de peso,
  objetivo, experiência, frequência, atividade, equipamento, preferência,
  horário e restrições.
- Gerador de plano e agenda diária.
- Registro de carga e repetições por série.
- Timer de descanso, vibração e notificação de treino concluído.
- Histórico de treinos, medidas e fotos comparáveis.
- Sequência de dias, pontos básicos e compartilhamento.

Essas funções não devem ser reescritas todas de uma vez. Cada tela antiga será
conectada aos novos contratos antes de receber novo layout.

## Lacunas para o produto desejado

- Sugestão de treino ainda ignora parte de equipamento, rotina e restrições.
- Não há histórico de carga padronizado por exercício.
- Não há cálculo persistido de volume por exercício, sessão, semana e mês.
- Não há agregação consistente de calorias e duração.
- Não há metas mensuráveis com período e progresso.
- Medalhas são apenas apresentação condicional, sem regras versionadas.
- O treino ativo não retoma corretamente duração e descanso após interrupção.
- Não há camada de sincronização/offline explícita nem testes dos cálculos.

## Regra da migração

Nenhuma etapa remove uma tela, coleção ou dependência antes de:

1. existir um adaptador de leitura dos dados antigos;
2. a nova escrita estar validada;
3. o fluxo correspondente ter sido testado no Android e no iOS;
4. a etapa possuir um commit/arquivo de retorno independente.
