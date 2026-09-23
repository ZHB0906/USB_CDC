# STM32F103C8 USB CDC build script for PowerShell
$ErrorActionPreference = "Stop"

$BASE = "E:\Robo\RoboRTS-Firmware-icra2021\USBcdc"
$TOOLS = "$BASE\tools\linker"
$USB = "$BASE\USB"
$OUTDIR = "$BASE\build"

# Create output dir
New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null

# Compiler
$CC = "arm-none-eabi-gcc"
$OBJCOPY = "arm-none-eabi-objcopy"
$OBJDUMP = "arm-none-eabi-objdump"
$SIZE = "arm-none-eabi-size"

# CPU and common flags
$CPU_FLAGS = "-mcpu=cortex-m3 -mthumb -mfloat-abi=soft"
$COMMON_FLAGS = "$CPU_FLAGS -Og -g3 -Wall -Wextra -Wno-unused-parameter -ffunction-sections -fdata-sections -fno-common -DSTM32F103xB -DUSE_HAL_DRIVER"

# Include paths
$INCLUDES = @(
    "-I$USB\Core\Inc"
    "-I$USB\Drivers\STM32F1xx_HAL_Driver\Inc"
    "-I$USB\Drivers\STM32F1xx_HAL_Driver\Inc\Legacy"
    "-I$USB\Drivers\CMSIS\Include"
    "-I$USB\Drivers\CMSIS\Device\ST\STM32F1xx\Include"
    "-I$USB\Middlewares\ST\STM32_USB_Device_Library\Core\Inc"
    "-I$USB\Middlewares\ST\STM32_USB_Device_Library\Class\CDC\Inc"
    "-I$USB\USB_DEVICE\App"
    "-I$USB\USB_DEVICE\Target"
    "-I$USB\Middlewares\support"
)

# Source files
$SRCS = @(
    "$TOOLS\startup_stm32f103xb.S"
    "$USB\Core\Src\main.c"
    "$USB\Core\Src\gpio.c"
    "$USB\Core\Src\stm32f1xx_it.c"
    "$USB\Core\Src\system_stm32f1xx.c"
    "$USB\Core\Src\stm32f1xx_hal_msp.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_cortex.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_dma.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_exti.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_flash.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_flash_ex.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_gpio.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_gpio_ex.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_pcd.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_pcd_ex.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_pwr.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_rcc.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_rcc_ex.c"
    "$USB\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_ll_usb.c"
    "$USB\Middlewares\ST\STM32_USB_Device_Library\Core\Src\usbd_core.c"
    "$USB\Middlewares\ST\STM32_USB_Device_Library\Core\Src\usbd_ctlreq.c"
    "$USB\Middlewares\ST\STM32_USB_Device_Library\Core\Src\usbd_ioreq.c"
    "$USB\Middlewares\ST\STM32_USB_Device_Library\Class\CDC\Src\usbd_cdc.c"
    "$USB\USB_DEVICE\App\usb_device.c"
    "$USB\USB_DEVICE\App\usbd_cdc_if.c"
    "$USB\USB_DEVICE\App\usbd_desc.c"
    "$USB\USB_DEVICE\Target\usbd_conf.c"
    "$USB\Middlewares\support\fifo.c"
)

$LINKER_SCRIPT = "$TOOLS\STM32F103C8_FLASH.ld"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Building USB CDC for STM32F103C8 ..."
Write-Host "============================================================"

# Build the complete argument list
$args_list = @(
    $COMMON_FLAGS.Split(" ")
    $INCLUDES
    $SRCS
    "-o", "$OUTDIR\usb_cdc_f103.elf"
    "-nostartfiles"
    "-Wl,-Map=$OUTDIR\usb_cdc_f103.map,--cref"
    "-Wl,--gc-sections"
    "-Wl,--print-memory-usage"
    "-T$LINKER_SCRIPT"
    "-lm"
)

& $CC @args_list 2>&1 | ForEach-Object { Write-Host $_ }

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Build FAILED!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Build succeeded, generating binary files ..." -ForegroundColor Green

& $OBJCOPY -Oihex "$OUTDIR\usb_cdc_f103.elf" "$OUTDIR\usb_cdc_f103.hex"
& $OBJCOPY -Obinary "$OUTDIR\usb_cdc_f103.elf" "$OUTDIR\usb_cdc_f103.bin"
& $SIZE -B "$OUTDIR\usb_cdc_f103.elf"
& $OBJDUMP -S "$OUTDIR\usb_cdc_f103.elf" > "$OUTDIR\usb_cdc_f103.lss"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Build done! Output: $OUTDIR"
Write-Host "  Flash file: usb_cdc_f103.bin / .hex"
Write-Host "============================================================"
