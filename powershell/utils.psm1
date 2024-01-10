function Get-BrParameterCount {
    param (
        [string[]]$ParameterName
    )

    foreach ($Parameter in $ParameterName) {
        $Results = Get-Command -ParameterName $Parameter -ErrorAction SilentlyContinue

        [pscustomobject]@{
            ParameterName = $Parameter
            NumberOfCmdlets = $Results.Count
        }
    }
}

function Get-WslPath {
    $path = Get-Location
    $wsl_path = $path -replace "\\","/"
    $wsl_path = $wsl_path -replace "C:/","/mnt/c/"
    return $wsl_path
}

Export-ModuleMember -Function Get-BrParameterCount, Get-WslPath
