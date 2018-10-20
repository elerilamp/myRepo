param (
	[string]$Directory = "H:\InProgress\PowerShell_CSV\myRepo\SourceFilesCSV\", #required
	[string]$CSVFileName = "_2_65MR_19C.csv",
	[string]$DestTableName = "_2_65MR_19C_new",
	[string]$DBName = "youCanDeleteThis",
	[string]$ServerName = "localhost\SQL14"
)
function LoadCsvTosql 
{  
  
    [CmdletBinding()]  
    param( 
	[Parameter(Position=0, Mandatory=$true)] [string]$Directory,
    [Parameter(Position=1, Mandatory=$true)] [string]$CSVFileName,  
    [Parameter(Position=2, Mandatory=$true)] [string]$ServerName,  
    [Parameter(Position=3, Mandatory=$true)] [String]$DBName, 
    [Parameter(Position=3, Mandatory=$true)] [String]$DestTableName
    )  
  
 try { 
    $FilestartTime=(Get-Date); 

	$CSVPath = "$Directory\$CSVFileName"
	
	####################### 
	function Get-Type 
	{ 
		param($type) 
	 
	$types = @( 
	'System.Boolean', 
	'System.Byte[]', 
	'System.Byte', 
	'System.Char', 
	'System.Datetime', 
	'System.Decimal', 
	'System.Double', 
	'System.Guid', 
	'System.Int16', 
	'System.Int32', 
	'System.Int64', 
	'System.Single', 
	'System.UInt16', 
	'System.UInt32', 
	'System.UInt64') 
	 
		if ( $types -contains $type ) { 
			Write-Output "$type" 
		} 
		else { 
			Write-Output 'System.String' 
			 
		} 
	} #Get-Type 
	 
	####################### 
	<# 
	.SYNOPSIS 
	Creates a DataTable for an object 
	.DESCRIPTION 
	Creates a DataTable based on an objects properties. 
	.INPUTS 
	Object 
		Any object can be piped to Out-DataTable 
	.OUTPUTS 
	   System.Data.DataTable 
	.EXAMPLE 
	$dt = Get-psdrive| Out-DataTable 
	This example creates a DataTable from the properties of Get-psdrive and assigns output to $dt variable 
	.NOTES 
	Adapted from script by Marc van Orsouw see link 
	Version History 
	v1.0  - Chad Miller - Initial Release 
	v1.1  - Chad Miller - Fixed Issue with Properties 
	v1.2  - Chad Miller - Added setting column datatype by property as suggested by emp0 
	v1.3  - Chad Miller - Corrected issue with setting datatype on empty properties 
	v1.4  - Chad Miller - Corrected issue with DBNull 
	v1.5  - Chad Miller - Updated example 
	v1.6  - Chad Miller - Added column datatype logic with default to string 
	v1.7 - Chad Miller - Fixed issue with IsArray 
	.LINK 
	http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx 
	#> 
	function Out-DataTable 
	{ 
		[CmdletBinding()] 
		param(
			[Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$InputObject,
			[Parameter(Position=1, Mandatory=$false, ValueFromPipeline = $true)] [bool]$FixDataValue = $false,
			[Parameter(Position=2, Mandatory=$false, ValueFromPipeline = $true)] [String]$DataValue = ""
		)
	 
		Begin 
		{ 
			$dt = new-object Data.datatable   
			$First = $true  
		} 
		Process 
		{ 
			foreach ($object in $InputObject) 
			{ 
				$DR = $DT.NewRow()   
				foreach($property in $object.PsObject.get_properties()) 
				{   
					if ($first) 
					{   
						$Col =  new-object Data.DataColumn   
						$Col.ColumnName = $property.Name.ToString()   
						if ($property.value) 
						{ 
							if ($property.value -isnot [System.DBNull]) { 
								$Col.DataType = [System.Type]::GetType("$(Get-Type $property.TypeNameOfValue)") 
							 } 
						} 
						$DT.Columns.Add($Col) 
					}   
					if ($property.Gettype().IsArray) { 
						$DR.Item($property.Name) =$property.value | ConvertTo-XML -AS String -NoTypeInformation -Depth 1 
					}   
				   else {
						if ($first -and $FixDataValue -and (-not ($DataValue -eq "XXX"))) {
							$DR.Item($property.Name) = $DataValue #replace value in the first data cell
							$DataValue = "XXX"
						} else {
							$DR.Item($property.Name) = $property.value 
						}
					} 
				}   
				$DT.Rows.Add($DR)   
				$First = $false 
			} 
		}  
		  
		End 
		{ 
			Write-Output @(,($dt)) 
		} 
	 
	} #Out-DataTable
	
	try {add-type -AssemblyName "Microsoft.SqlServer.ConnectionInfo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -EA Stop} 
	catch {add-type -AssemblyName "Microsoft.SqlServer.ConnectionInfo"} 
	 
	try {add-type -AssemblyName "Microsoft.SqlServer.Smo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -EA Stop}  
	catch {add-type -AssemblyName "Microsoft.SqlServer.Smo"}  
	 
	#######################  
	function Get-SqlType  
	{  
		param([string]$TypeName)  
	  
		switch ($TypeName)   
		{  
			'Boolean' {[Data.SqlDbType]::Bit}  
			'Byte[]' {[Data.SqlDbType]::VarBinary}  
			'Byte'  {[Data.SQLDbType]::VarBinary}  
			'Datetime'  {[Data.SQLDbType]::DateTime}  
			'Decimal' {[Data.SqlDbType]::Decimal}  
			'Double' {[Data.SqlDbType]::Float}  
			'Guid' {[Data.SqlDbType]::UniqueIdentifier}  
			'Int16'  {[Data.SQLDbType]::SmallInt}  
			'Int32'  {[Data.SQLDbType]::Int}  
			'Int64' {[Data.SqlDbType]::BigInt}  
			'UInt16'  {[Data.SQLDbType]::SmallInt}  
			'UInt32'  {[Data.SQLDbType]::Int}  
			'UInt64' {[Data.SqlDbType]::BigInt}  
			'Single' {[Data.SqlDbType]::Decimal} 
			default {[Data.SqlDbType]::NVarChar}  
		}  
		  
	} #Get-SqlType 
	 
	#######################  
	<#  
	.SYNOPSIS  
	Creates a SQL Server table from a DataTable  
	.DESCRIPTION  
	Creates a SQL Server table from a DataTable using SMO.  
	.EXAMPLE  
	$dt = Invoke-Sqlcmd2 -ServerInstance "Z003\R2" -Database pubs "select *  from authors"; Add-SqlTable -ServerInstance "Z003\R2" -Database pubscopy -TableName authors -DataTable $dt  
	This example loads a variable dt of type DataTable from a query and creates an empty SQL Server table  
	.EXAMPLE  
	$dt = Get-Alias | Out-DataTable; Add-SqlTable -ServerInstance "Z003\R2" -Database pubscopy -TableName alias -DataTable $dt  
	This example creates a DataTable from the properties of Get-Alias and creates an empty SQL Server table.  
	.NOTES  
	Add-SqlTable uses SQL Server Management Objects (SMO). SMO is installed with SQL Server Management Studio and is available  
	as a separate download: http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=ceb4346f-657f-4d28-83f5-aae0c5c83d52  
	Version History  
	v1.0   - Chad Miller - Initial Release  
	v1.1   - Chad Miller - Updated documentation 
	v1.2   - Chad Miller - Add loading Microsoft.SqlServer.ConnectionInfo 
	v1.3   - Chad Miller - Added error handling 
	v1.4   - Chad Miller - Add VarCharMax and VarBinaryMax handling 
	v1.5   - Chad Miller - Added AsScript switch to output script instead of creating table 
	v1.6   - Chad Miller - Updated Get-SqlType types 
	#>  
	function Add-SqlTable  
	{  
	  
		[CmdletBinding()]  
		param(  
		[Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance,  
		[Parameter(Position=1, Mandatory=$true)] [string]$Database,  
		[Parameter(Position=2, Mandatory=$true)] [String]$TableName,  
		[Parameter(Position=3, Mandatory=$true)] [System.Data.DataTable]$DataTable,  
		[Parameter(Position=4, Mandatory=$false)] [string]$Username,  
		[Parameter(Position=5, Mandatory=$false)] [string]$Password,  
		[ValidateRange(0,8000)]  
		[Parameter(Position=6, Mandatory=$false)] [Int32]$MaxLength=0, 
		[Parameter(Position=7, Mandatory=$false)] [switch]$AsScript 
		)  
	  
	 try { 
		if($Username)  
		{ $con = new-object ("Microsoft.SqlServer.Management.Common.ServerConnection") $ServerInstance,$Username,$Password }  
		else  
		{ $con = new-object ("Microsoft.SqlServer.Management.Common.ServerConnection") $ServerInstance }  
		  
		$con.Connect()  
	  
		$server = new-object ("Microsoft.SqlServer.Management.Smo.Server") $con  
		$db = $server.Databases[$Database]  
		$table = new-object ("Microsoft.SqlServer.Management.Smo.Table") $db, $TableName  
	  
		foreach ($column in $DataTable.Columns)  
		{  
			$sqlDbType = [Microsoft.SqlServer.Management.Smo.SqlDataType]"$(Get-SqlType $column.DataType.Name)"  
			if ($sqlDbType -eq 'VarBinary' -or $sqlDbType -eq 'NVarChar')  
			{  
				if ($MaxLength -gt 0)  
				{$dataType = new-object ("Microsoft.SqlServer.Management.Smo.DataType") $sqlDbType, $MaxLength} 
				else 
				{ $sqlDbType  = [Microsoft.SqlServer.Management.Smo.SqlDataType]"$(Get-SqlType $column.DataType.Name)Max" 
				  $dataType = new-object ("Microsoft.SqlServer.Management.Smo.DataType") $sqlDbType 
				} 
			}  
			else  
			{ $dataType = new-object ("Microsoft.SqlServer.Management.Smo.DataType") $sqlDbType }  
			$col = new-object ("Microsoft.SqlServer.Management.Smo.Column") $table, $column.ColumnName, $dataType  
			$col.Nullable = $column.AllowDBNull  
			$table.Columns.Add($col)  
		}  
	  
		if ($AsScript) { 
			$table.Script() 
		} 
		else { 
			$table.Create() 
		} 
	} 
	catch { 
		$message = $_.Exception.GetBaseException().Message 
		Write-Error $message
		throw $error
	} 
	   
	} #Add-SqlTable
	
	####################### 
	<# 
	.SYNOPSIS 
	Writes data only to SQL Server tables. 
	.DESCRIPTION 
	Writes data only to SQL Server tables. However, the data source is not limited to SQL Server; any data source can be used, as long as the data can be loaded to a DataTable instance or read with a IDataReader instance. 
	.INPUTS 
	None 
		You cannot pipe objects to Write-DataTable 
	.OUTPUTS 
	None 
		Produces no output 
	.EXAMPLE 
	$dt = Invoke-Sqlcmd2 -ServerInstance "Z003\R2" -Database pubs "select *  from authors" 
	Write-DataTable -ServerInstance "Z003\R2" -Database pubscopy -TableName authors -Data $dt 
	This example loads a variable dt of type DataTable from query and write the datatable to another database 
	.NOTES 
	Write-DataTable uses the SqlBulkCopy class see links for additional information on this class. 
	Version History 
	v1.0   - Chad Miller - Initial release 
	v1.1   - Chad Miller - Fixed error message 
	.LINK 
	http://msdn.microsoft.com/en-us/library/30c3y597%28v=VS.90%29.aspx 
	#> 
	function Write-DataTable 
	{ 
		[CmdletBinding()] 
		param( 
		[Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
		[Parameter(Position=1, Mandatory=$true)] [string]$Database, 
		[Parameter(Position=2, Mandatory=$true)] [string]$TableName, 
		[Parameter(Position=3, Mandatory=$true)] $Data, 
		[Parameter(Position=4, Mandatory=$false)] [string]$Username, 
		[Parameter(Position=5, Mandatory=$false)] [string]$Password, 
		[Parameter(Position=6, Mandatory=$false)] [Int32]$BatchSize=0, 
		[Parameter(Position=7, Mandatory=$false)] [Int32]$QueryTimeout=0, 
		[Parameter(Position=8, Mandatory=$false)] [Int32]$ConnectionTimeout=15 
		) 
		 
		$conn=new-object System.Data.SqlClient.SQLConnection 
	 
		if ($Username) 
		{ $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
		else 
		{ $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout } 
	 
		$conn.ConnectionString=$ConnectionString 
	 
		try 
		{ 
			$conn.Open() 
			$bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $connectionString
			$bulkCopy.DestinationTableName = $tableName
			$bulkCopy.BatchSize = $BatchSize 
			$bulkCopy.BulkCopyTimeout = $QueryTimeOut 
			$bulkCopy.WriteToServer($Data) 
			$conn.Close() 
		} 
		catch 
		{ 
			$ex = $_.Exception 
			Write-Error "$ex.Message" 
			continue 
		} 
	 
	} #Write-DataTable

	$table = [IO.Path]::GetFileNameWithoutExtension($CSVPath)
		
	Write-Host -NoNewLine "Importing CSV to [$DBName] in progress... $table"

	#testing first dataline of csv - Import-Csv fail when first cell is empty (using powershell 2.0)
	$CsvFile = @(Get-Content $CSVPath)

	if ($CsvFile[1].substring(0,1) -eq ",") {
		$CsvFile[1] = ".$($CsvFile[1])"
		$CsvFile | Set-Content "$CSVPath.delete" #copy file
		$CSVPath = "$CSVPath.delete"
		$FixDataValue = $true
	} else {
		
		$FixDataValue = $false
	}
	
	$dtemp = Import-Csv -Path $CSVPath #- | Out-DataTable
	
			
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
	 
	$dt = Out-DataTable -InputObject $dtemp -FixDataValue $FixDataValue
	$dtCount = $dt.Rows.Count

	Add-SqlTable -ServerInstance $ServerName -Database $DBName -TableName $DestTableName -DataTable $dt
	
	Write-DataTable -ServerInstance $ServerName -Database $DBName -TableName $DestTableName -Data $dt
	
	Write-Output "  [$dtCount rows]"
	
} 
catch { 
    $message = $_.Exception.GetBaseException().Message
	
	if ($message -like "There is already an object*") {
		Write-Output "0 Rows Inserted"
		break
	} else {
		Write-Error $message
	}
	
} 
finally {
	if ($CSVPath -like "*.delete") {
		Remove-Item $CSVPath
	}
}
        
        $FileElapsed=(Get-Date)-$FilestartTime; 
        Write-Output "File Load Time: $FileElapsed"   
   
} #LoadCsvTosql

LoadCsvTosql -Directory $Directory -CSVFileName $CsvFileName -ServerName $ServerName -DBName $DBName -DestTableName $DestTableName
