# Try PG16 connection
$pgBin = 'C:\Program Files\PostgreSQL\16\bin'
$env:PATH = $pgBin + ';' + $env:PATH
& "$pgBin\psql.exe" -U postgres -p 5433 -h localhost -c "SELECT 1 AS test_connection" > "C:\tmp\pg16_test.txt" 2>&1
Write-Host "PG16 test complete. Check C:\tmp\pg16_test.txt"