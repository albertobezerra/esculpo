# Como aplicar a etapa 1

Este pacote contém somente arquivos novos ou alterados. Ele não é um projeto
completo e não deve ser extraído como um aplicativo separado.

1. Faça uma cópia da pasta atual do Esculpo.
2. Extraia o ZIP da etapa 1 na raiz do projeto, onde está o `pubspec.yaml`.
3. Permita substituir os arquivos com o mesmo nome.
4. Nenhum arquivo existente precisa ser apagado manualmente.
5. Execute:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Teste manual mínimo

1. Abra o app e confirme a splash curta.
2. Tente entrar com senha errada e confirme que nenhuma conta é criada.
3. Troque para “Quero criar uma conta” e cadastre um usuário de teste.
4. Conclua o onboarding e confirme a entrada na tela inicial.
5. Feche, abra novamente e confirme que o onboarding não se repete.
6. Abra uma vez cada aba e confirme que o conteúdo aparece normalmente.
7. Saia pelo perfil e confirme o retorno para o login.

## Arquivos substituídos

- `README.md`
- `lib/main.dart`
- `lib/screens/tela_splash.dart`
- `lib/screens/tela_login.dart`
- `lib/screens/tela_onboarding.dart`
- `lib/screens/tela_inicial.dart`
- `lib/screens/perfil/profile_screen.dart`
- `test/widget_test.dart`

## Pastas/arquivos adicionados

- `lib/app/esculpo_app.dart`
- `lib/core/navigation/app_route_names.dart`
- `lib/core/navigation/app_routes.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/presentation/auth_gate.dart`
- `lib/features/onboarding/data/onboarding_repository.dart`
- `lib/features/onboarding/domain/onboarding_profile.dart`
- `docs/ARCHITECTURE_AUDIT.md`
- `docs/MIGRATION_PLAN.md`
- `docs/DATA_CONTRACT_V2.md`
- `docs/ETAPA_1_APLICACAO.md`

## Retorno

Se a etapa falhar, restaure somente os oito arquivos substituídos usando a
cópia feita no passo 1. Os arquivos adicionados podem permanecer sem afetar o
projeto antigo, pois só são referenciados pelos arquivos substituídos.
