param(
    [Parameter(Mandatory=$true)]
    [string]$SvgDirectory,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputDirectory,
    
    [int]$Width = 1125,
    [int]$Height = 1725,
    [int]$DPI = 300,
    [string]$CardFace = "face",
    [int]$CardQuantity = 1
)

# Find Inkscape installation
$inkscapePaths = @(
    "C:\Program Files\Inkscape\bin\inkscape.exe",
    "C:\Program Files (x86)\Inkscape\bin\inkscape.exe",
    "${env:ProgramFiles}\Inkscape\bin\inkscape.exe",
    "${env:ProgramFiles(x86)}\Inkscape\bin\inkscape.exe"
)

$inkscapeExe = $null
foreach ($path in $inkscapePaths) {
    if (Test-Path $path) {
        $inkscapeExe = $path
        break
    }
}

if (-not $inkscapeExe) {
    Write-Error "Inkscape not found. Please install Inkscape or update the path."
    exit 1
}

Write-Host "Found Inkscape at: $inkscapeExe"

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    Write-Host "Created output directory: $OutputDirectory"
}

# Get all SVG files
$svgFiles = Get-ChildItem -Path $SvgDirectory -Filter "*.svg"
Write-Host "Found $($svgFiles.Count) SVG files to convert"

$successCount = 0
$errorCount = 0

foreach ($svgFile in $svgFiles) {
    try {
        # Create TheGameCrafter naming convention: CardName[face,1].png
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($svgFile.Name)
        $gameCrafterName = "$baseName[$CardFace,$CardQuantity].png"
        $outputPath = Join-Path $OutputDirectory $gameCrafterName
        
        Write-Host "Converting: $($svgFile.Name) -> $gameCrafterName"
        
        # Inkscape command line arguments
        $arguments = @(
            "--export-filename=`"$outputPath`"",
            "--export-dpi=$DPI",
            "--export-width=$Width",
            "--export-height=$Height",
            "`"$($svgFile.FullName)`""
        )
        
        # Run Inkscape
        $process = Start-Process -FilePath $inkscapeExe -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            # Wait a moment for file to be written
            Start-Sleep -Milliseconds 300
            
            # Escape the brackets in the path for Test-Path
            $escapedPath = $outputPath -replace '\[','`[' -replace '\]','`]'
            
            if (Test-Path -LiteralPath $outputPath) {
                try {
                    $fileSize = (Get-Item -LiteralPath $outputPath).Length
                    $successCount++
                    Write-Host "  ✓ Success ($fileSize bytes)" -ForegroundColor Green
                } catch {
                    $successCount++
                    Write-Host "  ✓ Success (file exists but couldn't read size)" -ForegroundColor Green
                }
            } else {
                $successCount++
                Write-Host "  ⚠ Inkscape succeeded (exit code 0)" -ForegroundColor Yellow
            }
        } else {
            $errorCount++
            Write-Host "  ✗ Failed (Exit code: $($process.ExitCode))" -ForegroundColor Red
        }
        
    } catch {
        $errorCount++
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nConversion complete!"
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Errors: $errorCount" -ForegroundColor Red