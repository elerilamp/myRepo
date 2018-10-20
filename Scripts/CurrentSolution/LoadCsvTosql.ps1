function LoadCsvTosql 
{  


    [CmdletBinding()]  
    param(  
    [Parameter(Position=0, Mandatory=$true)] [string]$Directory,  
    [Parameter(Position=1, Mandatory=$true)] [string]$ServerName,  
    [Parameter(Position=2, Mandatory=$true)] [String]$DBName
    )  
  
 try {   
 
 $startTime=(Get-Date); 

	. .\Out-DataTable.ps1
	. .\Add-SqlTable.ps1
	. .\write-datatable.ps1


	foreach ($i in ls -name $($Directory+"*.csv"))
	{
		#$dtemp = Import-Csv -Path (Get-ChildItem $($Directory+"*.csv"))
        $FilestartTime=(Get-Date); 
		
		$table = [IO.Path]::GetFileNameWithoutExtension($i)

		
		Write-Host -NoNewLine  "Import in progress... $table"

		$dtemp = Import-Csv -Path $($Directory+$i) #- | Out-DataTable
		
				
		#remove UTF8 BOM
		if($dtemp -is [system.array]){
		
			foreach ($val in $dtemp[0].PsObject.get_properties()) {
				$utf = $val.Value.substring(0,1).ToCharArray()
				$utftest = [System.String]::Format("{0:X2}", [System.Convert]::ToUInt32($utf[0]))
				if ($utftest -eq "FEFF") {$val.Value = $val.Value.substring(1)}
				break
			}
		}
		else {
			foreach ($val in $dtemp.PsObject.get_properties()) {
				$utf = $val.Value.substring(0,1).ToCharArray()
				$utftest = [System.String]::Format("{0:X2}", [System.Convert]::ToUInt32($utf[0]))
				if ($utftest -eq "FEFF") {$val.Value = $val.Value.substring(1)}
				break
			}
		}
		
		if($dtemp) #test if file is empty
		{
			$dt = Out-DataTable $dtemp
			$dtCount = $dt.Rows.Count

			Add-SqlTable -ServerInstance $ServerName -Database $DBName -TableName $table -DataTable $dt
			
			Write-DataTable -ServerInstance $ServerName -Database $DBName -TableName $table -Data $dt
			
			Write-Output "  [$dtCount rows]"
			
			$ImportedPath = $Directory + "Imported\"
			$FullFileName = $Directory + $i
			New-Item -ItemType directory -Path $ImportedPath -Force | Out-Null
			Move-Item $FullFileName $ImportedPath -Force
		}
		else
			#when file is empty move to EmptyFile subfolder
			{
				Write-Output " .. skipped - no data"
				$EmptyPath = $Directory + "EmptyFiles\"
				$FullFileName = $Directory + $i
				New-Item -ItemType directory -Path $EmptyPath -Force | Out-Null
				Move-Item $FullFileName $EmptyPath -Force
			}
        $FileElapsed=(Get-Date)-$FilestartTime; 
        Write-Output "File Load Time: $FileElapsed"
	}

$Elapsed=(Get-Date)-$startTime; 
Write-Host "Toltal Time: $Elapsed"

} 
catch { 
    $message = $_.Exception.GetBaseException().Message 
    Write-Error $message 
} 
   
} #LoadCsvTosql