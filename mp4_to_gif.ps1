$mp4Dir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "doc\gifs"

$mp4s = Get-ChildItem -Path $mp4Dir -Filter "*.mp4"

if ($mp4s.Count -eq 0) {
    Write-Host "No MP4 files found in: $mp4Dir"
    exit
}

foreach ($mp4 in $mp4s) {
    $gifOut = Join-Path $mp4.DirectoryName "$($mp4.BaseName).gif"

    Write-Host "Converting: $($mp4.Name) -> $($mp4.BaseName).gif"
    ffmpeg -y -loglevel warning -i $mp4.FullName `
        -vf "fps=15,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" `
        $gifOut
    Write-Host "Done: $($mp4.BaseName).gif"
}

Write-Host ""
Write-Host "All done. MP4 files preserved."
