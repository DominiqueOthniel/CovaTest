# Deploiement Cloud Run (sans Docker local)
# Prerequis: Google Cloud SDK (gcloud) + projet GCP avec facturation

$ErrorActionPreference = "Stop"

$gcloudCmd = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $gcloudCmd) {
  $candidate = Join-Path $env:LOCALAPPDATA "Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
  if (Test-Path $candidate) {
    $env:Path = "$(Split-Path $candidate -Parent);$env:Path"
  } else {
    Write-Host "gcloud introuvable. Rouvre le terminal apres installation du Cloud SDK."
    exit 1
  }
}

$ProjectId = $env:GCP_PROJECT_ID
$Region = if ($env:GCP_REGION) { $env:GCP_REGION } else { "europe-west1" }
$Repo = "taskmanager"

if (-not $ProjectId) {
  Write-Host "Definissez GCP_PROJECT_ID avant de lancer ce script."
  Write-Host 'Exemple: $env:GCP_PROJECT_ID = "mon-projet-gcp"'
  exit 1
}

Write-Host "Projet: $ProjectId | Region: $Region"

gcloud config set project $ProjectId

Write-Host "Activation des APIs..."
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com

$RepoCheck = gcloud artifacts repositories describe $Repo --location=$Region 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Creation Artifact Registry..."
  gcloud artifacts repositories create $Repo --repository-format=docker --location=$Region --description="Task Manager images"
}

$BackendImage = "$Region-docker.pkg.dev/$ProjectId/$Repo/backend:latest"
$FrontendImage = "$Region-docker.pkg.dev/$ProjectId/$Repo/frontend:latest"

Write-Host "Build backend (Cloud Build)..."
Set-Location "$PSScriptRoot\..\backend"
gcloud builds submit --tag $BackendImage
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Deploy backend Cloud Run..."
gcloud run deploy taskmanager-backend `
  --image $BackendImage `
  --region $Region `
  --platform managed `
  --allow-unauthenticated `
  --port 8080 `
  --memory 512Mi `
  --set-env-vars "SPRING_PROFILES_ACTIVE=dev,JWT_SECRET=TaskManagerCloudRunSecretKeyMustBeLongEnough123"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$BackendUrl = gcloud run services describe taskmanager-backend --region $Region --format="value(status.url)"
Write-Host "Backend URL: $BackendUrl"

Write-Host "Build frontend (Cloud Build)..."
Set-Location "$PSScriptRoot\..\frontend"
gcloud builds submit --config cloudbuild.cloudrun.yaml --substitutions="_BACKEND_URL=$BackendUrl,_REGION=$Region"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Deploy frontend Cloud Run..."
gcloud run deploy taskmanager-frontend `
  --image $FrontendImage `
  --region $Region `
  --platform managed `
  --allow-unauthenticated `
  --port 8080 `
  --memory 256Mi
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$FrontendUrl = gcloud run services describe taskmanager-frontend --region $Region --format="value(status.url)"
Write-Host ""
Write-Host "Deploiement termine."
Write-Host "Frontend: $FrontendUrl"
Write-Host "Backend : $BackendUrl"
