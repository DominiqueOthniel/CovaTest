# Deploiement Railway (alternative a GCP)

## Pourquoi Railway
Google Cloud refuse souvent les cartes prepayees. Railway permet de deployer
le meme stack (Spring Boot + React) avec une URL publique partagee web/mobile.

## Etapes console

1. Cree un compte sur https://railway.app (GitHub login recommande)
2. New Project → Deploy from GitHub repo → choisis `CovaTest` (ou ton repo)
3. Dans le projet, cree **2 services** depuis le meme repo:

### Service backend
- Root Directory: `backend`
- Builder: Dockerfile
- Variables:
  - `SPRING_PROFILES_ACTIVE` = `dev`
  - `JWT_SECRET` = une longue chaine secrete
- Generate Domain (Settings → Networking)

Copie l URL publique backend, ex:
`https://taskmanager-backend-production-xxxx.up.railway.app`

### Service frontend
- Root Directory: `frontend`
- Builder: Dockerfile
- Variables de **build**:
  - `VITE_API_URL` = URL backend (sans slash final)
- Generate Domain

Ouvre l URL frontend → inscris-toi → cree une tache.

## Flutter / APK (meme backend)

Dans `mobile/lib/main.dart`, la constante pointe deja vers le backend local.
Pour l APK, lance avec l URL Railway:

```text
API_BASE_URL = https://TON-BACKEND.up.railway.app
```

Ou modifie `defaultValue` dans `main.dart` avant le build release.

## Note pour le jury
Le sujet demandait GCP Cloud Run. Le deploiement GCP est prepare
(`scripts/deploy-gcp.ps1`) mais bloque par le moyen de paiement (cartes prepayees refusees).
Railway sert d alternative PaaS equivalente pour la demo live.
