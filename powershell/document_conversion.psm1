function Convert-Documents-Doc {

    param (
        [Parameter(Mandatory)] $DocumentPath,
        [Parameter(Mandatory)] $ResultDir
    )
    
    $word_app = New-Object -ComObject Word.Application
    $result_dir = Resolve-Path $ResultDir

    # This filter will find .doc as well as .docx documents
    Get-ChildItem -Path $DocumentPath -Filter *.doc? | ForEach-Object {

        $document = $word_app.Documents.Open($_.FullName)
        $document.PrintRevisions = False
        $document.ShowRevisions = False

        $pdf_filename = "$result_dir/$($_.BaseName).pdf"
        Write-Output "Saving $pdf_filename"

        $document.SaveAs([ref] $pdf_filename, [ref] 17)
        $document.Close()
    }

    $word_app.Quit()
}

function Convert-Documents-Ppt {

    param (
        [Parameter(Mandatory)] $DocumentPath,
        [Parameter(Mandatory)] $ResultDir
    )
    
    $result_dir = Resolve-Path $ResultDir

    # workaround for ppSaveAsPDF not found
    $SaveOption = 32 # [Microsoft.Office.Interop.PowerPoint.PpSaveAsFileType]::ppSaveAsPDF
    $PowerPoint = New-Object -ComObject “PowerPoint.Application”

    Get-ChildItem -Path $DocumentPath -Filter *.pptx | ForEach-Object {

        $Presentation = $PowerPoint.Presentations.Open($_.FullName)
        $pdf_filename = "$result_dir/$($_.BaseName).pdf"
        Write-Output "Saving $pdf_filename"

        $Presentation.SaveAs($pdf_filename, $SaveOption)
        $Presentation.Close()
    }

    $PowerPoint.Quit()
}

Export-ModuleMember -Function Convert-Documents-Doc
Export-ModuleMember -Function Convert-Documents-Ppt
