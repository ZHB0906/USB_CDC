cmake_minimum_required(VERSION 3.10)

# 项目配置
set(APPLICATION_NAME "usb_cdc_f103")
project(${APPLICATION_NAME} C CXX ASM)

# 路径变量
set(USB_ROOT ${CMAKE_SOURCE_DIR}/USB)
set(TOOLS_ROOT ${CMAKE_SOURCE_DIR}/tools)

# ============================================================
# Include 目录
# ============================================================
set(INCLUDE_DIRS
    ${USB_ROOT}/Core/Inc
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Inc
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Inc/Legacy
    ${USB_ROOT}/Drivers/CMSIS/Include
    ${USB_ROOT}/Drivers/CMSIS/Device/ST/STM32F1xx/Include
    ${USB_ROOT}/Middlewares/ST/STM32_USB_Device_Library/Core/Inc
    ${USB_ROOT}/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc
    ${USB_ROOT}/USB_DEVICE/App
    ${USB_ROOT}/USB_DEVICE/Target
    ${USB_ROOT}/Middlewares/support
)

# ============================================================
# 源文件列表
# ============================================================
set(SDK_SOURCES
    # GCC 启动文件
    ${TOOLS_ROOT}/linker/startup_stm32f103xb.S

    # CubeMX Core
    ${USB_ROOT}/Core/Src/main.c
    ${USB_ROOT}/Core/Src/gpio.c
    ${USB_ROOT}/Core/Src/stm32f1xx_it.c
    ${USB_ROOT}/Core/Src/system_stm32f1xx.c
    ${USB_ROOT}/Core/Src/stm32f1xx_hal_msp.c

    # STM32F1xx HAL Driver
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_cortex.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_dma.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_exti.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_flash.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_flash_ex.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio_ex.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_pcd.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_pcd_ex.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_pwr.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc_ex.c
    ${USB_ROOT}/Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_ll_usb.c

    # STM32 USB Device Library Core
    ${USB_ROOT}/Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_core.c
    ${USB_ROOT}/Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_ctlreq.c
    ${USB_ROOT}/Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_ioreq.c

    # STM32 USB CDC Class
    ${USB_ROOT}/Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Src/usbd_cdc.c

    # USB Device 应用层 (CubeMX 生成)
    ${USB_ROOT}/USB_DEVICE/App/usb_device.c
    ${USB_ROOT}/USB_DEVICE/App/usbd_cdc_if.c
    ${USB_ROOT}/USB_DEVICE/App/usbd_desc.c
    ${USB_ROOT}/USB_DEVICE/Target/usbd_conf.c

    # FIFO 驱动
    ${USB_ROOT}/Middlewares/support/fifo.c
)

# ============================================================
# 构建类型
# ============================================================
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

if(CMAKE_BUILD_TYPE MATCHES Debug)
    message(STATUS "Debug build.")
    set(OPT_LEVEL -Og)
    set(DEBUG_FLAGS -g3)
else()
    message(STATUS "Release build.")
    set(OPT_LEVEL -Os)
    set(DEBUG_FLAGS "")
endif()

# ============================================================
# 链接脚本
# ============================================================
get_filename_component(LINKER_SCRIPT ${TOOLS_ROOT}/linker/STM32F103C8_FLASH.ld ABSOLUTE)

# ============================================================
# 可执行文件
# ============================================================
set(ELF_FILE ${APPLICATION_NAME}.elf)
add_executable(${ELF_FILE} ${SDK_SOURCES})

# ============================================================
# Include 路径
# ============================================================
target_include_directories(${ELF_FILE} PUBLIC ${INCLUDE_DIRS})

# ============================================================
# 编译宏
# ============================================================
target_compile_definitions(${ELF_FILE} PUBLIC
    STM32F103xB
    USE_HAL_DRIVER
)

# ============================================================
# 编译选项
# ============================================================
set(CPU_FLAGS "-mcpu=cortex-m3 -mthumb -mfloat-abi=soft")

target_compile_options(${ELF_FILE} PRIVATE
    ${CPU_FLAGS}
    ${OPT_LEVEL}
    ${DEBUG_FLAGS}
    -Wall
    -Wextra
    -Wno-unused-parameter
    -ffunction-sections
    -fdata-sections
    -fno-common
    --specs=nano.specs
)

target_compile_options(${ELF_FILE} PUBLIC
    ${CPU_FLAGS}
)

# ASM 文件编译选项
target_compile_options(${ELF_FILE} PRIVATE
    ${CPU_FLAGS}
    -x assembler-with-cpp
)

# ============================================================
# 链接选项
# ============================================================
target_link_options(${ELF_FILE} PRIVATE
    ${CPU_FLAGS}
    -nostartfiles
    -Wl,-Map=${APPLICATION_NAME}.map,--cref
    -Wl,--gc-sections
    -Wl,--print-memory-usage
    --specs=nano.specs
    -T${LINKER_SCRIPT}
)

target_link_libraries(${ELF_FILE} PRIVATE
    -lm
)

# ============================================================
# 后处理:生成 .bin / .hex / .lss / size 报告
# ============================================================
add_custom_command(TARGET ${ELF_FILE} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -Oihex ${ELF_FILE} ${APPLICATION_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -Obinary ${ELF_FILE} ${APPLICATION_NAME}.bin
    COMMAND ${CMAKE_SIZE} -B ${ELF_FILE}
    COMMAND ${CMAKE_OBJDUMP} -S ${ELF_FILE} > ${APPLICATION_NAME}.lss
    COMMENT "Generating .hex .bin .lss and size report"
)
