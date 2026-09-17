# Deploiement Railway (alternative a GCP)

## Backend live
API: https://covatest-production.up.railway.app  
Health: https://covatest-production.up.railway.app/api/health

## Pourquoi Railway
Google Cloud refuse souvent les cartes prepayees. Railway permet de deployer
le meme stack (Spring Boot + React + MySQL) avec une URL publique partagee web/mobile.

## Backend (deja deploye)
- Dockerfile racine du repo
- Domain public genere (port 8080)
- Variables minimales avant MySQL: `SPRING_PROFILES_ACTIVE=dev`, `JWT_SECRET=...`

## Ajouter MySQL (requis pour coller au sujet)

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

## Frontend

1. **+ New** → GitHub repo (meme repo)
2. Settings:
   - Root Directory: `frontend`
   - Builder: Dockerfile
   - Dockerfile path: `Dockerfile`
3. Variables:
   - `VITE_API_URL` = `https://covatest-production.up.railway.app`
4. Generate Domain (port 3000 si demande)
5. Ouvre l URL frontend

Si le builder frontend echoue, utilise le Dockerfile racine alternatif:
- Dockerfile path: `Dockerfile.frontend`
- Root Directory: vide
- Variable: `VITE_API_URL`

## Flutter / APK (meme backend)

```text
API_BASE_URL=https://covatest-production.up.railway.app
```

## Note pour le jury
Le sujet demandait GCP Cloud Run. Le deploiement GCP est prepare
(`scripts/deploy-gcp.ps1`) mais bloque par le moyen de paiement (cartes prepayees refusees).
Railway sert d alternative PaaS equivalente pour la demo live.
