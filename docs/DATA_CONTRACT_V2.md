# Contrato de dados v2

Este documento define o destino da migração. Apenas o perfil/onboarding começa
a escrever `schemaVersion: 2` na etapa 1. Os outros contratos ainda não devem
ser produzidos até sua respectiva etapa.

## Perfil e onboarding

```text
usuarios/{uid}
  nome
  peso
  altura
  metaPeso
  objetivo
  frequencia
  imc
  onboardingConcluido
  schemaVersion: 2
  updatedAt

usuarios/{uid}/onboarding/data
  ...respostas completas atuais
  onboardingConcluido
  schemaVersion: 2
  updatedAt
```

A escrita é atômica por batch. A leitura consulta primeiro o documento do
usuário e usa a subcoleção como fallback para contas antigas.

## Destino proposto para treino

```text
usuarios/{uid}/workout_plans/{planId}
usuarios/{uid}/workout_schedule/{yyyy-MM-dd}
usuarios/{uid}/workout_sessions/{sessionId}
usuarios/{uid}/exercise_progress/{exerciseId}/entries/{entryId}
```

Uma sessão deve guardar pelo menos:

- `planId`, `workoutDayId`, início, fim, duração e status;
- exercícios com identificador estável;
- séries planejadas e executadas;
- carga, repetições e instante de conclusão de cada série;
- volume total e por exercício;
- calorias estimadas e versão do algoritmo;
- `schemaVersion`.

## Destino proposto para evolução

```text
usuarios/{uid}/body_measurements/{id}
usuarios/{uid}/progress_photos/{id}
```

Fotos devem guardar `storagePath`, `downloadUrl`, data, peso opcional, medidas
opcionais, observações e pose/categoria opcional. A exclusão deve usar o
`storagePath`, evitando depender da análise da URL.

## Destino proposto para metas e medalhas

```text
usuarios/{uid}/goals/{goalId}
usuarios/{uid}/achievements/{achievementId}
usuarios/{uid}/point_events/{eventId}
```

Eventos de pontos devem ter identificador idempotente ligado à sessão. Assim,
reabrir ou sincronizar um treino não concede pontos duas vezes.
