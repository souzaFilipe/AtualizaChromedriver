# Script PowerShell para consultar e baixar a vers�o mais recente do ChromeDriver compat�vel com a vers�o do Google Chrome instalada

# Obtem todos os processos do ChromeDriver em execu��o
$processos = Get-Process chromedriver -ErrorAction SilentlyContinue
$numeroDeProcessos = $processos.Count

# Encerra todos os processos do ChromeDriver
$processos | Stop-Process -Force

# Exibe uma mensagem no console com o n�mero de processos encerrados
Write-Host "$numeroDeProcessos processos do ChromeDriver encerrados."

# Obt�m a vers�o principal do Google Chrome instalado
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-Not (Test-Path $chromePath)) {
    Write-Host "Chrome n�o encontrado no caminho especificado: $chromePath"
    exit
}
$chromeVersionInfo = (Get-Item $chromePath).VersionInfo
$chromeVersion = $chromeVersionInfo.ProductVersion
$chromeMainVersion = $chromeVersion.Split('.')[0]
Write-Host "Vers�o do Google Chrome identificada: $chromeVersion (Vers�o principal: $chromeMainVersion)"

# Consulta a vers�o mais recente do ChromeDriver para a vers�o principal do Chrome
$latestDriverVersionUrl = "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$chromeMainVersion"
Write-Host "Consultando a vers�o mais recente do ChromeDriver para a vers�o do Chrome: $chromeMainVersion"
try {
    $latestDriverVersion = Invoke-RestMethod -Uri $latestDriverVersionUrl
    Write-Host "Vers�o mais recente do ChromeDriver dispon�vel: $latestDriverVersion"
} catch {
    Write-Host "N�o foi poss�vel obter a vers�o mais recente do ChromeDriver para a vers�o do Chrome: $chromeMainVersion"
    exit
}

# Monta a URL de download do ChromeDriver com a vers�o obtida
$downloadUrl = "https://storage.googleapis.com/chrome-for-testing-public/$latestDriverVersion/win64/chromedriver-win64.zip"
Write-Host "URL de download do ChromeDriver: $downloadUrl"

# Define o diret�rio iglobal_local no diret�rio do usu�rio
$userDir = [Environment]::GetFolderPath('UserProfile')
$driverDir = Join-Path -Path $userDir -ChildPath "iglobal_local"

# Verifica e cria o diret�rio iglobal_local, se necess�rio
if (-Not (Test-Path $driverDir)) {
    New-Item -Path $driverDir -ItemType Directory
    Write-Host "Diret�rio iglobal_local criado em: $driverDir"
}

# Remove o ChromeDriver existente
$existingDriverPath = Join-Path -Path $driverDir -ChildPath "chromedriver.exe"
if (Test-Path $existingDriverPath) {
    Remove-Item -Path $existingDriverPath -Force
    Write-Host "Vers�o anterior do ChromeDriver removida."
}

# Define o caminho para o arquivo zip de download
$zipPath = Join-Path -Path $driverDir -ChildPath "chromedriver.zip"

# Prepara o diret�rio para a extra��o
$tempExtractionPath = Join-Path -Path $driverDir -ChildPath "temp_extraction"
New-Item -Path $tempExtractionPath -ItemType Directory -Force | Out-Null
Write-Host "Diret�rio tempor�rio para extra��o criado: $tempExtractionPath"

# Faz o download do ChromeDriver
Write-Host "Iniciando o download do ChromeDriver..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
Write-Host "Download do ChromeDriver conclu�do."

try {
    # Extrai o arquivo zip
    Write-Host "Iniciando a extra��o do ChromeDriver..."
    Expand-Archive -Path $zipPath -DestinationPath $tempExtractionPath -Force
    Write-Host "ChromeDriver extra�do para o diret�rio tempor�rio."

    # Verifica se h� subdiret�rios e move os arquivos corretamente
    $subDirectories = Get-ChildItem -Path $tempExtractionPath -Directory
    if ($subDirectories.Count -gt 0) {
        foreach ($subDir in $subDirectories) {
            Get-ChildItem -Path $subDir.FullName -File | ForEach-Object {
                $destPath = Join-Path -Path $driverDir -ChildPath $_.Name
                Move-Item -Path $_.FullName -Destination $destPath -Force
                Write-Host "Arquivo `"$($_.Name)`" movido para: $destPath"
            }
        }
    } else {
        Get-ChildItem -Path $tempExtractionPath -File | ForEach-Object {
            $destPath = Join-Path -Path $driverDir -ChildPath $_.Name
            Move-Item -Path $_.FullName -Destination $destPath -Force
            Write-Host "Arquivo `"$($_.Name)`" movido para: $destPath"
        }
    }

    Write-Host "ChromeDriver movido para: $driverDir"
} catch {
    Write-Host "Erro ao extrair ou mover o ChromeDriver: $_"
} finally {
    # Limpeza p�s-extra��o
    Remove-Item -Path $tempExtractionPath -Recurse -ErrorAction SilentlyContinue
    Write-Host "Diret�rio tempor�rio removido: $tempExtractionPath"

    # Sempre remove o arquivo ZIP, independentemente de sucesso ou falha
    Remove-Item -Path $zipPath -ErrorAction SilentlyContinue
    Write-Host "Arquivo ZIP do ChromeDriver removido: $zipPath"
}

Write-Host "Instala��o do ChromeDriver vers�o $latestDriverVersion completada com sucesso."

