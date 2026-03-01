@echo off
:: MoltOS USB-NEXT: OpenOS Runner (Windows)
:: Placed on the USB drive to launch the VMAGENT

echo ====================================================
echo           MOLTOS VMAGENT: STARTING OPENOS           
echo ====================================================

:: Get the directory of the batch script (USB root)
set USB_DIR=%~dp0
set IMAGE_PATH=%USB_DIR%openos-vmagent.qcow2

:: Basic verification
if not exist "%IMAGE_PATH%" (
    echo [X] Error: OpenOS VM image not found at %IMAGE_PATH%
    pause
    exit /b 1
)

:: Check if QEMU is installed
where qemu-system-x86_64.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [X] Error: QEMU is not installed or not in PATH.
    echo.
    echo To run OpenOS, please install QEMU for Windows:
    echo Option 1: choco install qemu
    echo Option 2: Download from https://qemu.weilnetz.de/w64/
    pause
    exit /b 1
)

echo.
echo Booting OpenOS VM with 4GB RAM, 2 Cores...
echo [!] Attempting to use Windows Hypervisor Platform (WHPX) acceleration
echo Do not close this CMD window until you shut down the VM.
echo ====================================================

:: Launch the VM using WHPX acceleration if available
qemu-system-x86_64.exe ^
    -accel whpx,kernel-irqchip=off ^
    -m 4096 ^
    -smp 2 ^
    -drive file="%IMAGE_PATH%",format=qcow2,if=virtio ^
    -net nic,model=virtio ^
    -net user,hostfwd=tcp::8080-:8080,hostfwd=tcp::11434-:11434 ^
    -vga std ^
    -audiodev pa,id=snd0 -machine pc

:: Fallback if WHPX fails
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [!] WHPX Acceleration failed. Attempting to fall back to HAXM or TCG (Slow Mode)...
    qemu-system-x86_64.exe ^
        -m 4096 ^
        -smp 2 ^
        -drive file="%IMAGE_PATH%",format=qcow2,if=virtio ^
        -net nic,model=virtio ^
        -net user,hostfwd=tcp::8080-:8080,hostfwd=tcp::11434-:11434 ^
        -vga std ^
        -audiodev pa,id=snd0 -machine pc
)

echo.
echo OpenOS VM Shutdown.
pause
