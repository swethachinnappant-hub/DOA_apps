# Create PostgreSQL database jewelryb2b on PG15
$pgBin = 'C:\Program Files\PostgreSQL\15\bin'
$env:PATH = $pgBin + ';' + $env:PATH

# Try connecting with trust authentication
Write-Host "Attempting to connect to PG15..."
& "$pgBin\psql.exe" -U postgres -p 5432 -h localhost -c "SELECT 1 AS test_connection" 2>&1 | Out-File "C:\tmp\pg_test.txt" -Encoding utf8
Write-Host "Connection test complete. Check C:\tmp\pg_test.txt"