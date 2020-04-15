$path = [System.Environment]::GetEnvironmentVariable("Path",
 "Machine")
[System.Environment]::SetEnvironmentVariable("PSModulePath", $path +
";C:\data", "Machine")


Get-ChildItem Env: |fl