$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$wb = $excel.Workbooks.Add()
$excel.ActiveCell.Value2 = "Hello, it works"
