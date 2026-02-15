# driver-server.ps1

$port = 8080
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serveur local démarré sur http://localhost:$port"

function Get-Drivers {
    $drivers = Get-WmiObject Win32_PnPSignedDriver | 
        Select-Object DeviceName, Manufacturer, DriverVersion, DriverDate

    $drivers | ForEach-Object {
        [PSCustomObject]@{
            DeviceName    = $_.DeviceName
            Manufacturer  = $_.Manufacturer
            DriverVersion = $_.DriverVersion
            DriverDate    = $_.DriverDate
        }
    } | ConvertTo-Json -Depth 2
}

while ($true) {
    try {
        $context = $listener.GetContext()
        $response = $context.Response

        # Autoriser les requêtes depuis n'importe quelle origine (CORS)
        $response.AddHeader("Access-Control-Allow-Origin", "*")

        $json = Get-Drivers
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)

        $response.ContentLength64 = $buffer.Length
        $response.ContentType = "application/json"

        try {
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Flush()
        } catch {
            Write-Warning "Client fermé avant la fin de l'envoi : $_"
        } finally {
            $response.OutputStream.Close()
        }
    } catch {
        Write-Warning "Erreur lors de la réception d'une requête : $_"
    }
}
