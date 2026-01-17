#Obtain TaglibSharp dll assembly
set-location $PSScriptRoot
$DestinationPath = Join-Path -Path "$PSScriptRoot" -ChildPath "psmusictagger\lib"
$TargetLibPath = Join-Path -Path $DestinationPath -ChildPath "TagLibSharp.dll"
If(-not (Test-Path -Path $DestinationPath)){
    New-Item -Path $DestinationPath -ItemType Directory
}else{
    Write-Verbose "Lib folder already exists at $DestinationPath" -Verbose
    #remove existing TagLibSharp.dll
    If(Test-Path -Path $TargetLibPath){
        Remove-Item -Path $TargetLibPath -Force
    }
}

git clone https://github.com/mono/taglib-sharp.git    
set-location .\taglib-sharp
dotnet build ./src/TagLibSharp/TaglibSharp.csproj -c Release
$TaglibPath = (Get-ChildItem -Path .\src\TagLibSharp\bin\Release\netstandard2.0\TagLibSharp.dll).FullName

Copy-Item -Path $TaglibPath -Destination $TargetLibPath -Force
set-location $PSScriptRoot
Remove-Item -Path .\taglib-sharp -Recurse -Force