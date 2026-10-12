$soundsDir = "c:\project\AplikasiAndroid\menstracker\assets\sounds"
if (!(Test-Path $soundsDir)) {
    New-Item -ItemType Directory -Force -Path $soundsDir
}

function Create-WavBytes($samples, $sampleRate) {
    $numSamples = $samples.Length
    $numChannels = 1
    $bitsPerSample = 16
    $byteRate = $sampleRate * $numChannels * ($bitsPerSample / 8)
    $blockAlign = $numChannels * ($bitsPerSample / 8)
    $dataSize = $numSamples * ($bitsPerSample / 8)
    $chunkSize = 36 + $dataSize

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)

    # "RIFF"
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
    $bw.Write([UInt32]$chunkSize)
    # "WAVE"
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
    # "fmt "
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
    $bw.Write([UInt32]16) # Subchunk1Size
    $bw.Write([UInt16]1)  # PCM
    $bw.Write([UInt16]$numChannels)
    $bw.Write([UInt32]$sampleRate)
    $bw.Write([UInt32]$byteRate)
    $bw.Write([UInt16]$blockAlign)
    $bw.Write([UInt16]$bitsPerSample)
    # "data"
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
    $bw.Write([UInt32]$dataSize)

    foreach ($s in $samples) {
        $clamped = [Math]::Max(-1.0, [Math]::Min(1.0, $s))
        $int16 = [Int16]($clamped * 32767.0)
        $bw.Write($int16)
    }

    $bw.Flush()
    $bytes = $ms.ToArray()
    $bw.Close()
    $ms.Close()
    return $bytes
}

$sampleRate = 44100

# 1. Pop
$duration = 0.12
$total = [int]($sampleRate * $duration)
$samples = New-Object double[] $total
for ($i = 0; $i -lt $total; $i++) {
    $t = $i / $sampleRate
    $progress = $i / $total
    $freq = 440.0 + (680.0 * [Math]::Pow($progress, 0.65))
    $env = if ($progress -lt 0.06) { $progress / 0.06 } else { [Math]::Exp(-7.5 * ($progress - 0.06)) }
    $wave = 0.85 * [Math]::Sin(2 * [Math]::PI * $freq * $t) + 0.15 * [Math]::Sin(4 * [Math]::PI * $freq * $t)
    $samples[$i] = $wave * $env
}
[System.IO.File]::WriteAllBytes("$soundsDir\mascot_pop.wav", (Create-WavBytes $samples $sampleRate))
Write-Host "Created mascot_pop.wav"

# 2. Boop
$duration = 0.16
$total = [int]($sampleRate * $duration)
$samples = New-Object double[] $total
for ($i = 0; $i -lt $total; $i++) {
    $t = $i / $sampleRate
    $progress = $i / $total
    $freq = 650.0 + (180.0 * [Math]::Sin([Math]::PI * $progress))
    $env = [Math]::Sin([Math]::PI * [Math]::Pow($progress, 0.55)) * [Math]::Exp(-4.0 * $progress)
    $wave = 0.9 * [Math]::Sin(2 * [Math]::PI * $freq * $t) + 0.1 * [Math]::Sin(4 * [Math]::PI * $freq * $t)
    $samples[$i] = $wave * $env
}
[System.IO.File]::WriteAllBytes("$soundsDir\mascot_boop.wav", (Create-WavBytes $samples $sampleRate))
Write-Host "Created mascot_boop.wav"

# 3. Sparkle
$duration = 0.36
$total = [int]($sampleRate * $duration)
$samples = New-Object double[] $total
$freqs = @(1567.98, 2093.00, 2637.02, 3135.96)
$delays = @(0.0, 0.06, 0.12, 0.18)
for ($k = 0; $k -lt $freqs.Length; $k++) {
    $f = $freqs[$k]
    $d = $delays[$k]
    $startIdx = [int]($d * $sampleRate)
    for ($i = $startIdx; $i -lt $total; $i++) {
        $localT = ($i - $startIdx) / $sampleRate
        $env = [Math]::Exp(-9.5 * $localT)
        $chime = [Math]::Sin(2 * [Math]::PI * $f * $localT) + 0.25 * [Math]::Sin(4 * [Math]::PI * $f * $localT)
        $samples[$i] += ($chime * $env * 0.32)
    }
}
[System.IO.File]::WriteAllBytes("$soundsDir\mascot_sparkle.wav", (Create-WavBytes $samples $sampleRate))
Write-Host "Created mascot_sparkle.wav"

