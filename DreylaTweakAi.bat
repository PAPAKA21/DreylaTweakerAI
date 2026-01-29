@echo off
pushd "%~dp0" 2>nul || cd /d "%~dp0"
chcp 65001 >nul

:: --- ADMIN CHECK ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [Dreyla]: Need Admin rights! Requesting...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: --- SETTINGS ---
set "CV=3.19.16"
set "U_VER=https://raw.githubusercontent.com/PAPAKA21/DreylaTweakerAI/main/Version.txt"
set "U_FILE=https://raw.githubusercontent.com/PAPAKA21/DreylaTweakerAI/main/DreylaTweakAi.bat"

:: --- UPDATE CHECK ---
echo [Dreyla]: Я ищу обновления, еще чуть чуть, и будет что-то новенькое...
powershell -NoProfile -Command "$w=New-Object Net.WebClient;$v=$w.DownloadString('%U_VER%').Trim();if([version]$v -gt [version]'%CV%'){exit 1}else{exit 0}"
if %errorlevel% equ 1 (
    echo [Dreyla]: Я нашла обновления, там что-то новенькое, поехали!
    powershell -NoProfile -Command "(New-Object Net.WebClient).DownloadFile('%U_FILE%', 'Dreyla_NEW.bat')"
    
    (
        echo @echo off
        echo timeout /t 2 ^>nul
        echo move /y "Dreyla_NEW.bat" "%~nx0"
        echo start "" "%~nx0"
        echo del "update.cmd"
    ) > update.cmd
    
    start "" update.cmd
    exit
)

:: --- LAUNCH ---
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -Path '%~f0' -Raw -Encoding UTF8) -replace '(?s)^.*?<#', '<#')"
if %errorlevel% neq 0 (
    echo.
    echo [Dreyla]: PowerShell exited with error!
    pause
)
exit /b
<#
#>

# --- ENGINE START ---
$Global:WorkDrive = "C"
$Global:AppsPath = "C:\Programs"

# Функция печатающейся машинки
function Write-Type {
    param(
        [string]$Text,
        [int]$Delay = 5,
        [string]$Color = "White"
    )
    $Text.ToCharArray() | ForEach-Object {
        Write-Host $_ -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

# Улучшенный тетрис
function Play-Tetris {
    Clear-Host
    $width = 12
    $height = 18
    $board = New-Object 'int[]' ($width * $height)
    $score = 0
    $level = 1
    $lines = 0
    
    try { [Console]::CursorVisible = $false } catch {}

    $shapes = @(
        @{ Coords = @(-1,0, 0,0, 1,0, 2,0); Color = "Cyan"; Char = "#" },
        @{ Coords = @(0,0, 1,0, 0,1, 1,1); Color = "Yellow"; Char = "#" },
        @{ Coords = @(-1,0, 0,0, 1,0, 0,1); Color = "Magenta"; Char = "#" },
        @{ Coords = @(0,0, 1,0, -1,1, 0,1); Color = "Green"; Char = "#" },
        @{ Coords = @(-1,0, 0,0, 0,1, 1,1); Color = "Red"; Char = "#" },
        @{ Coords = @(-1,0, 0,0, 1,0, 1,1); Color = "Blue"; Char = "#" },
        @{ Coords = @(-1,0, 0,0, 1,0, -1,1); Color = "White"; Char = "#" }
    )

    while ($true) {
        $currentShapeIdx = Get-Random -Minimum 0 -Maximum 7
        $currentShape = $shapes[$currentShapeIdx].Coords
        $pieceColor = $shapes[$currentShapeIdx].Color
        $pieceChar = $shapes[$currentShapeIdx].Char
        $px = [int]($width / 2) - 1
        $py = 0
        
        function Test-Collision($tx, $ty, $shape) {
            for ($i = 0; $i -lt $shape.Length; $i += 2) {
                $cx = $tx + $shape[$i]
                $cy = $ty + $shape[$i+1]
                if ($cx -lt 0 -or $cx -ge $width -or $cy -ge $height) { return $true }
                if ($cy -ge 0) {
                   if ($board[$cy * $width + $cx] -ne 0) { return $true }
                }
            }
            return $false
        }

        if (Test-Collision $px $py $currentShape) {
            Write-Host "`n[X] GAME OVER! [X]" -ForegroundColor Red
            Write-Host "[!] Final Score: $score | Lines: $lines | Level: $level" -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            try { [Console]::CursorVisible = $true } catch {}
            return
        }

        $locked = $false
        $gravityTimer = 0
        $gravityLimit = [math]::Max(2, 8 - $level)

        while (-not $locked) {
            if ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true).Key
                if ($k -eq 'Escape') { try { [Console]::CursorVisible = $true } catch {}; return }
                
                $dx = 0; $dy = 0
                if ($k -eq 'LeftArrow') { $dx = -1 }
                if ($k -eq 'RightArrow') { $dx = 1 }
                if ($k -eq 'DownArrow') { $dy = 1; $score += 1 }
                if ($k -eq 'UpArrow') {
                    if ($currentShapeIdx -ne 1) {
                         $newShape = $currentShape.Clone()
                         for ($i = 0; $i -lt $newShape.Length; $i += 2) {
                             $ox = $newShape[$i]; $oy = $newShape[$i+1]
                             $newShape[$i] = -$oy
                             $newShape[$i+1] = $ox
                         }
                         if (-not (Test-Collision $px $py $newShape)) {
                             $currentShape = $newShape
                         }
                    }
                }

                if ($dx -ne 0) {
                    if (-not (Test-Collision ($px + $dx) $py $currentShape)) { $px += $dx }
                }
                if ($dy -ne 0) {
                    if (-not (Test-Collision $px ($py + 1) $currentShape)) { 
                        $py += $dy
                        $score += 2
                    }
                }
            }

            # Очистка и рендер
            [Console]::SetCursorPosition(0, 0)
            Write-Host "+-------------------------------------------------------------+" -ForegroundColor Cyan
            Write-Host "|                    [#] TETRIS v3.01 [#]                     |" -ForegroundColor Yellow
            Write-Host "| Score: $score  |  Lines: $lines  |  Level: $level  |  Esc: Exit |" -ForegroundColor White
            Write-Host "+-------------------------------------------------------------+" -ForegroundColor Cyan
            
            $renderBuf = $board.Clone()
            for ($i = 0; $i -lt $currentShape.Length; $i += 2) {
                $cx = $px + $currentShape[$i]
                $cy = $py + $currentShape[$i+1]
                if ($cy -ge 0 -and $cy -lt $height -and $cx -ge 0 -and $cx -lt $width) {
                    $renderBuf[$cy * $width + $cx] = 2
                }
            }

            for ($y = 0; $y -lt $height; $y++) {
                Write-Host "|" -NoNewline -ForegroundColor Cyan
                for ($x = 0; $x -lt $width; $x++) {
                    $val = $renderBuf[$y * $width + $x]
                    if ($val -eq 0) { 
                        Write-Host "  " -NoNewline 
                    }
                    elseif ($val -eq 2) { 
                        Write-Host "$pieceChar$pieceChar" -NoNewline -ForegroundColor $pieceColor 
                    }
                    else { 
                        Write-Host "##" -NoNewline -ForegroundColor Gray 
                    }
                }
                Write-Host "|" -ForegroundColor Cyan
            }
            
            Write-Host "+-------------------------------------------------------------+" -ForegroundColor Cyan

            $gravityTimer++
            if ($gravityTimer -ge $gravityLimit) {
                $gravityTimer = 0
                if (-not (Test-Collision $px ($py + 1) $currentShape)) {
                    $py++
                } else {
                    for ($i = 0; $i -lt $currentShape.Length; $i += 2) {
                        $cx = $px + $currentShape[$i]
                        $cy = $py + $currentShape[$i+1]
                        if ($cy -ge 0 -and $cx -ge 0 -and $cx -lt $width -and $cy -lt $height) {
                            $board[$cy * $width + $cx] = 1
                        }
                    }
                    $locked = $true
                    
                    $linesCleared = 0
                    for ($y = 0; $y -lt $height; $y++) {
                        $rowFull = $true
                        for ($x = 0; $x -lt $width; $x++) { 
                            if ($board[$y * $width + $x] -eq 0) { 
                                $rowFull = $false; break 
                            } 
                        }
                        
                        if ($rowFull) {
                            $linesCleared++
                            for ($ky = $y; $ky -gt 0; $ky--) {
                                for ($kx = 0; $kx -lt $width; $kx++) {
                                    $board[$ky * $width + $kx] = $board[($ky - 1) * $width + $kx]
                                }
                            }
                            for ($kx = 0; $kx -lt $width; $kx++) { $board[$kx] = 0 }
                        }
                    }
                    
                    if ($linesCleared -gt 0) { 
                        $lines += $linesCleared
                        $score += $linesCleared * 100 * $linesCleared * $level
                        if ($lines -ge $level * 10) {
                            $level++
                            Write-Host "`n[!] LEVEL UP! Now level $level" -ForegroundColor Yellow -BackgroundColor DarkGreen
                            Start-Sleep -Milliseconds 500
                        }
                    }
                }
            }
            Start-Sleep -Milliseconds 50
        }
    }
}


# змейка
function Play-Snake {
    Clear-Host
    $width = 30
    $height = 15

    $snake = @(@{ X = [int]($width / 2); Y = [int]($height / 2) })
    $dx = 1
    $dy = 0
    $score = 0
    $highScore = 0

    function New-SnakeFood {
        param($snakeBody, $w, $h)
        while ($true) {
            $fx = Get-Random -Minimum 1 -Maximum ($w - 1)
            $fy = Get-Random -Minimum 1 -Maximum ($h - 1)
            if (-not ($snakeBody | Where-Object { $_.X -eq $fx -and $_.Y -eq $fy })) {
                return @{ X = $fx; Y = $fy }
            }
        }
    }

    $food = New-SnakeFood -snakeBody $snake -w $width -h $height

    while ($true) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true).Key
            switch ($key) {
                'W' { if ($dy -ne 1)  { $dx = 0;  $dy = -1 } }
                'S' { if ($dy -ne -1) { $dx = 0;  $dy = 1 } }
                'A' { if ($dx -ne 1)  { $dx = -1; $dy = 0 } }
                'D' { if ($dx -ne -1) { $dx = 1;  $dy = 0 } }
                'Escape' { 
                    try { [Console]::CursorVisible = $true } catch {}
                    return 
                }
            }
        }

        $head = $snake[0]
        $newHead = @{
            X = $head.X + $dx
            Y = $head.Y + $dy
        }

        if ($newHead.X -le 0 -or $newHead.X -ge ($width - 1) -or
            $newHead.Y -le 0 -or $newHead.Y -ge ($height - 1)) {
            break
        }

        if ($snake | Where-Object { $_.X -eq $newHead.X -and $_.Y -eq $newHead.Y }) {
            break
        }

        $snake = ,$newHead + $snake

        if ($newHead.X -eq $food.X -and $newHead.Y -eq $food.Y) {
            $score += 10
            if ($score -gt $highScore) { $highScore = $score }
            $food = New-SnakeFood -snakeBody $snake -w $width -h $height
            
            try { [Console]::Beep(800, 50) } catch {}
        }
        else {
            if ($snake.Count -gt 1) {
                $snake = $snake[0..($snake.Count - 2)]
            }
        }

        Clear-Host
        Write-Host "+--------------------------------------------------------------------------+" -ForegroundColor Green
        Write-Host "|                    [S] ЗМЕЙКА v0.12 [S]                      |" -ForegroundColor Yellow
        Write-Host "| Score: $score  |  High Score: $highScore  |  ESC: Exit       |" -ForegroundColor Cyan
        Write-Host "+--------------------------------------------------------------------------+" -ForegroundColor Green
        Write-Host " Управление: W A S D | ESC - выход" -ForegroundColor DarkGray

        for ($y = 0; $y -lt $height; $y++) {
            $line = ""
            for ($x = 0; $x -lt $width; $x++) {
                if ($y -eq 0 -or $y -eq ($height - 1) -or $x -eq 0 -or $x -eq ($width - 1)) {
                    $line += "#"
                }
                elseif ($x -eq $food.X -and $y -eq $food.Y) {
                    $line += "O"
                }
                elseif ($snake | Where-Object { $_.X -eq $x -and $_.Y -eq $y }) {
                    $line += "*"
                }
                else {
                    $line += " "
                }
            }
            Write-Host $line -ForegroundColor White
        }

        Start-Sleep -Milliseconds 100
    }

    Clear-Host
    Write-Host "[X] GAME OVER! [X]" -ForegroundColor Red
    Write-Host "[!] Final Score: $score | High Score: $highScore" -ForegroundColor Yellow
    Write-Host "`nНажми любую клавишу..." -ForegroundColor DarkGray
    try { [Console]::CursorVisible = $true } catch {}
    [Console]::ReadKey($true) | Out-Null
}

