# Powershell profile. Adapted from: https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
# To be installed at (For Windows Power Shell):
# C:\Users\[User]\Documents\WindowsPowerShell\profile.ps1
# (For PowerShell 6+):
# C:\Users\[User]\Documents\PowerShell\profile.ps1

Import-Module -Name "$PSScriptRoot/document_conversion"
Import-Module -Name "$PSScriptRoot/utils"

# initialize posh prompt if installed
$res=(Get-Command oh-my-posh)
if ($res) {
    # prevent python venv messing up the prompt
    $env:VIRTUAL_ENV_DISABLE_PROMPT=1

    # run posh init
    & ([ScriptBlock]::Create((oh-my-posh init pwsh --config "$PSScriptRoot/oh_my_posh_theme.json" --print) -join "`n"))
}



# aliases
New-Alias ll ls

# Use PsReadLine and switch to emacs mode
Import-Module PSReadLine
Set-PSReadLineOption -EditMode Emacs
# Set-PSReadlineKeyHandler -Key ctrl+d -Function DeleteCharOrExit


# The option "moves to end" is useful if you want the cursor at the end
# of the line while cycling through history like it does w/o searching,
# without that option, the cursor will remain at the position it was
# when you used up arrow, which can be useful if you forget the exact
# string you started the search on.
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# This key handler shows the entire or filtered history using Out-GridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.
Set-PSReadLineKeyHandler -Key F7 `
                         -BriefDescription History `
                         -LongDescription 'Show command history' `
                         -ScriptBlock {
    $pattern = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
    if ($pattern)
    {
        $pattern = [regex]::Escape($pattern)
    }
    $history = [System.Collections.ArrayList]@(
        $last = ''
        $lines = ''
        foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath))
        {
            if ($line.EndsWith('`'))
            {
                $line = $line.Substring(0, $line.Length - 1)
                $lines = if ($lines)
                {
                    "$lines`n$line"
                }
                else
                {
                    $line
                }
                continue
            }
            if ($lines)
            {
                $line = "$lines`n$line"
                $lines = ''
            }
            if (($line -cne $last) -and (!$pattern -or ($line -match $pattern)))
            {
                $last = $line
                $line
            }
        }
    )
    $history.Reverse()
    $command = $history | Out-GridView -Title History -PassThru
    if ($command)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
    }
}

# In Emacs mode - Tab acts like in bash, but the Windows style completion
# is still useful sometimes, so bind some keys so we can do both
Set-PSReadLineKeyHandler -Key Ctrl+q -Function TabCompleteNext
Set-PSReadLineKeyHandler -Key Ctrl+Q -Function TabCompletePrevious

# CaptureScreen is good for blog posts or email showing a transaction
# of what you did when asking for help or demonstrating a technique.
# Set-PSReadLineKeyHandler -Chord 'Ctrl+d,Ctrl+c' -Function CaptureScreen

# cannot hear >15khz, set it high enough to annoy other people
# Set-PSReadLineOption -DingTone 13000
# Set-PSReadLineOption -DingDuration 250
