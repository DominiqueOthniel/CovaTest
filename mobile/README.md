# CovaTask Mobile (bonus)

Application Flutter CovaTask consommant la meme API Spring Boot.

## Lancer

1. Demarrer le backend (local ou Railway)
2. Depuis `mobile/`:

```bash
flutter pub get
flutter run
```

Par defaut l URL API pointe vers `http://10.0.2.2:8080` (emulateur Android).

Pour Railway:

```text
API_BASE_URL=https://covatest-production.up.railway.app
```

Ou modifier `defaultValue` dans `lib/main.dart`.