# окна консоли
function Set-ConsolePosition {
    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Pos {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
"@ -ErrorAction SilentlyContinue

        $hwnd = [Win32Pos]::GetConsoleWindow()
        if ($hwnd -ne [IntPtr]::Zero) {
            # Переместим окно примерно в верхнюю треть экрана
            $SWP_NOSIZE = 0x0001
            $SWP_NOZORDER = 0x0004
            [Win32Pos]::SetWindowPos($hwnd, [IntPtr]::Zero, 120, 80, 0, 0, $SWP_NOSIZE -bor $SWP_NOZORDER) | Out-Null
        }
    } catch {
        # Если что-то пошло не так — просто игнорируем, твикер всё равно продолжит работать
    }
}

# Matrix режим
function Run-Matrix {
    Clear-Host
    $host.UI.RawUI.WindowTitle = "MATRIX MODE - DREYLA"
    $width = $host.UI.RawUI.WindowSize.Width
    $height = $host.UI.RawUI.WindowSize.Height
    $columns = @()
    $chars = "01ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()_+-=[]{}|;:,.<>?"
    
    for ($i = 0; $i -lt $width; $i++) {
        $columns += @{
            Y = Get-Random -Maximum $height
            Speed = Get-Random -Minimum 1 -Maximum 4
            Length = Get-Random -Minimum 5 -Maximum 15
        }
    }
    
    try { [Console]::CursorVisible = $false } catch {}
    
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        
        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $col = $columns[$x]
                
                if ($y -ge ($col.Y - $col.Length) -and $y -le $col.Y) {
                    $distance = $col.Y - $y
                    
                    if ($distance -eq 0) {
                        Write-Host $chars[(Get-Random -Maximum $chars.Length)] -NoNewline -ForegroundColor White
                    }
                    elseif ($distance -lt 3) {
                        Write-Host $chars[(Get-Random -Maximum $chars.Length)] -NoNewline -ForegroundColor Green
                    }
                    else {
                        Write-Host $chars[(Get-Random -Maximum $chars.Length)] -NoNewline -ForegroundColor DarkGreen
                    }
                }
                else {
                    Write-Host " " -NoNewline
                }
            }
        }
        
        for ($i = 0; $i -lt $width; $i++) {
            $columns[$i].Y += $columns[$i].Speed
            
            if ($columns[$i].Y -gt $height + $columns[$i].Length) {
                $columns[$i].Y = -$columns[$i].Length
                $columns[$i].Speed = Get-Random -Minimum 1 -Maximum 4
                $columns[$i].Length = Get-Random -Minimum 5 -Maximum 15
            }
        }
        
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true).Key
            if ($key -eq 'Escape') { break }
        }
        
        Start-Sleep -Milliseconds 50
    }
    
    try { [Console]::CursorVisible = $true } catch {}
    Clear-Host
}


# Рандомные фразы от твикера
function Show-RandomQuote {
    $quotes = @(
        "Dreyla: если что-то лагает — значит, оно ещё живо."
        "AI-совет: перед твиком сделай точку восстановления. А лучше две."
        "Секретный твик: не ставь говносборки, и жизнь станет легче."
        "Оптимизация — это искусство убирать лишнее, а не ломать всё."
        "Если Windows не ломалась 3 дня — ты что-то замышляешь, да?"
        "Dreyla: У Папакера есть проблемы со здоровьем, и психический тоже."
        "Dreyla: Идея создать меня возникла случайно, когда мы тестировали модели искусственного интеллекта для генерации картинок."
        "Папака: Windows Defender никогда не жалуется на VPN и ZAPRET обходы, Zapret Обходы открываются только через BAT файлы."
        "Dreyla: Когда придумали мне фиолетовый стиль одежды, волос, а так же глаз, была трудность, утвердить возраст."
        "Dreyla: Win или Linux? Честно есть простой ответ. WIN - для людей, LINUX - для тех, кому нечего делать (Пользователь Linux)."
        "Dreyla: Проблемы ИИ, дорого, слопно, люди не умеют пользоваться, умели бы, не говорили что Шмайсер придумал АК."
        "Dreyla: Когда мы делали этот скрипт, мы не знали ничего о том, что вообще делаем, но знали что тетрист точно нужен."
        "Папака: Имя для Дрейлы, выбрали подписчики"
        "Факт: Хуже проблем с ИИ могут быть только проблемы со страной."
        "[>] FIXED EDITION: Теперь без багов и дублирования!",
        "[+] v3.06: Плавная навигация и красивый интерфейс!"
        "[*] Больше никаких проблем с меню!"
        "[#] Игры работают идеально!"
        "[*] Есть еще ошибки"
        "[fix] Все функции проверены и исправлены!"
        "[+] v3.15: Настолько нестабильна, что отключила интернет, причина: Она просто запуталась."
        "[+] v3.18: Не работал тетрис."
        "[+] v3.19: Попытка добавить модель Dreyla AI. Увы Дрейла решила снести WIN на VMware (Да она это смогла.) "
        "[+] Папака: Я хочу сменить Vegas на Davinci, но там сложно, и запутанно, что выводит меня из себя. И мне не стыдно. "
        "v3.19.1: Версия где мы удалили ИИ Дрейлы, в 3.19 она могла снести все, вплодь до системы."
    )
    $q = Get-Random -InputObject $quotes
    Write-Host "  $q" -ForegroundColor DarkGray
}

# Баннер с информацией о системе
function Show-SystemBanner {
    Show-Header "SYSTEM INFO"
    $os  = Get-CimInstance Win32_OperatingSystem
    $cs  = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)

    Write-Host "╔══════════ DETAIL ══════════════╗" -ForegroundColor Cyan
    Write-Host "║ OS:   $($os.Caption)  (Build $($os.BuildNumber))" -ForegroundColor Gray
    Write-Host "║ CPU:  $($cpu.Name.Trim())" -ForegroundColor Gray
    Write-Host "║ RAM:  $ramGB GB" -ForegroundColor Gray
    Write-Host "╚════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Нажми любую клавишу, чтобы вернуться в меню." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}

# Улучшенный бенчмарк
function Run-MicroBenchmark {
    Show-Header "--- [>] УЛУЧШЕННЫЙ БЕНЧМАРК v0.06 ---"
    Write-Host "[!] Комплексный тест: CPU, RAM, Диск" -ForegroundColor DarkGray
    Write-Host "[+] C багами и с красивой визуализацией" -ForegroundColor DarkGray
    
    if (-not (Show-Confirmation "[>] Запустить бенчмарк (~30 сек)?")) { return }

    Write-Host "`n[...] Подготовка к тесту..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1

    # Progress Bar Helper
    function Show-Progress {
        param($Label)
        Write-Host -NoNewline " $Label ["
        for ($p=0; $p -lt 20; $p++) {
            Write-Host -NoNewline "▓" -ForegroundColor Cyan
            Start-Sleep -Milliseconds 20
        }
        Write-Host "] OK" -ForegroundColor Green
    }

    # CPU Test
    Show-Progress "Testing CPU "
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $iterations = 300000
    $acc = 0.0
    for ($i = 1; $i -le $iterations; $i++) {
        $acc += [math]::Sqrt($i) / ($i + 1)
    }
    $sw.Stop()
    $ms = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)

    # RAM Test
    Show-Progress "Testing RAM "
    $swRam = [System.Diagnostics.Stopwatch]::StartNew()
    $testArray = @()
    for ($i = 0; $i -lt 50000; $i++) {
        $testArray += "TestString_$i"
    }
    $swRam.Stop()
    $ramMs = [math]::Round($swRam.Elapsed.TotalMilliseconds, 1)
    $testArray = $null
    [System.GC]::Collect()

    # Disk Test
    Show-Progress "Testing DISK"
    $diskFile = Join-Path $env:TEMP "dreyla_bench.tmp"
    $data = "X" * 1024 * 512
    
    $swDiskWrite = [System.Diagnostics.Stopwatch]::StartNew()
    Set-Content -Path $diskFile -Value $data -Encoding ASCII -ErrorAction SilentlyContinue
    $swDiskWrite.Stop()
    
    $swDiskRead = [System.Diagnostics.Stopwatch]::StartNew()
    Get-Content -Path $diskFile -Encoding ASCII -ErrorAction SilentlyContinue | Out-Null
    $swDiskRead.Stop()
    
    Remove-Item -Path $diskFile -ErrorAction SilentlyContinue
    
    $diskWriteMs = [math]::Round($swDiskWrite.Elapsed.TotalMilliseconds, 2)
    $diskReadMs  = [math]::Round($swDiskRead.Elapsed.TotalMilliseconds, 2)

    # AI Section (Commented Future Update)
    # Write-Host "`n[AI] Analysing Results with Local LLM..." -ForegroundColor Magenta
    # Start-Sleep -Seconds 2
    # Write-Host "[AI] Optimization suggestions ready." -ForegroundColor Green
    
    # Результаты
    $tier = ""
    $comment = ""
    $color = ""
    
    if ($ms -lt 150) {
        $tier = "S+ (GODLIKE)"
        $comment = "[!] МОНСТР! Твой ПК - ракета!"
        $color = "Green"
    }
    elseif ($ms -lt 300) {
        $tier = "S (EXCELLENT)"
        $comment = "[+] ОТЛИЧНО! Гейминг на ультрах!"
        $color = "Cyan"
    }
    elseif ($ms -lt 500) {
        $tier = "A (GOOD)"
        $comment = "[OK] ХОРОШО! Комфортный гейминг!"
        $color = "Yellow"
    }
    else {
        $tier = "B (NORMAL)"
        $comment = "[OK] НОРМАЛЬНО! Играбельно!"
        $color = "DarkYellow"
    }

    Write-Host "`n" + "═" * 50 -ForegroundColor DarkCyan
    Write-Host "[#] РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "═" * 50 -ForegroundColor DarkCyan
    
    Write-Host "`n[CPU] Время: $ms мс | Ранг: $tier" -ForegroundColor Green
    Write-Host "[RAM] Время: $ramMs мс" -ForegroundColor Magenta
    Write-Host "[DSK] Запись: $diskWriteMs мс | Чтение: $diskReadMs мс" -ForegroundColor Blue
    
    Write-Host "`n" + "═" * 50 -ForegroundColor DarkCyan
    Write-Host $comment -ForegroundColor $color
    Write-Host "═" * 50 -ForegroundColor DarkCyan
    
    # Write-Host "[AI] AI Feature coming in v4.0..." -ForegroundColor DarkGray
    
    Write-Host "`nНажми любую клавишу..." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}


# О твикере / Credits
function Show-About {
    Show-Header "--- Авторы / DreylaAI ---"
    Write-Host ""
    Write-Type "Этот твикер сделан, чтобы любая винда чувствовала себя как после санатория." -Delay 8 -Color Cyan
    Write-Type "Dreyla старается убрать лишний мусор, поставить нужный софт и не сжечь тебе мозг сложными меню." -Delay 8 -Color Cyan
    Write-Type "Если вы читаете это, будьте осторожны перед тем как выбрать что отключить." -Delay 8 -Color Cyan
    Write-Type "Почему в консоле? Потому что так проще мне понять что я пишу, я не программист," -Delay 8 -Color Red
    Write-Type "помогла модель Dreyla, эту модель вы не найдете." -Delay 8 -Color Red
    Write-Type "ОБНОВЛЕНИЕ И ПРОВЕРКА!" -Delay 8 -Color Red
    Write-Host ""
    Write-Type "Автор сборки: Папака + немного помощи от Dreyla AI." -Delay 8 -Color Yellow
    Write-Type "Если тебе зашло — не ставь говносборки, ставь оригинал и твикер." -Delay 8 -Color Yellow
    Write-Host ""
    Write-Host "Нажми любую клавишу, чтобы вернуться." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}

function Show-Logo {
    Clear-Host
    $colors = @("Cyan", "DarkCyan", "Blue", "Magenta", "DarkMagenta")
    $logo = @(
        "    ██████╗ ██████╗ ███████╗██╗   ██╗██╗      █████╗ ",
        "    ██╔══██╗██╔══██╗██╔════╝╚██╗ ██╔╝██║     ██╔══██╗",
        "    ██║  ██║██████╔╝█████╗   ╚████╔╝ ██║     ███████║",
        "    ██║  ██║██╔══██╗██╔══╝    ╚██╔╝  ██║     ██╔══██║",
        "    ██████╔╝██║  ██║███████╗   ██║   ███████╗██║  ██║",
        "    ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝",
        "             PREMIUM OPTIMIZER | v3.19.16 Test Update | BY PAPAKA & DreylaAI"
    )
    
    foreach ($line in $logo) {
        $c = Get-Random -InputObject $colors
        Write-Host $line -ForegroundColor $c
    }
}



