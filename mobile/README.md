# Task Manager Mobile (bonus)

Application Flutter minimale consommant la meme API Spring Boot.

## Lancer

1. Demarrer le backend sur le port 8080
2. Depuis `mobile/`:

```bash
flutter pub get
flutter run
```

Par defaut l URL API pointe vers `http://10.0.2.2:8080` (emulateur Android).

Pour un autre host, modifier la constante `apiBaseUrl` dans `lib/main.dart`.
