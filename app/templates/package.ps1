Add-Type -AssemblyName System.IO.Compression.FileSystem

$gameName = "test";

function Archive
{
    $src = $PSScriptRoot+'\src'
    $archiveFolder = $PSScriptRoot+'\archives\'
    $dest = $archiveFolder+$gameName+'.love'

    # Creates archives dir if not exists
    if(-Not (Test-Path $archiveFolder))
    {
        New-Item -ItemType Directory -Force -Path $archiveFolder
    }

    # Remove old archive
    if(Test-Path $dest)
    {
        Remove-Item $dest -Recurse -Force
    }

     Write-Host "[Archive] Starting ..."
    [io.compression.zipfile]::CreateFromDirectory($src, $dest )
     Write-Host "[Archive] Finished : $dest"
}

function DownloadDependency
{
    param( [string]$name )
 
    $toolsFolder = $PSScriptRoot+'\engines\';
    $destPath = $toolsFolder+$name+'.zip'

    if(-Not (Test-Path $destPath))
    {
        New-Item -ItemType Directory -Force -Path $toolsFolder

        $client = (New-Object Net.WebClient)
        $sourceUrl = 'https://bitbucket.org/rude/love/downloads/'+$name+'.zip'
        Write-Host "[Download][$name] Starting $sourceUrl ..."
        $client.DownloadFile($sourceUrl,$destPath);
        Write-Host "[Download][$name] Finished !"
        $client.Dispose();
    }

}

function PackageWindows
{
    param( [string]$loveVersion, [string]$arch )
    
    $bin = $PSScriptRoot+'\bin\win\' + $arch + '\'

    # Remove old binaries
    if(Test-Path $bin)
    {
        Remove-Item $bin -Recurse -Force
    }

    # Download LOVE framework
    $name = 'love-' + $loveVersion + '-'+$arch
    DownloadDependency $name
    
    # Unzip LOVE framework to bin directory
    $zip = $PSScriptRoot+'\engines\'+$name+'.zip'
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip,$bin)

    # Generate executable
    $archive = $PSScriptRoot+'\archives\'+$gameName+'.love'
    $loveexe = $bin + $name + '\' + "love.exe"
    $gameexe = $bin + $name + '\' + $gameName +'.exe'
    New-Item -ItemType File -Force -Path $gameexe
    Add-Content -Path $gameexe -Value (Get-Content $loveexe)
    Add-Content -Path $gameexe -Value (Get-Content $archive)
    Write-Host "[Package][Windows] Finished : $bin"
}

function PackageMacOs
{
    param( [string]$loveVersion, [string]$arch )
    
    $bin = $PSScriptRoot+'\bin\macosx\' + $arch + '\'

    # Remove old binaries
    if(Test-Path $bin)
    {
        Remove-Item $bin -Recurse -Force
    }

    # Download LOVE framework
    $name = 'love-' + $loveVersion + '-macosx-'+$arch
    DownloadDependency $name
    
    # Unzip LOVE framework to bin directory
    $zip = $PSScriptRoot+'\engines\'+$name+'.zip'
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip,$bin)

    # Renaming app
    $appName = $gameName + ".app"
    $appFolder = $bin + $appName + "\"
    Rename-Item ($bin + "love.app") $appName
    
    # Copy love archive to resources
    $appResourcesFolder = $appFolder + "Resources"
    $archive = $PSScriptRoot+'\archives\'+$gameName+'.love'
    Copy-Item $archive $appResourcesFolder
    
    # Updating Info.plist
    $appPlist = $appFolder + "Info.plist"
    Get-Content $appPlist | ForEach-Object { $_ -replace "org.love2d.love", "com."+$gameName } | ForEach-Object { $_ -replace "LÖVE", $gameName } | Set-Content ($file+".tmp")
    
}

Archive
PackageWindows "0.9.2" "win32"
PackageMacOs "0.9.2" "x64"