# 4. Happy
$duration = 0.42
$total = [int]($sampleRate * $duration)
$samples = New-Object double[] $total
$notes = @(1046.50, 1318.51, 1567.98, 2093.00)
$noteDur = 0.09
for ($k = 0; $k -lt $notes.Length; $k++) {
    $f = $notes[$k]
    $startT = $k * $noteDur
    $startIdx = [int]($startT * $sampleRate)
    $endIdx = [Math]::Min($total, [int](($startT + 0.18) * $sampleRate))
    for ($i = $startIdx; $i -lt $endIdx; $i++) {
        $localT = ($i - $startIdx) / $sampleRate
        $env = [Math]::Sin([Math]::PI * ($localT / 0.18)) * [Math]::Exp(-4.5 * $localT)
        $wave = 0.8 * [Math]::Sin(2 * [Math]::PI * $f * $localT) + 0.2 * [Math]::Sin(4 * [Math]::PI * $f * $localT)
        $samples[$i] += ($wave * $env * 0.38)
    }
}
[System.IO.File]::WriteAllBytes("$soundsDir\mascot_happy.wav", (Create-WavBytes $samples $sampleRate))
Write-Host "Created mascot_happy.wav"

# 5. Giggle
$duration = 0.30
$total = [int]($sampleRate * $duration)
$samples = New-Object double[] $total
for ($i = 0; $i -lt $total; $i++) {
    $t = $i / $sampleRate
    $progress = $i / $total
    $pulse = [Math]::Abs([Math]::Sin(3 * 2 * [Math]::PI * $progress))
    $freq = 800.0 + (320.0 * [Math]::Sin(2 * [Math]::PI * 8.0 * $t))
    $env = $pulse * [Math]::Exp(-2.2 * $progress)
    $wave = [Math]::Sin(2 * [Math]::PI * $freq * $t)
    $samples[$i] = $wave * $env * 0.65
}
[System.IO.File]::WriteAllBytes("$soundsDir\mascot_giggle.wav", (Create-WavBytes $samples $sampleRate))
Write-Host "Created mascot_giggle.wav"

# 6. Greeting
$duration = 0.38
$total = [int]($sampleRate * $duration)
$samples = New-Object double[] $total
$freqs = @(1396.91, 1760.00, 2093.00)
$delays = @(0.0, 0.10, 0.20)
for ($k = 0; $k -lt $freqs.Length; $k++) {
    $f = $freqs[$k]
    $d = $delays[$k]
    $startIdx = [int]($d * $sampleRate)
    for ($i = $startIdx; $i -lt $total; $i++) {
        $localT = ($i - $startIdx) / $sampleRate
        $env = [Math]::Exp(-7.0 * $localT)
        $chime = 0.85 * [Math]::Sin(2 * [Math]::PI * $f * $localT) + 0.15 * [Math]::Sin(4 * [Math]::PI * $f * $localT)
        $samples[$i] += ($chime * $env * 0.35)
    }
}
[System.IO.File]::WriteAllBytes("$soundsDir\mascot_greeting.wav", (Create-WavBytes $samples $sampleRate))
Write-Host "Created mascot_greeting.wav"

# 7. Swoop
$duration = 0.32
$total = [int]($sampleRate * $duration)
$samples = New-Object double[] $total
for ($i = 0; $i -lt $total; $i++) {
    $t = $i / $sampleRate
    $progress = $i / $total
    $freq = 520.0 + (900.0 * [Math]::Sin([Math]::PI * $progress))
    $env = [Math]::Sin([Math]::PI * $progress) * (0.8 + 0.2 * [Math]::Sin([Math]::PI * $progress))
    $wave = 0.8 * [Math]::Sin(2 * [Math]::PI * $freq * $t) + 0.2 * [Math]::Sin(4 * [Math]::PI * $freq * $t)
    $samples[$i] = $wave * $env * 0.70
}
[System.IO.File]::WriteAllBytes("$soundsDir\mascot_swoop.wav", (Create-WavBytes $samples $sampleRate))
Write-Host "Created mascot_swoop.wav"
