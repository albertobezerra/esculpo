# Plano incremental de reestruturação

## Arquitetura-alvo

```text
lib/
  app/                    # MaterialApp e composição global
  core/
    navigation/           # rotas e argumentos tipados
    theme/                # tokens visuais e temas
    widgets/              # estados de loading, erro e vazio
  features/
    auth/
      data/ domain/ presentation/
    onboarding/
      data/ domain/ presentation/
    workouts/
      data/ domain/ presentation/
    progress/
      data/ domain/ presentation/
    goals/
      data/ domain/ presentation/
    gamification/
      data/ domain/ presentation/
```

Arquivos em `screens/`, `widgets/` e `servicos/` permanecem como camada
legada. Eles serão movidos um fluxo por vez.

## Etapa 1 — fundação compatível

Status: implementada neste checkpoint.

- separar bootstrap, aplicativo, rotas e autenticação;
- manter aliases das rotas antigas;
- tornar login e cadastro ações explícitas;
- ler onboarding antigo e reparar automaticamente o indicador no usuário;
- gravar onboarding principal e legado no mesmo batch;
- carregar cada aba principal somente quando for visitada;
- manter nome do pacote e dependências atuais;
- não apagar nenhuma tela ou dado.

Critérios de aceite:

- usuário deslogado vê login depois da splash;
- senha errada não cria conta;
- novo cadastro segue para onboarding;
- usuário antigo com onboarding concluído entra no início;
- onboarding concluído não reaparece após novo login;
- logout limpa a pilha e retorna ao portão de autenticação.

## Etapa 2 — shell, design system e telas compartilhadas

- definir espaçamentos, raios, cores semânticas e tipografia;
- criar componentes de cabeçalho, card, botão, loading, erro e vazio;
- unificar linguagem em português do Brasil;
- migrar navegação das telas de perfil e progresso para rotas centrais;
- medir tamanho dos assets e explicitar no `pubspec` somente os usados.

## Etapa 3 — domínio de treino

- criar modelos tipados `WorkoutPlan`, `WorkoutDay`, `WorkoutExercise`,
  `WorkoutSet` e `WorkoutSession`;
- adicionar repositório que leia o formato atual e escreva versão 2;
- corrigir o split para respeitar exatamente a frequência semanal;
- usar objetivo, experiência, equipamento, rotina e restrições na sugestão;
- definir dias de descanso e permitir regeneração controlada do plano.

Critério importante: o plano `personalized` atual continua legível até todos os
usuários serem migrados.

## Etapa 4 — execução e progressão

- edição direta de carga/repetições na lista de séries;
- mostrar última carga e últimas sessões do exercício;
- sugerir progressão sem alterar automaticamente o registro;
- persistir sessão ativa, tempo iniciado, pausa e descanso;
- retomar treino após fechar o app;
- calcular `volume = soma(carga x repetições)` de séries concluídas;
- registrar estimativa de calorias com algoritmo e versão explícitos;
- mostrar progresso do exercício e da sessão.

## Etapa 5 — evolução corporal

- unificar metadados de fotos em `usuarios/{uid}/progress_photos`;
- manter leitura de `fotosProgresso` durante a transição;
- juntar peso, medidas e fotos numa única linha do tempo;
- comparação lado a lado por data;
- indicadores por exercício, dia, semana e mês.

## Etapa 6 — metas, gamificação e medalhas

- metas com tipo, valor-alvo, período e estado;
- pontos derivados de eventos reais e idempotentes;
- catálogo versionado de medalhas;
- medalhas para primeira sessão, consistência, volume, recordes e metas;
- tela de conquistas com progresso para a próxima recompensa;
- evitar recompensas baseadas em peso corporal ou práticas inseguras.

## Etapa 7 — qualidade e leveza

- testes unitários para volume, progressão, frequência, streak e medalhas;
- testes de widgets dos fluxos críticos;
- índices e regras do Firestore revisados;
- remover providers, serviços, pacotes e assets duplicados somente após uso zero;
- medir APK/AAB, tempo de abertura, memória e leituras do Firestore;
- validar acessibilidade, contraste, tamanhos de toque e textos responsivos.

## Ordem segura de entrega

Cada etapa deve ser entregue como um ZIP apenas com os arquivos alterados,
acompanhado de checksum e teste de integridade. A aplicação ocorre sempre na
raiz do projeto, uma etapa por vez, e somente depois do teste local começa a
etapa seguinte.
