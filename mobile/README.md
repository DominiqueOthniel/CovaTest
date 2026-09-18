# CovaTask Mobile (bonus)

Application Flutter CovaTask alignee sur le frontend web (theme, auth, CRUD, filtres).
Consomme la meme API Spring Boot.

## Lancer

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

URL API par defaut : `https://covatest-production.up.railway.app`

Backend local (emulateur Android) :

```text
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```
