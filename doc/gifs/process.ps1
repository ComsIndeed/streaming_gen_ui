$currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputDir = Join-Path $currentDir "input"
$outputDir = Join-Path $currentDir "output"
$archiveDir = Join-Path $currentDir "archive"

# Ensure directories exist
if (!(Test-Path $inputDir)) { New-Item -ItemType Directory -Path $inputDir | Out-Null }
if (!(Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }
if (!(Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir | Out-Null }

$mediaFiles = @(Get-ChildItem -Path $inputDir -File | Where-Object { $_.Extension.ToLower() -in ".mp4", ".gif" })

if ($mediaFiles.Count -eq 0) {
    Write-Host "No MP4 or GIF files found in: $inputDir"
    Write-Host "Please drop your original files into the 'input' folder and run this script again."
    Write-Host "Current Directory is: $currentDir"
    exit
}

foreach ($file in $mediaFiles) {
    $baseName = $file.BaseName
    $ext = $file.Extension.ToLower()

    Write-Host "`n=================================================="
    Write-Host "Processing: $($file.Name) ($($file.Length / 1MB -as [int])MB)"
    Write-Host "=================================================="

    # Determine full-size high-quality gif source for downscaling
    $fullSizeGif = Join-Path $outputDir "$baseName.gif"

    if ($ext -eq ".mp4") {
        Write-Host "-> Converting MP4 to full-size GIF..."
        ffmpeg -y -loglevel warning -i $file.FullName -vf "fps=15,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $fullSizeGif
    }
    elseif ($ext -eq ".gif") {
        Write-Host "-> Copying full-size GIF to output..."
        Copy-Item -Path $file.FullName -Destination $fullSizeGif -Force
    }

    # Now generate the downscaled versions from the fullSizeGif
    # Small: 320px
    $smallOut = Join-Path $outputDir "$($baseName)_small.gif"
    Write-Host "-> Generating small (320px)..."
    ffmpeg -y -loglevel warning -i $fullSizeGif -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $smallOut

    # Medium: 480px
    $mediumOut = Join-Path $outputDir "$($baseName)_medium.gif"
    Write-Host "-> Generating medium (480px)..."
    ffmpeg -y -loglevel warning -i $fullSizeGif -vf "scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $mediumOut

    # Large: 640px
    $largeOut = Join-Path $outputDir "$($baseName)_large.gif"
    Write-Host "-> Generating large (640px)..."
    ffmpeg -y -loglevel warning -i $fullSizeGif -vf "scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $largeOut

    # Move the original input file to the archive folder
    Write-Host "-> Archiving original file..."
    $archivePath = Join-Path $archiveDir $file.Name
    if (Test-Path $archivePath) {
        Remove-Item -Path $archivePath -Force
    }
    Move-Item -Path $file.FullName -Destination $archiveDir -Force

    Write-Host "Done with $baseName!"
}

Write-Host "`nAll media files processed successfully!"