function Show-Spinner {
    param([string]$Activity)
    $spins = @("|", "/", "-", "\")
    Write-Host "  (∩^o^)⊃━☆ﾟ.*･｡ $Activity " -NoNewline -ForegroundColor Yellow
    for($i=0; $i -lt 12; $i++) {
        foreach ($s in $spins) {
            Write-Host "$s`b" -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 40
        }
    }
    Write-Host "[ УСПЕХ! ] Сделано! Ня! ✨" -ForegroundColor Green
    [Console]::Beep(1000, 150)
}


# --- FUNCTIONS ---
function Init-Setup {
    Set-ConsolePosition
    Show-Logo

    # Вступительный текст с эффектом печатной машинки
    Write-Host ""
    Write-Type "Приветик! (◕‿◕) Давай выберем домик для твоих программок!" -Delay 5 -Color Cyan
    Write-Type "Там будут жить все твои игры и программки, чтобы на диске C было чисто-чисто! ✨" -Delay 5 -Color Cyan
    Write-Type "Я люблю порядок, и ты тоже, правда? (´｡• ᵕ •｡`)" -Delay 5 -Color Cyan
    Write-Host ""
    Write-Type "Выбери буковку диска, пожалуйста! Если у тебя только C, то просто нажми Enter! (｡•̀ᴗ-)" -Delay 5 -Color Cyan
    Write-Type "А если есть другой (например, D или E), напиши его буковку! Я пойму!" -Delay 5 -Color Cyan
    Write-Host ""

    # Блок предупреждения
    Write-Host "══════════════════════════════════════════" -ForegroundColor DarkRed
    Write-Type "ОЙ-ОЙ! ВНИМАНИЕ! (O_O;)" -Delay 20 -Color Red
    Write-Type "Если у тебя какая-то странная сборка винды (не оригинал)..." -Delay 5 -Color Red
    Write-Type "То может не быть WINGET! Но я постараюсь справиться!" -Delay 5 -Color Red
    Write-Host "══════════════════════════════════════════" -ForegroundColor DarkRed
    Write-Host ""

    Write-Type "Я старалась сделать всё удобным и простым! Это моя первая версия на PowerShell! (≧◡≦)" -Delay 5 -Color Cyan
    Write-Type "Надеюсь, тебе понравится! Мур! ~" -Delay 5 -Color Cyan
    Write-Host ""

    Write-Type ">>> Приветик! Я Дрейла! Давай наведем красоту! (✿◠‿◠)" -Delay 15
    Write-Host "`Где будем строить базу? (Программы, игры...)" -ForegroundColor White
    Write-Host "Если диск один, просто жми Enter (C)." -ForegroundColor Gray
    
    $inputDrive = Read-Host "`n > Буква диска"
    $cleanDrive = $inputDrive -replace ":", "" -replace " ", ""
    if (-not $cleanDrive) { $cleanDrive = "C" }
    $Global:WorkDrive = $cleanDrive.ToUpper()
    $Global:AppsPath = "$($Global:WorkDrive):\Programs"
    
    Show-Spinner "Подключаюсь к диску... "
}

# --- СПИСОК ВСЕГО МУСОРА ---
$Global:GarbageList = @(
    # [SAFE] Безопасные для удаления (Новости, Погода, Советы)
    @{ID=1;  Category="SAFE"; Name="Microsoft.BingNews"; Desc="Новости Bing"},
    @{ID=2;  Category="SAFE"; Name="Microsoft.BingWeather"; Desc="Погода"},
    @{ID=3;  Category="SAFE"; Name="Microsoft.GetHelp"; Desc="Get Help (Техподдержка)"},
    @{ID=4;  Category="SAFE"; Name="Microsoft.Getstarted"; Desc="Советы (Get Started)"},
    @{ID=5;  Category="SAFE"; Name="Microsoft.Messaging"; Desc="Сообщения"},
    @{ID=6;  Category="SAFE"; Name="Microsoft.Microsoft3DViewer"; Desc="3D Viewer"},
    @{ID=7;  Category="SAFE"; Name="Microsoft.MicrosoftSolitaireCollection"; Desc="Solitaire Collection"},
    @{ID=8;  Category="SAFE"; Name="Microsoft.MixedReality.Portal"; Desc="Mixed Reality Portal"},
    @{ID=9;  Category="SAFE"; Name="Microsoft.OneConnect"; Desc="Платный Wi-Fi и сотовая связь"},
    @{ID=10; Category="SAFE"; Name="Microsoft.People"; Desc="People / Люди"},
    @{ID=11; Category="SAFE"; Name="Microsoft.Print3D"; Desc="Print 3D"},
    @{ID=12; Category="SAFE"; Name="Microsoft.SkypeApp"; Desc="Skype"},
    @{ID=13; Category="SAFE"; Name="Microsoft.Todos"; Desc="Microsoft To-Do"},
    @{ID=14; Category="SAFE"; Name="Microsoft.WindowsAlarms"; Desc="Будильник и часы"},
    @{ID=15; Category="SAFE"; Name="Microsoft.WindowsFeedbackHub"; Desc="Центр отзывов"},
    @{ID=16; Category="SAFE"; Name="Microsoft.WindowsMaps"; Desc="Карты"},
    @{ID=17; Category="SAFE"; Name="Microsoft.WindowsSoundRecorder"; Desc="Запись голоса"},
    @{ID=18; Category="SAFE"; Name="Microsoft.YourPhone"; Desc="Связь с телефоном"},
    @{ID=19; Category="SAFE"; Name="Microsoft.ZuneMusic"; Desc="Музыка Groove"},
    @{ID=20; Category="SAFE"; Name="Microsoft.ZuneVideo"; Desc="Кино и ТВ"},
    @{ID=21; Category="SAFE"; Name="Microsoft.Office.OneNote"; Desc="OneNote"},
    @{ID=22; Category="SAFE"; Name="Microsoft.MSPaint"; Desc="Paint 3D"},
    @{ID=23; Category="SAFE"; Name="Clipchamp.Clipchamp"; Desc="Clipchamp (Видеоредактор)"},
    @{ID=24; Category="SAFE"; Name="Microsoft.549981C3F5F10"; Desc="Cortana"},

    # [PRIVACY] Телеметрия и слежка
    @{ID=30; Category="PRIVACY"; Name="Telemetry"; Desc="Службы телеметрии (DiagTrack)"},
    @{ID=31; Category="PRIVACY"; Name="Advertising"; Desc="Рекламный ID"},
    @{ID=32; Category="PRIVACY"; Name="Schedules"; Desc="Планировщик (Сбор данных)"},

    # [DEEP] Глубокая очистка (Может удалить нужное)
    @{ID=40; Category="DEEP"; Name="OneDrive"; Desc="OneDrive (Полное удаление)"},
    @{ID=41; Category="DEEP"; Name="Xbox"; Desc="Все службы Xbox"},
    @{ID=42; Category="DEEP"; Name="Edge"; Desc="Edge (Браузер)"},
    @{ID=43; Category="DEEP"; Name="Microsoft.WindowsStore"; Desc="Microsoft Store (Магазин)"},
    @{ID=44; Category="DEEP"; Name="Microsoft.WindowsCamera"; Desc="Камера"},
    @{ID=45; Category="DEEP"; Name="Microsoft.Windows.Photos"; Desc="Фотографии"},
    @{ID=46; Category="DEEP"; Name="Microsoft.ScreenSketch"; Desc="Набросок на фрагменте экрана"},
    @{ID=47; Category="DEEP"; Name="Microsoft.WindowsCalculator"; Desc="Калькулятор"},
    @{ID=48; Category="DEEP"; Name="Microsoft.Wallet"; Desc="Кошелек"},
    @{ID=49; Category="DEEP"; Name="Microsoft.WindowsCommunicationsApps"; Desc="Почта и Календарь"},
    
    # [DEEP+] Extra Junk
    @{ID=50; Category="DEEP"; Name="Microsoft.Windows.HolographicFirstRun"; Desc="Mixed Reality (Holographic)"},
    @{ID=51; Category="DEEP"; Name="Microsoft.ParentalControls"; Desc="Parental Controls"},
    @{ID=52; Category="DEEP"; Name="Microsoft.BioEnrollment"; Desc="Windows Hello Setup"},
    @{ID=53; Category="DEEP"; Name="Microsoft.XboxGameCallableUI"; Desc="Xbox Game UI"},
    @{ID=54; Category="DEEP"; Name="Microsoft.XboxSpeechToTextOverlay"; Desc="Xbox Speech Overlay"},
    @{ID=55; Category="DEEP"; Name="Microsoft.Windows.PeopleExperienceHost"; Desc="People Bar"},
    @{ID=56; Category="DEEP"; Name="Microsoft.Windows.ContentDeliveryManager"; Desc="Windows Spotlight / Suggestions"},
    @{ID=57; Category="DEEP"; Name="Microsoft.Windows.SecHealthUI"; Desc="Windows Defender UI (ОПАСНО)"},
    @{ID=58; Category="DEEP"; Name="Microsoft.Windows.SmartScreen"; Desc="SmartScreen (ОПАСНО)"},
    @{ID=59; Category="DEEP"; Name="Microsoft.ECApp"; Desc="Eye Control (Управление глазами)"},
    @{ID=60; Category="DEEP"; Name="Microsoft.LockApp"; Desc="Lock Screen App (Экран блокировки)"},
    @{ID=61; Category="DEEP"; Name="Microsoft.Windows.Ai.Copilot.Provider"; Desc="Copilot (AI Assistant)"},
    @{ID=62; Category="DEEP"; Name="Microsoft.Copilot"; Desc="Copilot App"}
)

function Start-Debloat {
    $debloatMenu = @(
        @{Label="1. SAFE (БЕЗОПАСНО) - Новости, Погода, Советы, Скайп и прочее"; Value="1"},
        @{Label="2. BALANCED (ОПТИМАЛЬНО) - Safe + Телеметрия + Реклама"; Value="2"},
        @{Label="3. FULL (ОПАСНО) - Удалить ВСЁ (Edge, Xbox, Store, Defender UI)"; Value="3"},
        @{Label="4. CUSTOM (ВРУЧНУЮ) - Выбор из списка"; Value="4"},
        @{Label="0. Назад"; Value="0"}
    )
    
    $mode = Show-Menu-Interactive "--- МАСТЕР ОЧИСТКИ (DEBLOAT) ---" $debloatMenu
    
    $toDelete = @()

    switch ($mode) {
        "1" { 
            if (Show-Confirmation "Удалить безопасный мусор (Новости, Погода...)?") {
                $toDelete = $Global:GarbageList | Where-Object { $_.Category -eq "SAFE" } 
            }
        }
        "2" { 
            if (Show-Confirmation "Удалить Safe + Телеметрию + Рекламу?") {
                $toDelete = $Global:GarbageList | Where-Object { $_.Category -in @("SAFE", "PRIVACY") } 
            }
        }
        "3" { 
            Write-Host "`nВНИМАНИЕ! Вы выбрали удаление ВСЕГО (ЯДЕРНЫЙ РЕЖИМ)." -ForegroundColor Red
            Write-Host "Это удалит Магазин, Калькулятор, Фото, Edge, Xbox, Hello и прочее." -ForegroundColor Red
            if (Show-Confirmation "Вы ТОЧНО уверены? Это может сломать функции ОС.") {
                $toDelete = $Global:GarbageList 
            }
        }
        "4" {
            $customOptions = @()
            foreach ($item in $Global:GarbageList) {
                $catTag = "[$($item.Category)]"
                $customOptions += @{Label="$catTag $($item.Desc)"; Value=$item.ID}
            }
            
            $selectedIDs = Show-MultiSelect-Interactive "--- ВЫБОР КОМПОНЕНТОВ ---" $customOptions
            $toDelete = $Global:GarbageList | Where-Object { $selectedIDs -contains $_.ID }
        }
        "0" { return }
        "EXIT" { return }
    }

    if ($toDelete.Count -eq 0) { return }

    Clear-Host
    Write-Host "ВЫБРАНО К УДАЛЕНИЮ:" -ForegroundColor Yellow
    foreach ($item in $toDelete) {
        $col = "Gray"
        if ($item.Category -eq "DEEP") { $col = "Red" }
        Write-Host " - $($item.Desc)" -ForegroundColor $col
    }
    
    if (-not (Show-Confirmation "Начать уничтожение $($toDelete.Count) объектов?")) { return }

    foreach ($item in $toDelete) {
        Show-Spinner "Удаление [$($item.Category)]: $($item.Desc)"
        
        # Special Handlers
        if ($item.Name -eq "Telemetry") {
            Stop-Service "DiagTrack" -ErrorAction SilentlyContinue
            Set-Service "DiagTrack" -StartupType Disabled
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
            continue
        }
        if ($item.Name -eq "Advertising") {
             reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
             continue
        }
        if ($item.Name -eq "Schedules") {
             Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" | Disable-ScheduledTask -ErrorAction SilentlyContinue
             continue
        }
        if ($item.Name -eq "OneDrive") {
             taskkill /f /im OneDrive.exe /t | Out-Null
             $os = if ([Environment]::Is64BitOperatingSystem) { "SysWOW64" } else { "System32" }
             Start-Process "$env:SystemRoot\$os\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
             continue
        }
        if ($item.Name -eq "Xbox") {
             Get-AppxPackage -AllUsers "*Xbox*" | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
             continue
        }
        if ($item.Name -eq "Edge") {
             $edgePath = (Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application" -Filter "setup.exe" -Recurse | Select-Object -First 1).FullName
             if ($edgePath) { Start-Process $edgePath -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait }
             continue
        }

        # Standard Appx Removal
        Get-AppxPackage -AllUsers "*$($item.Name)*" | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like "*$($item.Name)*"} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    
    Write-Host "`nВсё лишнее убрала! Теперь система легкая как перышко! 🕊️" -ForegroundColor Green
    Pause
}

function Start-PrivacyMenu {
    $privMenu = @(
        @{Label="1. [RECOMMENDED] ОТКЛЮЧИТЬ ВСЁ (Максимальная приватность)"; Value="1"},
        @{Label="2. Отключить телеметрию Windows (DiagTrack, DataCollection)"; Value="2"},
        @{Label="3. Отключить телеметрию Office (Все версии)"; Value="3"},
        @{Label="4. Отключить телеметрию NVIDIA (Службы, Задачи)"; Value="4"},
        @{Label="5. Отключить запись действий (Timeline, Activity Feed)"; Value="5"},
        @{Label="6. Отключить SmartScreen и SpyNet (Проверка файлов)"; Value="6"},
        @{Label="7. Отключить Местоположение (Location Service)"; Value="7"},
        @{Label="8. Отключить Рекламный ID и слежку приложений"; Value="8"},
        @{Label="9. Блокировать домены телеметрии (Hosts)"; Value="9"},
        @{Label="0. Назад"; Value="0"}
    )
    
    $p = Show-Menu-Interactive "--- ПРИВАТНОСТЬ И ТЕЛЕМЕТРИЯ ---" $privMenu
    
    switch ($p) {
        "1" {
            if (Show-Confirmation "Применить КОМПЛЕКСНУЮ защиту приватности?") {
                Show-Spinner "Отключение Телеметрии Windows"
                # Services
                Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
                Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
                Set-Service "DiagTrack" -StartupType Disabled
                Set-Service "dmwappushservice" -StartupType Disabled
                cmd.exe /c "sc config DiagTrack start= disabled" | Out-Null
                cmd.exe /c "sc config dmwappushservice start= disabled" | Out-Null
                
                # Registry Tweaks
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotCollectMyView" /t REG_DWORD /d 1 /f | Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f | Out-Null
                
                Show-Spinner "Отключение Задач сбора данных"
                $tasks = @(
                    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
                    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
                    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
                    "\Microsoft\Windows\Autochk\Proxy",
                    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
                    "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
                    "\Microsoft\Windows\Feedback\Siuf\DmClient"
                )
                foreach ($t in $tasks) { Disable-ScheduledTask -TaskPath $t -ErrorAction SilentlyContinue }

                Show-Spinner "Отключение Office Telemetry"
                reg add "HKCU\Software\Policies\Microsoft\Office\16.0\Common\General" /v "EnableLogging" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKCU\Software\Microsoft\Office\16.0\Common\Feedback" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
                
                Show-Spinner "Отключение NVIDIA Telemetry"
                Get-Service "NvTelemetryContainer" -ErrorAction SilentlyContinue | Stop-Service -Force
                Get-Service "NvTelemetryContainer" -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
                Get-ScheduledTask | Where-Object { $_.TaskName -like "*NvTelemetry*" } | Disable-ScheduledTask -ErrorAction SilentlyContinue
                
                Show-Spinner "Отключение Activity Feed"
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f | Out-Null
                
                Show-Spinner "Отключение SmartScreen"
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f | Out-Null
                
                Show-Spinner "Отключение Рекламного ID"
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
                
                Write-Host "Все настройки приватности применены!" -ForegroundColor Green
            }
        }
        "2" {
            if (Show-Confirmation "Отключить телеметрию Windows?") {
                Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
                Set-Service "DiagTrack" -StartupType Disabled
                cmd.exe /c "sc config DiagTrack start= disabled" | Out-Null
                
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f | Out-Null
                Get-ScheduledTask "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" | Disable-ScheduledTask -ErrorAction SilentlyContinue
                Write-Host "Телеметрия отключена." -ForegroundColor Green
            }
        }
        "3" {
            if (Show-Confirmation "Отключить телеметрию Office?") {
                reg add "HKCU\Software\Policies\Microsoft\Office\16.0\Common\General" /v "EnableLogging" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKCU\Software\Microsoft\Office\16.0\Common\Feedback" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
                Write-Host "Телеметрия Office отключена." -ForegroundColor Green
            }
        }
        "4" {
            if (Show-Confirmation "Отключить телеметрию NVIDIA?") {
                Get-Service "NvTelemetryContainer" -ErrorAction SilentlyContinue | Stop-Service -Force
                Get-Service "NvTelemetryContainer" -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
                Get-ScheduledTask | Where-Object { $_.TaskName -like "*NvTelemetry*" } | Disable-ScheduledTask -ErrorAction SilentlyContinue
                Write-Host "Телеметрия NVIDIA отключена." -ForegroundColor Green
            }
        }
        "5" {
            if (Show-Confirmation "Отключить Timeline и Activity Feed?") {
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f | Out-Null
                Write-Host "Запись действий отключена." -ForegroundColor Green
            }
        }
        "6" {
            if (Show-Confirmation "Отключить SmartScreen?") {
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f | Out-Null
                Write-Host "SmartScreen отключен." -ForegroundColor Green
            }
        }
        "7" {
            if (Show-Confirmation "Отключить службы местоположения?") {
                Stop-Service "lfsvc" -Force -ErrorAction SilentlyContinue
                Set-Service "lfsvc" -StartupType Disabled
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f | Out-Null
                Write-Host "Местоположение отключено." -ForegroundColor Green
            }
        }
        "8" {
            if (Show-Confirmation "Отключить рекламный ID?") {
                reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
                Write-Host "Рекламный ID отключен." -ForegroundColor Green
            }
        }
        "9" {
            if (Show-Confirmation "Блокировать домены телеметрии в HOSTS?") {
                $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
                $domains = @(
                    "0.0.0.0 v10.events.data.microsoft.com",
                    "0.0.0.0 v20.events.data.microsoft.com",
                    "0.0.0.0 vortex.data.microsoft.com",
                    "0.0.0.0 vortex-win.data.microsoft.com",
                    "0.0.0.0 telecommand.telemetry.microsoft.com",
                    "0.0.0.0 telecommand.telemetry.microsoft.com.nsatc.net",
                    "0.0.0.0 oca.telemetry.microsoft.com",
                    "0.0.0.0 oca.telemetry.microsoft.com.nsatc.net",
                    "0.0.0.0 sqm.telemetry.microsoft.com",
                    "0.0.0.0 sqm.telemetry.microsoft.com.nsatc.net"
                )
                
                try {
                    $content = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
                    $newContent = $content + "`n" + ($domains -join "`n")
                    Set-Content -Path $hostsPath -Value $newContent -Force
                    Write-Host "Домены добавлены в HOSTS." -ForegroundColor Green
                } catch {
                    Write-Host "Ошибка записи в HOSTS (Нужны права админа/Антивирус блокирует)." -ForegroundColor Red
                }
            }
        }
    }
    if ($p -ne "0") { Pause }
}

function Start-Tweaks {
    $tweakMenu = @(
        @{Label="1. КОНТЕКСТНОЕ МЕНЮ (Каскадное, Утилиты)"; Value="1"},
        @{Label="2. МЕНЮ ФАЙЛОВ/ПАПОК (PNG, Владелец, Upscayl)"; Value="2"},
        @{Label="3. СИСТЕМА И ПРОИЗВОДИТЕЛЬНОСТЬ (Питание, HAGS, Сон)"; Value="3"},
        @{Label="4. ИНТЕРФЕЙС И ОБОЛОЧКА (WindHawk, Blur, Transparency)"; Value="4"},
        @{Label="5. ПРИВАТНОСТЬ И ТЕЛЕМЕТРИЯ (Отключение слежки)"; Value="5"},
        @{Label="0. Назад"; Value="0"}
    )
    
    $m = Show-Menu-Interactive "--- TWEAK MASTER ---" $tweakMenu
    
    switch ($m) {
        "1" {
            $sub = @(
                @{Label="1. Добавить каскадное меню 'Dreyla Utils'"; Value="1"},
                @{Label="2. Вернуть Классическое меню (Win 10)"; Value="2"},
                @{Label="3. Переключить 'Показать доп. параметры'"; Value="3"},
                @{Label="4. Добавить звук PrintScreen"; Value="4"},
                @{Label="0. Назад"; Value="0"}
            )
            $t = Show-Menu-Interactive "--- ТВИКИ РАБОЧЕГО СТОЛА ---" $sub
            
            switch ($t) {
                "1" {
                    if (Show-Confirmation "Добавить меню утилит (Restart Explorer и др)?") {
                        # Create Cascading Menu
                        $regPath = "HKCR\DesktopBackground\Shell\DreylaUtils"
                        reg add $regPath /ve /t REG_SZ /d "Dreyla Utilities" /f | Out-Null
                        reg add $regPath /v "Icon" /t REG_SZ /d "shell32.dll,35" /f | Out-Null
                        reg add $regPath /v "SubCommands" /t REG_SZ /d "" /f | Out-Null
                        
                        $shellPath = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
                        
                        # 1. Restart Explorer
                        reg add "$shellPath\Dreyla.Restart" /ve /t REG_SZ /d "Перезапустить Explorer" /f | Out-Null
                        reg add "$shellPath\Dreyla.Restart\command" /ve /t REG_SZ /d "cmd.exe /c taskkill /f /im explorer.exe & start explorer.exe" /f | Out-Null
                        
                        # 2. Kill Not Responding
                        reg add "$shellPath\Dreyla.KillNR" /ve /t REG_SZ /d "Убить зависшие задачи" /f | Out-Null
                        reg add "$shellPath\Dreyla.KillNR\command" /ve /t REG_SZ /d "taskkill /F /FI `"STATUS eq NOT RESPONDING`"" /f | Out-Null
                        
                        # 3. System Info
                        reg add "$shellPath\Dreyla.SysInfo" /ve /t REG_SZ /d "Инфо о системе (Msinfo)" /f | Out-Null
                        reg add "$shellPath\Dreyla.SysInfo\command" /ve /t REG_SZ /d "msinfo32.exe" /f | Out-Null
                        
                        # 4. Startup Manager
                        reg add "$shellPath\Dreyla.Startup" /ve /t REG_SZ /d "Управление автозагрузкой" /f | Out-Null
                        reg add "$shellPath\Dreyla.Startup\command" /ve /t REG_SZ /d "taskmgr" /f | Out-Null
                        
                        # Link them
                        reg add $regPath /v "SubCommands" /t REG_SZ /d "Dreyla.Restart;Dreyla.KillNR;Dreyla.SysInfo;Dreyla.Startup" /f | Out-Null
                        
                        Write-Host "Перезапуск Explorer для применения изменений..." -ForegroundColor Yellow
                        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 1
                        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
                            Start-Process explorer
                        }

                        Write-Host "Каскадное меню добавлено!" -ForegroundColor Green
                    }
                }
                "2" { 
                    if (Show-Confirmation "Вернуть классическое меню (Win 10 style)?") {
                        reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve | Out-Null
                        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1; Start-Process explorer
                        Write-Host "Сделала меню как в Windows 10! Удобно! (b ᵔ▽ᵔ)b" -ForegroundColor Green 
                    }
                }
                "3" {
                    if (Show-Confirmation "Переключить вид контекстного меню?") {
                        $path = "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
                        if (Test-Path $path) { 
                            Remove-Item $path -Recurse -Force
                            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1; Start-Process explorer
                            Write-Host "Включила современное меню (Win 11)! Красиво, да? (✿◠‿◠)" -ForegroundColor Yellow 
                        }
                        else { 
                            reg add $path /f /ve | Out-Null
                            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1; Start-Process explorer
                            Write-Host "Вернула старое меню (Win 10)! Как скажешь! (｡•̀ᴗ-)" -ForegroundColor Green 
                        }
                    }
                }
                "4" { 
                    if (Show-Confirmation "Включить звук скриншота?") {
                        reg add "HKCU\AppEvents\Schemes\Apps\.Default\SnapShot" /f | Out-Null
                        Write-Host "Включено! Теперь будет слышно! (｡•̀ᴗ-)" -ForegroundColor Green 
                    }
                }
            }
            if ($t -ne "0") { Pause }
        }
        "2" {
            $sub = @(
                @{Label="1. Стать владельцем (Take Ownership)"; Value="1"},
                @{Label="2. Открыть командную строку здесь"; Value="2"},
                @{Label="3. Конвертировать в PNG (Изображения)"; Value="3"},
                @{Label="4. Upscayl (Улучшить качество фото)"; Value="4"},
                @{Label="5. Удалить фон (Web)"; Value="5"},
                @{Label="6. Скачать видео (yt-dlp)"; Value="6"},
                @{Label="0. Назад"; Value="0"}
            )
            $t = Show-Menu-Interactive "--- ТВИКИ МЕНЮ ФАЙЛОВ ---" $sub
            
            switch ($t) {
                "1" { 
                    if (Show-Confirmation "Добавить 'Стать владельцем' в контекстное меню?") {
                        reg add "HKCR\*\shell\runas" /ve /t REG_SZ /d "Стать владельцем" /f | Out-Null
                        reg add "HKCR\*\shell\runas" /v "NoWorkingDirectory" /t REG_SZ /d "" /f | Out-Null
                        reg add "HKCR\*\shell\runas\command" /ve /t REG_SZ /d "cmd.exe /c takeown /f `"%1`" && icacls `"%1`" /grant administrators:F" /f | Out-Null
                        reg add "HKCR\Directory\shell\runas" /ve /t REG_SZ /d "Стать владельцем" /f | Out-Null
                        reg add "HKCR\Directory\shell\runas\command" /ve /t REG_SZ /d "cmd.exe /c takeown /f `"%1`" /r /d y && icacls `"%1`" /grant administrators:F /t" /f | Out-Null
                        Write-Host "Готово! Теперь ты тут главный! (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧" -ForegroundColor Green
                    }
                }
                "2" {
                    if (Show-Confirmation "Добавить 'Открыть CMD здесь'?") {
                        reg add "HKCR\Directory\shell\OpenCmdHere" /ve /t REG_SZ /d "Открыть CMD здесь" /f | Out-Null
                        reg add "HKCR\Directory\shell\OpenCmdHere\command" /ve /t REG_SZ /d "cmd.exe /s /k pushd `"%V`"" /f | Out-Null
                        Write-Host "Готово! CMD всегда под рукой! (o^▽^o)" -ForegroundColor Green
                    }
                }
                "3" {
                    if (Show-Confirmation "Добавить конвертацию в PNG?") {
                        reg add "HKCR\*\shell\ConvertToPNG" /ve /t REG_SZ /d "Конвертировать в PNG" /f | Out-Null
                        reg add "HKCR\*\shell\ConvertToPNG\command" /ve /t REG_SZ /d "powershell.exe -WindowStyle Hidden -Command `"Add-Type -AssemblyName System.Drawing; [System.Drawing.Bitmap]::FromFile('%1').Save('%1.png', 'Png')`"" /f | Out-Null
                        Write-Host "Меню добавлено." -ForegroundColor Green
                    }
                }
                "4" {
                    if (Show-Confirmation "Добавить пункт Upscayl (Требуется ПО)?") {
                        $uPath = "$env:LOCALAPPDATA\Programs\upscayl\Upscayl.exe"
                        if (-not (Test-Path $uPath)) { $uPath = "C:\Programs\Upscayl\Upscayl.exe" } 
                        
                        reg add "HKCR\*\shell\Upscayl" /ve /t REG_SZ /d "Улучшить через Upscayl" /f | Out-Null
                        reg add "HKCR\*\shell\Upscayl\command" /ve /t REG_SZ /d "`"$uPath`" `"%1`"" /f | Out-Null
                        Write-Host "Добавлено (Проверьте путь к Upscayl)." -ForegroundColor Yellow
                    }
                }
                "5" {
                    if (Show-Confirmation "Добавить ссылку на удаление фона?") {
                        reg add "HKCR\*\shell\RemoveBG" /ve /t REG_SZ /d "Удалить фон (Web)" /f | Out-Null
                        reg add "HKCR\*\shell\RemoveBG\command" /ve /t REG_SZ /d "cmd.exe /c start https://www.adobe.com/express/feature/image/remove-background" /f | Out-Null
                        Write-Host "Добавлено меню 'Удалить фон'." -ForegroundColor Green
                    }
                }
                "6" {
                    if (Show-Confirmation "Добавить пункт yt-dlp (Скачивание видео)?") {
                        if (-not (Get-Command "yt-dlp" -ErrorAction SilentlyContinue)) {
                            Write-Host "yt-dlp не найден! Установка через Winget..." -ForegroundColor Yellow
                            winget install yt-dlp -e --silent
                        }
                        reg add "HKCR\Directory\Background\shell\YoutubeDL" /ve /t REG_SZ /d "Скачать видео (Вставьте ссылку)" /f | Out-Null
                        reg add "HKCR\Directory\Background\shell\YoutubeDL\command" /ve /t REG_SZ /d "cmd.exe /k echo Вставьте ссылку: & set /p u= & yt-dlp %u%" /f | Out-Null
                        Write-Host "Меню добавлено (ПКМ на фоне)." -ForegroundColor Green
                    }
                }
            }
            if ($t -ne "0") { Pause }
        }
        "3" {
            $sub = @(
                @{Label="1. Ultimate PowerPlan (Макс. произв-ть)"; Value="1"},
                @{Label="2. Отключить Гибернацию (Сэкономить место)"; Value="2"},
                @{Label="3. Отключить HAGS (Для старых GPU/Стабильности)"; Value="3"},
                @{Label="4. Оптимизация оконных игр"; Value="4"},
                @{Label="5. Очистка диска (Deep)"; Value="5"},
                @{Label="6. Large System Cache (ВКЛ)"; Value="6"},
                @{Label="7. Качество обоев (100%)"; Value="7"},
                @{Label="8. Быстрое завершение работы"; Value="8"},
                @{Label="9. Отключить Обновления Windows/Store"; Value="9"},
                @{Label="10. Открыть Электропитание"; Value="10"},
                @{Label="11. Импорт схемы питания (.pow)"; Value="11"},
                @{Label="12. Тест режимов питания"; Value="12"},
                @{Label="13. Отключить триггеры служб"; Value="13"},
                @{Label="14. Autoruns (Автозагрузка)"; Value="14"},
                @{Label="0. Назад"; Value="0"}
            )
            $t = Show-Menu-Interactive "--- СИСТЕМНЫЕ ТВИКИ ---" $sub
            
            switch ($t) {
                "1" { if(Show-Confirmation "Применить схему Ultimate Performance?") { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; Write-Host "План питания добавлен." -ForegroundColor Green } }
                "2" { if(Show-Confirmation "Отключить гибернацию?") { powercfg -h off; Write-Host "Гибернация отключена." -ForegroundColor Green } }
                "3" { 
                    if(Show-Confirmation "Отключить HAGS (Hardware Accelerated GPU Scheduling)?") {
                        reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 1 /f | Out-Null
                        Write-Host "HAGS Отключен (Нужна перезагрузка)." -ForegroundColor Green
                    }
                }
                "4" {
                    if(Show-Confirmation "Отключить GameDVR и оптимизировать игры?") {
                        reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f | Out-Null
                        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f | Out-Null
                        Write-Host "Оптимизировано." -ForegroundColor Green
                    }
                }
                "5" { Start-Clean }
                "6" {
                    if (Show-Confirmation "Включить Large System Cache?") {
                        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f | Out-Null
                        Write-Host "Large System Cache включен." -ForegroundColor Green
                    }
                }
                "7" {
                    if (Show-Confirmation "Установить качество обоев 100%?") {
                        reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d 100 /f | Out-Null
                        Write-Host "Качество установлено на 100." -ForegroundColor Green
                    }
                }
                "8" {
                    if (Show-Confirmation "Ускорить завершение работы?") {
                        reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f | Out-Null
                        reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f | Out-Null
                        reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f | Out-Null
                        reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f | Out-Null
                        Write-Host "Твики завершения работы применены." -ForegroundColor Green
                    }
                }
                "9" {
                    if (Show-Confirmation "Отключить обновления Windows и Store?") {
                        Stop-Service "wuauserv" -Force -ErrorAction SilentlyContinue
                        Set-Service "wuauserv" -StartupType Disabled
                        Stop-Service "UsoSvc" -Force -ErrorAction SilentlyContinue
                        Set-Service "UsoSvc" -StartupType Disabled
                        Stop-Service "dosvc" -Force -ErrorAction SilentlyContinue
                        Set-Service "dosvc" -StartupType Disabled
                        Write-Host "Службы обновлений отключены." -ForegroundColor Green
                    }
                }
                "10" {
                    Start-Process "control.exe" -ArgumentList "powercfg.cpl"
                }
                "11" {
                    Write-Host "Положите .pow файл в корень диска $($Global:WorkDrive):"
                    if (Show-Confirmation "Импортировать схему питания?") {
                         $files = Get-ChildItem "$($Global:WorkDrive):" -Filter "*.pow"
                         if ($files) {
                             foreach ($f in $files) {
                                 powercfg -import $f.FullName
                                 Write-Host "Импортировано: $($f.Name)" -ForegroundColor Green
                             }
                         } else { Write-Host "Файлы .pow не найдены." -ForegroundColor Red }
                    }
                }
                "12" {
                     Write-Host "Тест переключает схемы и запускает бенчмарк."
                     Run-MicroBenchmark
                }
                "13" {
                    if (Show-Confirmation "Отключить триггеры для служб (WSearch, SysMain)?") {
                        sc triggerinfo WSearch delete
                        sc triggerinfo SysMain delete
                        Write-Host "Триггеры удалены." -ForegroundColor Green
                    }
                }
                "14" {
                    if (Show-Confirmation "Скачать и запустить Autoruns?") {
                        $toolPath = "$($Global:AppsPath)\Autoruns.exe"
                        if (-not (Test-Path $toolPath)) {
                            Show-Spinner "Скачивание Autoruns..."
                            Invoke-WebRequest "https://live.sysinternals.com/autoruns.exe" -OutFile $toolPath
                        }
                        Start-Process $toolPath
                    }
                }
            }
            if ($t -ne "0" -and $t -ne "EXIT") { Pause }
        }
        "4" {
            $sub = @(
                @{Label="1. Установить WindHawk (Кастомизация)"; Value="1"},
                @{Label="2. Make Win Transparent (TranslucentTB)"; Value="2"},
                @{Label="3. Make Blur Win (MicaForEveryone)"; Value="3"},
                @{Label="4. [TEST] Force Transparency (Registry)"; Value="4"},
                @{Label="0. Назад"; Value="0"}
            )
            $t = Show-Menu-Interactive "--- ИНТЕРФЕЙС И ОБОЛОЧКА ---" $sub
            
            Write-Host "`nВНИМАНИЕ! ЭТИ ФУНКЦИИ В ТЕСТОВОМ РЕЖИМЕ!" -ForegroundColor Red
            Write-Host "НИЧЕГО НЕ НАЖИМАЙТЕ ВО ВРЕМЯ ВЫПОЛНЕНИЯ!" -ForegroundColor Red
            
            switch ($t) {
                "1" { if(Show-Confirmation "Установить WindHawk?") { winget install RamenSoftware.WindHawk -e; Write-Host "Установлено." -ForegroundColor Green } }
                "2" { 
                    if(Show-Confirmation "Сделать панель задач прозрачной (TranslucentTB)?") { 
                        winget install TranslucentTB -e 
                        Start-Process "ms-windows-store://pdp/?ProductId=9PF4KZ2VN4W9" 
                        Write-Host "Установлено. Запустите приложение." -ForegroundColor Green 
                    } 
                }
                "3" { 
                    if(Show-Confirmation "Добавить эффект BLUR (MicaForEveryone)?") { 
                        winget install MicaForEveryone -e 
                        Write-Host "Установлено. Требуется настройка в приложении." -ForegroundColor Green 
                    } 
                }
                "4" {
                    if(Show-Confirmation "Включить прозрачность через реестр (Может не сработать)?") {
                        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 1 /f | Out-Null
                        Write-Host "Твик применен." -ForegroundColor Yellow
                    }
                }
                "5" { Start-PrivacyMenu }
            }
            if ($t -ne "0") { Pause }
        }
    }
}

# --- 3. ВЫБОР СОФТА (VIVALDI + МЕНЮ) ---
function Install-Soft {
    $sList = @(
        @{ID=1; Name="Vivaldi"; Slug="Vivaldi.Vivaldi"},
        @{ID=2; Name="Google Chrome"; Slug="Google.Chrome"},
        @{ID=3; Name="Firefox"; Slug="Mozilla.Firefox"},
        @{ID=4; Name="Discord"; Slug="Discord.Discord"},
        @{ID=5; Name="Roblox"; Slug="Roblox.Roblox"},
        @{ID=6; Name="K-Lite Codec"; Slug="CodecGuide.K-LiteCodecPack.Mega"},
        @{ID=7; Name="VLC Player"; Slug="VideoLAN.VLC"},
        @{ID=8; Name="7-Zip"; Slug="7zip.7zip"},
        @{ID=9; Name="Steam"; Slug="Valve.Steam"},
        @{ID=10; Name="Upscayl"; Slug="Upscayl.Upscayl"},
        @{ID=11; Name="Telegram"; Slug="Telegram.TelegramDesktop"},
        @{ID=12; Name="AIMP"; Slug="AIMP.AIMP"},
        @{ID=13; Name="AIDA64"; Slug="FinalWire.AIDA64.Extreme"},
        @{ID=14; Name="CrystalDiskInfo"; Slug="CrystalDewWorld.CrystalDiskInfo"},
        @{ID=15; Name="AmneziaVPN"; Slug="AmneziaVPN.AmneziaVPN"},
        @{ID=16; Name="HiBit Uninstaller"; Slug="HiBitSoftware.HiBitUninstaller"},
        @{ID=17; Name="Zapret (Flowseal) (GitHub)"; Slug="LINK:https://github.com/Flowseal/zapret-discord-youtube/releases/tag/1.9.3"},
        @{ID=18; Name="WindHawk (Customization)"; Slug="RamenSoftware.WindHawk"}
    )
    
    $menuOptions = @()
    foreach ($s in $sList) {
        $menuOptions += @{Label=$s.Name; Value=$s.ID}
    }
    
    $selectedIDs = Show-MultiSelect-Interactive "--- УСТАНОВКА ПРОГРАММ (WINGET) ---" $menuOptions
    
    if ($selectedIDs.Count -gt 0) {
        Write-Host "`nВыбрано для установки: $($selectedIDs.Count) приложений." -ForegroundColor Yellow
        if (-not (Show-Confirmation "Начать установку?")) { return }
        
        foreach ($id in $selectedIDs) {
            $item = $sList | Where-Object { $_.ID -eq $id }
            if ($item) {
                if ($item.Slug.StartsWith("LINK:")) {
                    $url = $item.Slug.Substring(5)
                    Write-Host "Открываю браузер: $($item.Name)..." -ForegroundColor Yellow
                    Start-Process $url
                } else {
                    Show-Spinner "Установка $($item.Name)"
                    # Create directory if needed
                    if (-not (Test-Path "$($Global:AppsPath)")) { New-Item -ItemType Directory -Path "$($Global:AppsPath)" -Force | Out-Null }
                    
                    winget install --id $item.Slug -e --silent --accept-package-agreements --accept-source-agreements --location "$($Global:AppsPath)\$($item.Name)"
                }
            }
        }
    }
    Pause
}

# Системные заглушки (кратко)
function Create-RestorePoint { Show-Spinner "Точка восстановления"; Checkpoint-Computer -Description "Dreyla_Fix" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue; Pause }
function Install-Runtimes { 
    $runtimes = @(
        @{Label="1. Visual C++ Redistributable 2015-2022 (x64/x86)"; Value="1"},
        @{Label="2. .NET Desktop Runtime 8.0"; Value="2"},
        @{Label="3. .NET Desktop Runtime 7.0"; Value="3"},
        @{Label="4. .NET Desktop Runtime 6.0"; Value="4"},
        @{Label="5. .NET Desktop Runtime 5.0"; Value="5"},
        @{Label="6. .NET Framework 3.5 (Enable via DISM)"; Value="6"},
        @{Label="7. DirectX (Web Setup)"; Value="7"},
        @{Label="8. Установить ВСЕ (Recommended)"; Value="8"},
        @{Label="0. Назад"; Value="0"}
    )

    $sel = Show-Menu-Interactive "--- БИБЛИОТЕКИ И RUNTIMES ---" $runtimes

    switch ($sel) {
        "1" { Show-Spinner "Visual C++"; winget install --id Microsoft.VCRedist.2015+.x64 -e --silent; winget install --id Microsoft.VCRedist.2015+.x86 -e --silent }
        "2" { Show-Spinner ".NET 8.0"; winget install --id Microsoft.DotNet.DesktopRuntime.8 -e --silent }
        "3" { Show-Spinner ".NET 7.0"; winget install --id Microsoft.DotNet.DesktopRuntime.7 -e --silent }
        "4" { Show-Spinner ".NET 6.0"; winget install --id Microsoft.DotNet.DesktopRuntime.6 -e --silent }
        "5" { Show-Spinner ".NET 5.0"; winget install --id Microsoft.DotNet.DesktopRuntime.5 -e --silent }
        "6" { Show-Spinner ".NET 3.5 Enabling"; DISM /Online /Enable-Feature /FeatureName:NetFx3 /All }
        "7" { Show-Spinner "DirectX"; winget install --id Microsoft.DirectX -e --silent }
        "8" {
            Show-Spinner "Visual C++..."
            winget install --id Microsoft.VCRedist.2015+.x64 -e --silent
            winget install --id Microsoft.VCRedist.2015+.x86 -e --silent
            Show-Spinner ".NET 8/7/6..."
            winget install --id Microsoft.DotNet.DesktopRuntime.8 -e --silent
            winget install --id Microsoft.DotNet.DesktopRuntime.7 -e --silent
            winget install --id Microsoft.DotNet.DesktopRuntime.6 -e --silent
            Show-Spinner ".NET 3.5..."
            DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
            Write-Host "Все библиотеки установлены!" -ForegroundColor Green
        }
    }
    if ($sel -ne "0") { Pause }
}
function Start-Clean {
    $cleanMenu = @(
        @{Label="1. LITE (Только Temp) - Безопасно"; Value="1"},
        @{Label="2. MAX (Temp, Cache, Logs, Updates) - Глубокая"; Value="2"},
        @{Label="3. HARDCORE (DISM + Old Drivers) - Долго"; Value="3"},
        @{Label="0. Назад"; Value="0"}
    )
    
    $c = Show-Menu-Interactive "--- ОЧИСТКА СИСТЕМЫ ---" $cleanMenu
    
    switch ($c) {
        "1" {
            if (Show-Confirmation "Очистить временные файлы?") {
                Show-Spinner "Очистка Temp..."
                Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Убрала немножко мусора! (temp) 🧹" -ForegroundColor Green
            }
        }
        "2" {
            if (Show-Confirmation "ВНИМАНИЕ! Это удалит кэш обновлений и журналы. Продолжить?") {
                Write-Host "Начинаем глубокую очистку..." -ForegroundColor Yellow
                
                Show-Spinner "Временные файлы"
                Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                
                Show-Spinner "Кэш обновлений"
                Stop-Service wuauserv -ErrorAction SilentlyContinue
                Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
                Start-Service wuauserv -ErrorAction SilentlyContinue
                
                Show-Spinner "Prefetch"
                Remove-Item -Path "$env:windir\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
                
                Show-Spinner "Журналы событий"
                Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log } -ErrorAction SilentlyContinue
                
                Show-Spinner "DNS Кэш"
                Clear-DnsClientCache
                
                Write-Host "ОЧИСТКА ЗАВЕРШЕНА!" -ForegroundColor Green
            }
        }
        "3" {
            if (Show-Confirmation "HARDCORE: DISM Cleanup + Driver Cleanup (Долго!)") {
                 Show-Spinner "DISM Cleanup"
                 dism /online /cleanup-image /startcomponentcleanup /resetbase
                 Write-Host "Ух! Это было сложно, но я справилась! (Hardcore Clean) 😤" -ForegroundColor Green
            }
        }
    }
    if ($c -ne "0" -and $c -ne "EXIT") { Pause }
}

function Start-ServicesMenu {
    while ($true) {
        $services = @(
            @{ID="DiagTrack"; Disp="Телеметрия (Сбор данных)"; Safe="RISKY"},
            @{ID="SysMain"; Disp="SysMain (Superfetch)"; Safe="RISKY"},
            @{ID="WSearch"; Disp="Windows Search (Поиск)"; Safe="RISKY"},
            @{ID="Spooler"; Disp="Диспетчер печати"; Safe="SAFE"},
            @{ID="Fax"; Disp="Факс"; Safe="SAFE"},
            @{ID="TabletInputService"; Disp="Сенсорная клавиатура"; Safe="SAFE"},
            @{ID="MapsBroker"; Disp="Диспетчер скачанных карт"; Safe="SAFE"},
            @{ID="XblAuthManager"; Disp="Xbox Live Auth Manager"; Safe="SAFE"},
            @{ID="XblGameSave"; Disp="Xbox Live Game Save"; Safe="SAFE"},
            @{ID="XboxNetApiSvc"; Disp="Xbox Live Networking Service"; Safe="SAFE"},
            @{ID="WMPNetworkSvc"; Disp="Windows Media Player Sharing"; Safe="SAFE"},
            @{ID="WbioSrvc"; Disp="Windows Biometric Service"; Safe="SAFE"},
            @{ID="WerSvc"; Disp="Windows Error Reporting"; Safe="SAFE"},
            @{ID="PcaSvc"; Disp="Program Compatibility Assistant"; Safe="SAFE"},
            @{ID="DPS"; Disp="Diagnostic Policy Service"; Safe="RISKY"},
            @{ID="TrkWks"; Disp="Distributed Link Tracking Client"; Safe="SAFE"},
            @{ID="RemoteRegistry"; Disp="Remote Registry"; Safe="SAFE"},
            @{ID="TermService"; Disp="Remote Desktop Services"; Safe="SAFE"},
            @{ID="RetailDemo"; Disp="Retail Demo Service"; Safe="SAFE"},
            @{ID="lfsvc"; Disp="Geolocation Service"; Safe="SAFE"},
            @{ID="SensorService"; Disp="Sensor Service"; Safe="SAFE"},
            @{ID="SensorDataService"; Disp="Sensor Data Service"; Safe="SAFE"},
            @{ID="SensrSvc"; Disp="Sensor Monitoring Service"; Safe="SAFE"},
            @{ID="WalletService"; Disp="Wallet Service"; Safe="SAFE"},
            @{ID="WwanSvc"; Disp="WWAN AutoConfig"; Safe="SAFE"},
            @{ID="PhoneSvc"; Disp="Phone Service"; Safe="SAFE"},
            @{ID="icssvc"; Disp="Mobile Hotspot Service"; Safe="SAFE"},
            @{ID="MpsSvc"; Disp="Windows Firewall (Брандмауэр)"; Safe="RISKY"},
            @{ID="defragsvc"; Disp="Optimize Drives (Дефрагментация)"; Safe="SAFE"},
            @{ID="wuauserv"; Disp="Windows Update"; Safe="RISKY"},
            @{ID="UsoSvc"; Disp="Update Orchestrator Service"; Safe="RISKY"},
            @{ID="bits"; Disp="BITS (Фоновая передача)"; Safe="RISKY"},
            @{ID="dosvc"; Disp="Delivery Optimization"; Safe="RISKY"}
        )

        $menu = @()
        $menu += @{Label="[PRESET] Рекомендуемые службы (Safe)"; Value="P1"}
        $menu += @{Label="[PRESET] Рекомендуемые службы 2 (Aggressive)"; Value="P2"}
        $menu += @{Label="[BACKUP] Создать бэкап служб (.vbs)"; Value="BACKUP"}
        $menu += @{Label="[BACKUP] Создать бэкап служб (.bat)"; Value="BACKUP_BAT"}
        $menu += @{Label="--------------------------------"; Value=""}

        foreach ($s in $services) {
            $st = (Get-Service $s.ID -ErrorAction SilentlyContinue).Status
            $stTag = if ($st -eq "Running") { "[ON] " } else { "[OFF]" }
            $lbl = "$stTag $($s.Disp)"
            $menu += @{Label=$lbl; Value=$s.ID}
        }
        $menu += @{Label="0. Назад"; Value="0"}

        $sel = Show-Menu-Interactive "--- ОПТИМИЗАЦИЯ СЛУЖБ ---" $menu
        
        if ($sel -eq "0" -or $sel -eq "EXIT") { return }
        if ($sel -eq "") { continue }

        if ($sel -eq "P1") {
            if (Show-Confirmation "Отключить безопасные службы (Fax, Phone, Maps, Retail)?") {
                $list = @("Fax", "PhoneSvc", "MapsBroker", "RetailDemo", "WalletService", "WwanSvc", "XblAuthManager", "XblGameSave")
                foreach ($l in $list) { Stop-Service $l -Force -ErrorAction SilentlyContinue; Set-Service $l -StartupType Disabled }
                Write-Host "Безопасный пресет применен." -ForegroundColor Green
                Pause
            }
            continue
        }
        
        if ($sel -eq "P2") {
            if (Show-Confirmation "Отключить агрессивные службы (SysMain, Spooler, Update)?") {
                $list = @("SysMain", "Spooler", "TabletInputService", "wuauserv", "UsoSvc", "bits", "dosvc", "DiagTrack", "WerSvc", "MpsSvc")
                foreach ($l in $list) { Stop-Service $l -Force -ErrorAction SilentlyContinue; Set-Service $l -StartupType Disabled }
                Write-Host "Агрессивный пресет применен." -ForegroundColor Green
                Pause
            }
            continue
        }

        if ($sel -eq "BACKUP") {
            if (Show-Confirmation "Создать бэкап конфигурации служб (services_backup.vbs)?") {
                $backupPath = "$($Global:WorkDrive):\Services_Backup_$(Get-Date -Format 'yyyyMMdd').vbs"
                $content = "Set objShell = CreateObject(`"WScript.Shell`")`r`n"
                $content += "If WScript.Arguments.length = 0 Then`r`n"
                $content += "   Set objShell = CreateObject(`"Shell.Application`")`r`n"
                $content += "   objShell.ShellExecute `"wscript.exe`", `"`"`" & WScript.ScriptFullName & `"`"`", `"`", `"runas`", 1`r`n"
                $content += "   WScript.Quit`r`n"
                $content += "End If`r`n"
                
                foreach ($s in $services) {
                    $startType = (Get-Service $s.ID).StartType
                    $startStr = "auto"
                    if ($startType -eq "Manual") { $startStr = "demand" }
                    if ($startType -eq "Disabled") { $startStr = "disabled" }
                    $content += "objShell.Run `"sc config $($s.ID) start= $startStr`", 0, True`r`n"
                }
                $content += "MsgBox `"Services Restored!`"`r`n"
                $content | Out-File $backupPath -Encoding ASCII
                Write-Host "Бэкап сохранен: $backupPath" -ForegroundColor Green
                Pause
            }
            continue
        }

        if ($sel -eq "BACKUP_BAT") {
            if (Show-Confirmation "Создать бэкап конфигурации служб (services_backup.bat)?") {
                $backupPath = "$($Global:WorkDrive):\Services_Backup_$(Get-Date -Format 'yyyyMMdd').bat"
                $content = "@echo off`r`necho Restoring Services...`r`n"
                $content += ":: Check Admin`r`nopenfiles >nul 2>&1`r`nif %errorlevel% neq 0 ( powershell start -verb runas '%0' & exit /b )`r`n"
                
                foreach ($s in $services) {
                    $startType = (Get-Service $s.ID).StartType
                    $startStr = "auto"
                    if ($startType -eq "Manual") { $startStr = "demand" }
                    if ($startType -eq "Disabled") { $startStr = "disabled" }
                    $content += "sc config $($s.ID) start= $startStr`r`n"
                }
                $content += "echo Done!`r`npause`r`n"
                $content | Out-File $backupPath -Encoding ASCII
                Write-Host "Бэкап сохранен: $backupPath" -ForegroundColor Green
                Pause
            }
            continue
        }
        
        $svc = $services | Where-Object { $_.ID -eq $sel }
        if ($svc) {
            $curr = Get-Service $svc.ID
            if ($curr.Status -eq "Running") {
                if (Show-Confirmation "Отключить службу '$($svc.Disp)'?") {
                    Stop-Service $svc.ID -Force -ErrorAction SilentlyContinue
                    Set-Service $svc.ID -StartupType Disabled
                    Write-Host "Служба отключена." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            } else {
                if (Show-Confirmation "Включить службу '$($svc.Disp)'?") {
                    Set-Service $svc.ID -StartupType Automatic
                    Start-Service $svc.ID -ErrorAction SilentlyContinue
                    Write-Host "Служба включена." -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
            }
        }
    }
}

function Start-LatencyOpt {
    $latMenu = @(
        @{Label="1. Применить твики реестра (SystemResponsiveness, Throttling)"; Value="1"},
        @{Label="2. Отключить Power Throttling (Схема питания)"; Value="2"},
        @{Label="3. Отключить динамический тик (BCD)"; Value="3"},
        @{Label="4. Отключить HPET (High Precision Event Timer)"; Value="4"},
        @{Label="5. Оптимизация TCP/Network (Netsh)"; Value="5"},
        @{Label="6. Приоритет Win32 (Win32PrioritySeparation)"; Value="6"},
        @{Label="7. Очередь мыши/клавиатуры (50/54 - ios1ph)"; Value="7"},
        @{Label="8. Службы, вызывающие лаги (SysMain, DPS)"; Value="8"},
        @{Label="9. Интеграция MSI Mode Tool (Инфо/Запуск)"; Value="9"},
        @{Label="10. [EXTREME] ПРИМЕНИТЬ ВСЕ ТВИКИ СРАЗУ"; Value="10"},
        @{Label="11. Запустить тест задержки (MicroBench)"; Value="11"},
        @{Label="12. Установить Timer Resolution (0.5ms) [C#]"; Value="12"},
        @{Label="13. Приоритет GPU и Игр (Реестр)"; Value="13"},
        @{Label="14. Отключить сжатие памяти (Memory Compression)"; Value="14"},
        @{Label="15. Отключить Гибернацию (hiberfil.sys)"; Value="15"},
        @{Label="0. Назад"; Value="0"}
    )

    Show-Header "--- УМЕНЬШЕНИЕ ЗАДЕРЖКИ (LATENCY) ---"
    Write-Host "ВАЖНО: Инпут-лаг зависит не только от Windows, но и от таймингов RAM," -ForegroundColor DarkGray
    Write-Host "DPC Latency драйверов и частоты опроса мыши. Если вы не чувствуете" -ForegroundColor DarkGray
    Write-Host "разницы — возможно, упор идет в железо, а не в настройки ОС." -ForegroundColor DarkGray
    Write-Host ""

    $c = Show-Menu-Interactive "--- УМЕНЬШЕНИЕ ЗАДЕРЖКИ (LATENCY) ---" $latMenu
    
    switch ($c) {
        "1" {
            if (Show-Confirmation "Применить твики реестра для игр?") {
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
                Write-Host "Твики реестра применены." -ForegroundColor Green
                Pause
            }
        }
        "2" {
            if (Show-Confirmation "Добавить схему питания Ultimate Performance?") {
                powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
                Write-Host "Схема добавлена. Включите её в Электропитании." -ForegroundColor Yellow
                Pause
            }
        }
        "3" {
            if (Show-Confirmation "Отключить Dynamic Tick (bcdedit)?") {
                bcdedit /set disabledynamictick yes
                bcdedit /set useplatformclock no
                bcdedit /set tscsyncpolicy Enhanced
                Write-Host "Dynamic Tick отключен." -ForegroundColor Green
                Pause
            }
        }
        "4" {
            if (Show-Confirmation "Отключить HPET (Может повысить FPS)?") {
                bcdedit /deletevalue useplatformclock
                Disable-PnpDevice -InstanceId (Get-PnpDevice -FriendlyName "High precision event timer").InstanceId -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "HPET отключен." -ForegroundColor Green
                Pause
            }
        }
        "5" {
            if (Show-Confirmation "Оптимизировать TCP (Netsh)?") {
                netsh int tcp set global autotuninglevel=normal
                netsh int tcp set global chimney=disabled
                netsh int tcp set global dca=enabled
                netsh int tcp set global netdma=enabled
                netsh int tcp set global rss=enabled
                netsh int tcp set global timestamps=disabled
                Write-Host "TCP параметры обновлены." -ForegroundColor Green
                Pause
            }
        }
        "6" {
            if (Show-Confirmation "Изменить Win32PrioritySeparation (26 hex)?") {
                reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f
                Write-Host "Приоритет изменен на 26 (hex)." -ForegroundColor Green
                Pause
            }
        }
        "7" {
            if (Show-Confirmation "Установить Queue Size (K:50, M:54)?") {
                reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "8" /f
                reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 54 /f
                reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d 50 /f
                Write-Host "Очереди ввода: Mouse=54, Keyboard=50." -ForegroundColor Green
                Pause
            }
        }
        "8" {
            if (Show-Confirmation "Отключить SysMain, DPS, MapsBroker?") {
                Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
                Set-Service "SysMain" -StartupType Disabled
                Stop-Service "DPS" -Force -ErrorAction SilentlyContinue
                Set-Service "DPS" -StartupType Disabled
                Stop-Service "MapsBroker" -Force -ErrorAction SilentlyContinue
                Set-Service "MapsBroker" -StartupType Disabled
                Stop-Service "TrkWks" -Force -ErrorAction SilentlyContinue
                Set-Service "TrkWks" -StartupType Disabled
                Write-Host "Службы отключены." -ForegroundColor Green
                Pause
            }
        }
        "9" {
            Write-Host "MSI Mode Tool переключает прерывания видеокарты в режим MSI,"
            Write-Host "что снижает задержки. Требуется утилита MSI_util_v3.exe."
            if (Show-Confirmation "Попробовать найти и запустить MSI Mode Tool?") {
                $paths = @(".\MSI_util_v3.exe", "C:\Programs\MSI_util_v3.exe", ".\Tools\MSI_util_v3.exe")
                $found = $false
                foreach ($p in $paths) {
                    if (Test-Path $p) {
                        Start-Process $p -Verb RunAs
                        $found = $true
                        break
                    }
                }
                if (-not $found) {
                    Write-Host "Файл не найден. Скачайте MSI Mode Tool v3 и положите рядом." -ForegroundColor Red
                }
                Pause
            }
        }
        "10" {
            if (Show-Confirmation "ПРИМЕНИТЬ ВСЕ ТВИКИ (EXTREME)?") {
                Write-Host "Применяем реестр..." -ForegroundColor Yellow
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f
                reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f
                
                Write-Host "Настраиваем BCD..." -ForegroundColor Yellow
                bcdedit /set disabledynamictick yes
                bcdedit /set useplatformclock no
                
                Write-Host "Настраиваем сеть..." -ForegroundColor Yellow
                netsh int tcp set global autotuninglevel=normal
                
                Write-Host "Настраиваем ввод (50/54)..." -ForegroundColor Yellow
                reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 54 /f
                reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d 50 /f
                
                Write-Host "ГОТОВО! ПЕРЕЗАГРУЗИТЕ ПК!" -ForegroundColor Red -BackgroundColor Yellow
                Pause
            }
        }
        "11" { Run-MicroBenchmark }
        "12" {
            if (Show-Confirmation "Установить Timer Resolution (0.5ms)?") {
                 $code = @"
using System;
using System.Runtime.InteropServices;
public class TimerRes {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);
    public static void SetMax() {
        uint current;
        NtSetTimerResolution(5000, true, out current); 
        Console.WriteLine("Timer Resolution set to 0.5ms (Max)");
    }
}
"@
                try { Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue } catch {}
                try { [TimerRes]::SetMax() } catch { Write-Host "Ошибка установки таймера." -ForegroundColor Red }
                Write-Host "Для сохранения эффекта не закрывайте это окно (или используйте ISLC)." -ForegroundColor Yellow
                Pause
            }
        }
        "13" {
             if (Show-Confirmation "Оптимизировать приоритет GPU для игр?") {
                 reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f
                 reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f
                 reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
                 reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
                 Write-Host "Приоритет GPU повышен." -ForegroundColor Green
                 Pause
             }
        }
        "14" {
            if (Show-Confirmation "Отключить сжатие памяти (Memory Compression)?") {
                Disable-MMAgent -mc -ErrorAction SilentlyContinue
                Write-Host "Сжатие памяти отключено (Требуется перезагрузка)." -ForegroundColor Green
                Pause
            }
        }
        "15" {
             if (Show-Confirmation "Отключить Гибернацию (hiberfil.sys)?") {
                 powercfg -h off
                 Write-Host "Гибернация отключена." -ForegroundColor Green
                 Pause
             }
        }
    }
}

function Activate-Win { Show-Spinner "Активация MAS"; irm https://get.activated.win | iex }

function Create-Folders {
    $locMenu = @(
        @{Label="1. На системном диске ($($Global:WorkDrive):)"; Value="1"},
        @{Label="2. На рабочем столе"; Value="2"},
        @{Label="3. Свой путь"; Value="3"},
        @{Label="0. Назад"; Value="0"}
    )
    
    $loc = Show-Menu-Interactive "--- CREATE FOLDERS ---" $locMenu
    if ($loc -eq "0" -or $loc -eq "EXIT") { return }
    
    $basePath = "$($Global:WorkDrive):\"
    if ($loc -eq "2") { $basePath = [Environment]::GetFolderPath("Desktop") }
    if ($loc -eq "3") { 
        Write-Host "Введите полный путь:"
        $basePath = Read-Host " > Путь" 
    }
    
    if (-not (Test-Path $basePath)) { New-Item -ItemType Directory -Path $basePath -Force | Out-Null }
    
    $setMenu = @(
        @{Label="1. STANDARD (Games, Soft, Downloads, Work, Media)"; Value="1"},
        @{Label="2. DEVELOPER (Projects, Repos, Tools, Scripts, Builds)"; Value="2"},
        @{Label="3. MEDIA CREATOR (Renders, Assets, Footage, Audio, OBS)"; Value="3"},
        @{Label="4. CUSTOM (Ввести вручную)"; Value="4"},
        @{Label="0. Назад"; Value="0"}
    )
    
    $set = Show-Menu-Interactive "--- ВЫБЕРИТЕ НАБОР ---" $setMenu
    $list = @()
    
    switch ($set) {
        "1" { $list = @("Games", "Soft", "Downloads", "Work", "Media") }
        "2" { $list = @("Projects", "Repos", "Tools", "Scripts", "Builds") }
        "3" { $list = @("Renders", "Assets", "Footage", "Audio", "OBS") }
        "4" { 
             $names = Read-Host "Введите имена папок через запятую"
             if ($names) { $list = $names.Split(',') }
        }
        "0" { return }
    }
    
    if ($list.Count -gt 0) {
        Write-Host "`nБудут созданы папки в [$basePath]:" -ForegroundColor Gray
        foreach ($n in $list) { Write-Host " - $($n.Trim())" }
        
        if (Show-Confirmation "Создать эти папки?") {
            foreach ($n in $list) {
                $p = Join-Path $basePath $n.Trim()
                New-Item -ItemType Directory -Path $p -Force | Out-Null
                Write-Host " [+] $p" -ForegroundColor Green
            }
        }
    }
    Pause
}

# --- МОДУЛЬ ВОССТАНОВЛЕНИЯ ---
function Start-RestoreMenu {
    $restoreMenu = @(
        @{Label="1. Вернуть Microsoft Store (Если пропал)"; Value="1"},
        @{Label="2. Вернуть Калькулятор и Paint"; Value="2"},
        @{Label="3. Вернуть Почту и Календарь"; Value="3"},
        @{Label="4. Включить Телеметрию назад (По умолчанию)"; Value="4"},
        @{Label="5. Переустановить OneDrive"; Value="5"},
        @{Label="6. [FIX] Переустановить ВСЕ встроенные приложения"; Value="6"},
        @{Label="7. [IMAGE] Восстановить из образа (Provisioned)"; Value="7"},
        @{Label="0. Назад"; Value="0"}
    )
    
    $r = Show-Menu-Interactive "--- МЕНЮ ВОССТАНОВЛЕНИЯ (RECOVERY) ---" $restoreMenu
    
    switch ($r) {
        "1" { 
            if (Show-Confirmation "Попробовать восстановить Microsoft Store?") {
                Show-Spinner "Восстановление Магазина"
                
                # Метод 1: Регистрация существующих пакетов
                $store = Get-AppxPackage -AllUsers *WindowsStore*
                if ($store) {
                    $store | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue}
                    Write-Host "Попытка регистрации стандартным методом..." -ForegroundColor Cyan
                } else {
                    Write-Host "Магазин не найден в системе. Ищем в папке WindowsApps..." -ForegroundColor Yellow
                    try {
                        $manifest = Get-ChildItem "$env:ProgramFiles\WindowsApps\Microsoft.WindowsStore*AppxManifest.xml" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($manifest) {
                            Add-AppxPackage -Register $manifest.FullName -DisableDevelopmentMode -ErrorAction SilentlyContinue
                            Write-Host "Магазин зарегистрирован через Manifest." -ForegroundColor Green
                        } else {
                            Write-Host "Файлы магазина не найдены!" -ForegroundColor Red
                        }
                    } catch {}
                }

                # Метод 2: Сброс через wsreset
                Start-Process "wsreset.exe" -NoNewWindow -Wait
                Write-Host "Попытка восстановления завершена." -ForegroundColor Green
            }
        }
        "2" { 
            if (Show-Confirmation "Установить Калькулятор и Paint?") {
                winget install Microsoft.WindowsCalculator -e; winget install Microsoft.Paint -e 
            }
        }
        "3" { 
            if (Show-Confirmation "Установить Outlook (Почту)?") {
                winget install Microsoft.OutlookForWindows -e 
            }
        }
        "4" { 
            if (Show-Confirmation "Включить телеметрию обратно?") {
                Set-Service "DiagTrack" -StartupType Automatic
                Start-Service "DiagTrack" -ErrorAction SilentlyContinue
                reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f | Out-Null
                Write-Host "Телеметрия включена." -ForegroundColor Green
            }
        }
        "5" { 
            if (Show-Confirmation "Скачать установщик OneDrive?") {
                Start-Process "https://go.microsoft.com/fwlink/p/?LinkId=248256" 
            }
        }
        "6" {
            if (Show-Confirmation "Переустановить ВСЕ встроенные приложения (Долго)?") {
                 Show-Spinner "Восстановление всех AppX"
                 Get-AppxPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue}
                 Write-Host "Вернула все-все приложения на место! 🏠" -ForegroundColor Green
            }
        }
        "7" {
             if (Show-Confirmation "Восстановить приложения из образа Windows?") {
                 Show-Spinner "Поиск пакетов в образе..."
                 $prov = Get-AppxProvisionedPackage -Online
                 foreach ($p in $prov) {
                     if ($p.InstallLocation) {
                         Write-Host "Restore: $($p.DisplayName)" -ForegroundColor Gray
                         Add-AppxPackage -DisableDevelopmentMode -Register "$($p.InstallLocation)\AppxManifest.xml" -ErrorAction SilentlyContinue
                     }
                 }
                 Write-Host "Восстановление завершено." -ForegroundColor Green
                 Pause
             }
        }
    }
    if ($r -ne "0" -and $r -ne "EXIT") { Pause }
}



# --- HELPER FUNCTIONS ---
function Show-Header {
    param($Title)
    Clear-Host
    Show-Logo
    $User = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host " ╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host " ║ USER: $User | DRIVE: $($Global:WorkDrive): | STATUS: READY ║" -ForegroundColor DarkCyan
    Write-Host " ╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Show-RandomQuote
    
    if ($Title) {
        Write-Host "$Title" -ForegroundColor Yellow
    }
}

function Show-Confirmation {
    param([string]$Message)
    Write-Host "`n[?] $Message (Y/N)" -ForegroundColor Yellow -NoNewline
    $k = [Console]::ReadKey($true)
    Write-Host ""
    if ($k.Key -eq "Y") { return $true }
    return $false
}

function Show-Menu-Interactive {
    param($Title, $Options)
    $index = 0
    $max = $Options.Count - 1
    $startRow = $Host.UI.RawUI.CursorPosition.Y
    
    # Hide Cursor
    try { [Console]::CursorVisible = $false } catch {}

    while ($true) {
        Show-Header $Title
        Write-Host " [↑/↓] Навигация  [Enter] Выбор  [Esc] Назад" -ForegroundColor DarkGray
        Write-Host " ────────────────────────────────────────────────" -ForegroundColor DarkCyan

        for ($i = 0; $i -lt $Options.Count; $i++) {
            $prefix = "   "
            $color = "White"
            $bg = "Black"
            
            if ($i -eq $index) {
                $prefix = " ->"
                $color = "Cyan"
                $bg = "DarkBlue"
            }
            
            Write-Host "$prefix $($Options[$i].Label)" -ForegroundColor $color -BackgroundColor $bg
        }
        
        $key = [Console]::ReadKey($true)
        
        if ($key.Key -eq "UpArrow") { 
            $index-- 
            if ($index -lt 0) { $index = $max }
        }
        elseif ($key.Key -eq "DownArrow") { 
            $index++ 
            if ($index -gt $max) { $index = 0 }
        }
        elseif ($key.Key -eq "Enter") {
            try { [Console]::CursorVisible = $true } catch {}
            return $Options[$index].Value
        }
        elseif ($key.Key -eq "Escape" -or $key.Key -eq "Q") {
            try { [Console]::CursorVisible = $true } catch {}
            return "EXIT"
        }
    }
}

function Show-MultiSelect-Interactive {
    param($Title, $Options)
    $index = 0
    $max = $Options.Count - 1
    $selectionState = @{} 
    
    # Hide Cursor
    try { [Console]::CursorVisible = $false } catch {}

    while ($true) {
        Show-Header $Title
        Write-Host " [↑/↓] Навигация  [Space] Отметить  [Enter] Готово  [Esc] Отмена" -ForegroundColor DarkGray
        Write-Host " ────────────────────────────────────────────────" -ForegroundColor DarkCyan

        for ($i = 0; $i -lt $Options.Count; $i++) {
            $prefix = "   "
            $mark = "[ ]"
            $color = "White"
            $bg = "Black"
            
            if ($selectionState[$i]) { $mark = "[*]"; $color = "Green" }
            
            if ($i -eq $index) {
                $prefix = " ->"
                if ($selectionState[$i]) { $color = "Green"; $bg = "DarkBlue" } else { $color = "Cyan"; $bg = "DarkBlue" }
            }
            
            Write-Host "$prefix $mark $($Options[$i].Label)" -ForegroundColor $color -BackgroundColor $bg
        }
        
        $key = [Console]::ReadKey($true)
        
        if ($key.Key -eq "UpArrow") { 
            $index-- 
            if ($index -lt 0) { $index = $max }
        }
        elseif ($key.Key -eq "DownArrow") { 
            $index++ 
            if ($index -gt $max) { $index = 0 }
        }
        elseif ($key.Key -eq "Spacebar") {
            $selectionState[$index] = -not $selectionState[$index]
        }
        elseif ($key.Key -eq "Enter") {
            try { [Console]::CursorVisible = $true } catch {}
            $selectedValues = @()
            foreach($k in $selectionState.Keys) {
                if ($selectionState[$k]) { $selectedValues += $Options[$k].Value }
            }
            return $selectedValues
        }
        elseif ($key.Key -eq "Escape" -or $key.Key -eq "Q") {
            try { [Console]::CursorVisible = $true } catch {}
            return @()
        }
    }
}

function Change-Drive {
    Show-Header "--- НАСТРОЙКА ДИСКА ---"
    Write-Host "Текущий диск для установки/папок: " -NoNewline; Write-Host "$($Global:WorkDrive):" -ForegroundColor Green
    Write-Host "`nВведите новую букву диска (напр. D, E, F) или Enter для отмены."
    
    $newDrive = Read-Host " > Буква"
    $clean = $newDrive -replace ":", "" -replace " ", ""
    
    if ($clean) {
        $Global:WorkDrive = $clean.ToUpper()
        $Global:AppsPath = "$($Global:WorkDrive):\Programs"
        Write-Host "Диск изменен на $($Global:WorkDrive):" -ForegroundColor Green
        Start-Sleep -Seconds 1
    }
}

# --- MAIN LOOP ---
Init-Setup

$mainMenu = @(
    @{Label="1.  [SYSTEM]  Точка восстановления"; Value="1"},
    @{Label="2.  [DEBLOAT] Удаление мусора Microsoft"; Value="2"},
    @{Label="3.  [TWEAKS]  Твики интерфейса"; Value="3"},
    @{Label="4.  [SOFT]    Установка программ"; Value="4"},
    @{Label="5.  [LIBS]    Библиотеки (C++, DirectX)"; Value="5"},
    @{Label="6.  [CLEAN]   Очистка (Lite / Deep)"; Value="6"},
    @{Label="7.  [FOLDERS] Создать структуру папок"; Value="7"},
    @{Label="8.  [ACTIV]   Активация (MAS)"; Value="8"},
    @{Label="9.  [RESTORE] Меню восстановления"; Value="9"},
    @{Label="0.  [SERVICE] Службы (Откл. лишнего)"; Value="0"},
    @{Label="L.  [LATENCY] Уменьшение задержки"; Value="L"},
    @{Label="D.  [DRIVE]   Сменить рабочий диск"; Value="D"},
    @{Label="T.  [FUN]     Мини-тетрис"; Value="T"},
    @{Label="S.  [FUN]     Змейка"; Value="S"},
    @{Label="M.  [FUN]     Matrix mode"; Value="M"},
    @{Label="B.  [INFO]    Инфо о системе"; Value="B"},
    @{Label="G.  [BENCH]   Мини-бенчмарк"; Value="G"},
    @{Label="A.  [ABOUT]   О твикере"; Value="A"},
    @{Label="Q.  [EXIT]    Выход"; Value="EXIT"}
)

do {
    $sel = Show-Menu-Interactive " ГЛАВНОЕ МЕНЮ" $mainMenu
    
    switch ($sel) {
        '1' { if(Show-Confirmation "Создать точку восстановления?") { Create-RestorePoint } }
        '2' { Start-Debloat }
        '3' { Start-Tweaks }
        '4' { Install-Soft }
        '5' { if(Show-Confirmation "Установить библиотеки C++?") { Install-Runtimes } }
        '6' { Start-Clean }
        '7' { Create-Folders }
        '8' { if(Show-Confirmation "Запустить активатор MAS?") { Activate-Win } }
        '9' { Start-RestoreMenu }
        '0' { Start-ServicesMenu }
        'L' { Start-LatencyOpt }
        'D' { Change-Drive }
        'T' { Play-Tetris }
        'S' { Play-Snake }
        'M' { Run-Matrix }
        'B' { Show-SystemBanner; Pause }
        'G' { Run-MicroBenchmark }
        'A' { Show-About }
        'EXIT' { exit }
    }
} while ($true)



