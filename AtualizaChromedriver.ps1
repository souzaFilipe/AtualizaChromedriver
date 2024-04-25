# Script PowerShell para consultar e baixar a versão mais recente do ChromeDriver compatível com a versão do Google Chrome instalada

# Obtem todos os processos do ChromeDriver em execução
$processos = Get-Process chromedriver -ErrorAction SilentlyContinue
$numeroDeProcessos = $processos.Count

# Encerra todos os processos do ChromeDriver
$processos | Stop-Process -Force

# Exibe uma mensagem no console com o número de processos encerrados
Write-Host "$numeroDeProcessos processos do ChromeDriver encerrados."

# Obtém a versão principal do Google Chrome instalado
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-Not (Test-Path $chromePath)) {
    Write-Host "Chrome não encontrado no caminho especificado: $chromePath"
    exit
}
$chromeVersionInfo = (Get-Item $chromePath).VersionInfo
$chromeVersion = $chromeVersionInfo.ProductVersion
$chromeMainVersion = $chromeVersion.Split('.')[0]
Write-Host "Versão do Google Chrome identificada: $chromeVersion (Versão principal: $chromeMainVersion)"

# Consulta a versão mais recente do ChromeDriver para a versão principal do Chrome
$latestDriverVersionUrl = "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$chromeMainVersion"
Write-Host "Consultando a versão mais recente do ChromeDriver para a versão do Chrome: $chromeMainVersion"
try {
    $latestDriverVersion = Invoke-RestMethod -Uri $latestDriverVersionUrl
    Write-Host "Versão mais recente do ChromeDriver disponível: $latestDriverVersion"
} catch {
    Write-Host "Não foi possível obter a versão mais recente do ChromeDriver para a versão do Chrome: $chromeMainVersion"
    exit
}

# Monta a URL de download do ChromeDriver com a versão obtida
$downloadUrl = "https://storage.googleapis.com/chrome-for-testing-public/$latestDriverVersion/win64/chromedriver-win64.zip"
Write-Host "URL de download do ChromeDriver: $downloadUrl"

# Define o diretório iglobal_local no diretório do usuário
$userDir = [Environment]::GetFolderPath('UserProfile')
$driverDir = Join-Path -Path $userDir -ChildPath "iglobal_local"

# Verifica e cria o diretório iglobal_local, se necessário
if (-Not (Test-Path $driverDir)) {
    New-Item -Path $driverDir -ItemType Directory
    Write-Host "Diretório iglobal_local criado em: $driverDir"
}

# Remove o ChromeDriver existente
$existingDriverPath = Join-Path -Path $driverDir -ChildPath "chromedriver.exe"
if (Test-Path $existingDriverPath) {
    Remove-Item -Path $existingDriverPath -Force
    Write-Host "Versão anterior do ChromeDriver removida."
}

# Define o caminho para o arquivo zip de download
$zipPath = Join-Path -Path $driverDir -ChildPath "chromedriver.zip"

# Prepara o diretório para a extração
$tempExtractionPath = Join-Path -Path $driverDir -ChildPath "temp_extraction"
New-Item -Path $tempExtractionPath -ItemType Directory -Force | Out-Null
Write-Host "Diretório temporário para extração criado: $tempExtractionPath"

# Faz o download do ChromeDriver
Write-Host "Iniciando o download do ChromeDriver..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
Write-Host "Download do ChromeDriver concluído."

try {
    # Extrai o arquivo zip
    Write-Host "Iniciando a extração do ChromeDriver..."
    Expand-Archive -Path $zipPath -DestinationPath $tempExtractionPath -Force
    Write-Host "ChromeDriver extraído para o diretório temporário."

    # Verifica se há subdiretórios e move os arquivos corretamente
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
    # Limpeza pós-extração
    Remove-Item -Path $tempExtractionPath -Recurse -ErrorAction SilentlyContinue
    Write-Host "Diretório temporário removido: $tempExtractionPath"

    # Sempre remove o arquivo ZIP, independentemente de sucesso ou falha
    Remove-Item -Path $zipPath -ErrorAction SilentlyContinue
    Write-Host "Arquivo ZIP do ChromeDriver removido: $zipPath"
}

Write-Host "Instalação do ChromeDriver versão $latestDriverVersion completada com sucesso."

