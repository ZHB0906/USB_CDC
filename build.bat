@echo off
setlocal

cd /d "E:\Robo\RoboRTS-Firmware-icra2021\USBcdc"

set CC=arm-none-eabi-gcc
set OBJCOPY=arm-none-eabi-objcopy
set OBJDUMP=arm-none-eabi-objdump
set SIZE=arm-none-eabi-size

set BASE=E:\Robo\RoboRTS-Firmware-icra2021\USBcdc
set TOOLS=%BASE%\tools\linker
set USB=%BASE%\USB
set OUTDIR=%BASE%\build

if not exist %OUTDIR% mkdir %OUTDIR%

set CPU=-mcpu=cortex-m3 -mthumb -mfloat-abi=soft
set FLAGS=%CPU% -Og -g3 -Wall -Wextra -Wno-unused-parameter -ffunction-sections -fdata-sections -fno-common -DSTM32F103xB -DUSE_HAL_DRIVER

set INCLUDES=-I%USB%\Core\Inc -I%USB%\Drivers\STM32F1xx_HAL_Driver\Inc -I%USB%\Drivers\STM32F1xx_HAL_Driver\Inc\Legacy -I%USB%\Drivers\CMSIS\Include -I%USB%\Drivers\CMSIS\Device\ST\STM32F1xx\Include -I%USB%\Middlewares\ST\STM32_USB_Device_Library\Core\Inc -I%USB%\Middlewares\ST\STM32_USB_Device_Library\Class\CDC\Inc -I%USB%\USB_DEVICE\App -I%USB%\USB_DEVICE\Target -I%USB%\Middlewares\support

set SRCS=^
%TOOLS%\startup_stm32f103xb.S ^
%USB%\Core\Src\main.c ^
%USB%\Core\Src\gpio.c ^
%USB%\Core\Src\stm32f1xx_it.c ^
%USB%\Core\Src\system_stm32f1xx.c ^
%USB%\Core\Src\stm32f1xx_hal_msp.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_cortex.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_dma.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_exti.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_flash.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_flash_ex.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_gpio.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_gpio_ex.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_pcd.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_pcd_ex.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_pwr.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_rcc.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_hal_rcc_ex.c ^
%USB%\Drivers\STM32F1xx_HAL_Driver\Src\stm32f1xx_ll_usb.c ^
%USB%\Middlewares\ST\STM32_USB_Device_Library\Core\Src\usbd_core.c ^
%USB%\Middlewares\ST\STM32_USB_Device_Library\Core\Src\usbd_ctlreq.c ^
%USB%\Middlewares\ST\STM32_USB_Device_Library\Core\Src\usbd_ioreq.c ^
%USB%\Middlewares\ST\STM32_USB_Device_Library\Class\CDC\Src\usbd_cdc.c ^
%USB%\USB_DEVICE\App\usb_device.c ^
%USB%\USB_DEVICE\App\usbd_cdc_if.c ^
%USB%\USB_DEVICE\App\usbd_desc.c ^
%USB%\USB_DEVICE\Target\usbd_conf.c ^
%USB%\Middlewares\support\fifo.c

echo Building...
%CC% %FLAGS% %INCLUDES% %SRCS% -o %OUTDIR%\usb_cdc_f103.elf -nostartfiles -Wl,--gc-sections -T%TOOLS%\STM32F103C8_FLASH.ld -lm 2>&1

if errorlevel 1 (
    echo BUILD FAILED
    exit /b 1
)

echo BUILD SUCCEEDED
%OBJCOPY% -Oihex %OUTDIR%\usb_cdc_f103.elf %OUTDIR%\usb_cdc_f103.hex
%OBJCOPY% -Obinary %OUTDIR%\usb_cdc_f103.elf %OUTDIR%\usb_cdc_f103.bin
%SIZE% -B %OUTDIR%\usb_cdc_f103.elf

endlocal
