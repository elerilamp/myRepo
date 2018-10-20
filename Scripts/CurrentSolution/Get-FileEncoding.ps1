function Get-FileEncoding {
<#
.SYNOPSIS
Gets file encoding.
.DESCRIPTION
The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM).
Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx
.EXAMPLE
Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'}
This command gets ps1 files in current directory where encoding is not ASCII
.EXAMPLE
Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'} | foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding ASCII}
Same as previous example but fixes encoding using set-content
.NOTES
Version History
v1.0   - 2010/08/10, Chad Miller - Initial release
v1.1   - 2010/08/16, Jason Archer - Improved pipeline support and added detection of little endian BOMs.
#>
    [CmdletBinding()]
    param (
        [Alias("PSPath")]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [String]$Path
    )
 
    process {
        $Encoding = "ASCII"
        [Byte[]]$byte = Get-Content -Encoding Byte -ReadCount 4 -TotalCount 4 -Path $Path
 
        if ($byte[0] -eq 0xEF -and $byte[1] -eq 0xBB -and $byte[2] -eq 0xBF) {
            $Encoding = "UTF8"
        } elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xFE -and $byte[3] -eq 0xFF) {
            ## UTF-32 Big-Endian
            $Encoding = "UTF32"
        } elseif ($byte[0] -eq 0xFF -and $byte[1] -eq 0xFE -and $byte[2] -eq 0 -and $byte[3] -eq 0) {
            ## UTF-32 Little-Endian
            $Encoding = "UTF32"
        } elseif ($byte[0] -eq 0xFE -and $byte[1] -eq 0xFF) {
            ## 1201 UTF-16 Big-Endian
            $Encoding = "Unicode (UTF16))"
        } elseif ($byte[0] -eq 0xFF -and $byte[1] -eq 0xFE) {
            ## 1200 UTF-16 Little-Endian
            $Encoding = "Unicode (UTF16))"
        } elseif ($byte[0] -eq 0x2B -and $byte[1] -eq 0x2F -and $byte[2] -eq 0x76) {
            $Encoding = "UTF7"
        }
 
        $Encoding
    }
}