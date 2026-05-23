$gifDir = "doc/gifs"

Write-Host "Cleaning up old downscaled variants..."
Get-ChildItem -Path $gifDir -Filter "*_small.gif" | Remove-Item -ErrorAction SilentlyContinue
Get-ChildItem -Path $gifDir -Filter "*_medium.gif" | Remove-Item -ErrorAction SilentlyContinue
Get-ChildItem -Path $gifDir -Filter "*_large.gif" | Remove-Item -ErrorAction SilentlyContinue

$gifs = Get-ChildItem -Path $gifDir -Filter "*.gif"

foreach ($gif in $gifs) {
    if ($gif.Name -like "*_small.gif" -or $gif.Name -like "*_medium.gif" -or $gif.Name -like "*_large.gif") {
        continue
    }

    $baseName = $gif.BaseName
    $dir = $gif.DirectoryName

    Write-Host "=========================================="
    Write-Host "Processing: $($gif.Name) ($($gif.Length / 1MB -as [int])MB)"
    Write-Host "=========================================="

    # Small: 320px
    $smallOut = Join-Path $dir "$($baseName)_small.gif"
    Write-Host "-> Generating small (320px)..."
    ffmpeg -y -loglevel warning -i $gif.FullName -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $smallOut

    # Medium: 480px
    $mediumOut = Join-Path $dir "$($baseName)_medium.gif"
    Write-Host "-> Generating medium (480px)..."
    ffmpeg -y -loglevel warning -i $gif.FullName -vf "scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $mediumOut

    # Large: 640px
    $largeOut = Join-Path $dir "$($baseName)_large.gif"
    Write-Host "-> Generating large (640px)..."
    ffmpeg -y -loglevel warning -i $gif.FullName -vf "scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $largeOut
    
    Write-Host "Finished $($gif.Name)"
}
