# Deploiement Railway (alternative a GCP)

## Demo live

- Web: https://covatask.up.railway.app/login
- API: https://covatest-production.up.railway.app
- Health: https://covatest-production.up.railway.app/api/health

## Pourquoi Railway
Google Cloud refuse les cartes prepayees et accepte que les cartes credit ou debit pour utiliser la version gratuite , chose que je n'ai pas. Railway permet de deployer
le meme stack (Spring Boot + React + MySQL) avec une URL publique partagee web/mobile.

## Backend (deja deploye)
- Dockerfile racine du repo
- Domain public genere (port 8080)
- Profil `mysql` + variables MySQL Railway
- `JWT_SECRET` en variable d environnement

## MySQL

1. Projet Railway → **+ New** → **Database** → **MySQL**
2. Service backend → **Variables** → **Add Variable Reference** depuis MySQL:
   - `MYSQLHOST` (ou `MYSQL_HOST`)
   - `MYSQLPORT` (ou `MYSQL_PORT`)
   - `MYSQLDATABASE` (ou `MYSQL_DATABASE`)
   - `MYSQLUSER` (ou `MYSQL_USER`)
   - `MYSQLPASSWORD` (ou `MYSQL_PASSWORD`)
3. Mets `SPRING_PROFILES_ACTIVE` = `mysql`
4. Redeploy le backend
5. Reteste `/api/health` puis inscription

## Frontend (deja deploye)

- URL: https://covatask.up.railway.app
- Root Directory: `frontend`
- Variable `VITE_API_URL` = `https://covatest-production.up.railway.app`

Si le builder frontend echoue, utilise `Dockerfile.frontend` a la racine du repo.

## Flutter / APK (meme backend)

URL deja configuree par defaut dans `mobile/lib/api/api_client.dart`:

```text
API_BASE_URL=https://covatest-production.up.railway.app
```

## Note pour le jury
Le sujet demandait GCP Cloud Run. Le deploiement GCP est prepare
(`scripts/deploy-gcp.ps1`) mais bloque par le moyen de paiement (cartes prepayees refusees).
Railway sert d alternative PaaS equivalente pour la demo live.
