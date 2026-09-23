# USBcdc — STM32F103 上的 USB CDC 虚拟串口


**把 STM32F103 变成一个扛得住实时控制回路的 USB 虚拟串口。**

---

## 一、这个项目

STM32F103C8T6 是最普及的 Cortex-M3。
把调试链路从 UART 换成 USB CDC 时，会撞上具体问题，这个工程就是为了把它们逐个解决并**可复现地**验证：

### 1. `printf` 不能阻塞控制回路

USB 全速是 **1 ms 帧、64 B 包**，天然是突发 + 高延迟的通道；而 CubeMX 默认生成的
`CDC_Transmit_FS()` 在上一包还没发完时直接返回 `USBD_BUSY` —— 调用方要么阻塞等待，要么丢数据。

在 1 kHz 的控制回路里每周期 `printf` 一次，这两条路都不能接受。
本工程用 **4096 B 发送 FIFO** 把「产生日志」和「发送日志」彻底解耦：写入 FIFO 是纯内存操作（微秒级、
可关中断保护），USB 发送由主循环按需搬运，控制回路的实时性不受 USB 影响。

### 2. 省掉一条调试线

一根 USB 线同时供电 + 输出串口，不需要额外的 USB-TTL 转接板，也不占用宝贵的 UART。
对于只剩一个 UART、又被电机/IMU 占满的小车平台，这是刚需。

---

## 二、数据通路

**发送（非阻塞的关键）**

```
printf() ──► _write() ──► CDC_Transmit_FS() ──► usb_tx_fifo (4096 B)
                                                      │
                                    主循环 usb_tx_flush() 每次搬 ≤1024 B
                                                      ▼
                                        UserTxBufferFS (1024 B) ──► USB IN 端点
```

**接收**

```
USB OUT ──► CDC_Receive_FS() ──► usb_vcp_rx_callback()（用户注册的回调）
```

上层只需注册一次回调，不必关心 USB 状态机：

```c
usb_vcp_rx_callback_register(my_handler);   /* int32_t (*)(uint8_t *buf, uint16_t len) */
```

`printf` 通过重定向 `_write()` 直接进 FIFO，所以你可以像在 PC 上一样打日志，无需额外封装：

```c
printf("imu: %.2f %.2f %.2f\r\n", ax, ay, az);
```

---

## 三、设计要点（几个踩过的坑）

- **FIFO 必须在 USB 初始化之前初始化。** `usb_tx_fifo_init()` 放在 `main()` 的 `SysInit` 阶段，
  早于 `MX_USB_DEVICE_Init()`。因为枚举过程中 `CDC_Init_FS()` 会执行，如果在那里初始化 FIFO，
  就会把启动时已经排队的 banner 数据清掉。代码里对这一点有显式注释。
- **没枚举完成就不发数据。** `usb_tx_flush()` 先检查 `dev_state == USBD_STATE_CONFIGURED`。
- **避免重入覆盖。** 发送前检查 `hcdc->TxState`，非 0 说明上一包还在飞，直接让出。
- **临界区保护。** 从 FIFO 取数据的「读长度 + 搬运」两步被关中断包住，保证 ISR 与主循环并发安全。
- **堆被显式禁用。** `_sbrk()` 返回 `NULL`（F103 只有 20 KB RAM，不留 malloc 空间），
  并补齐 `_close/_fstat/_isatty/_lseek/_open/_read` 等 newlib syscall stub。

---

## 四、硬件与资源占用

| 项目 | 值 |
|---|---|
| MCU | STM32F103C8T6（Cortex-M3，64 KB Flash / 20 KB SRAM） |
| 时钟 | HSE 8 MHz × PLL9 = **72 MHz** SYSCLK；USB 时钟 = PLL / 1.5 = **48 MHz** |
| USB | 全速设备，CDC 类，`VID:PID = 0x0483:0x5740`，产品串 `STM32 Virtual ComPort` |
| 缓冲 | TX FIFO 4096 B + 接收 1024 B + 发送 1024 B |

实测占用（Debug / `-Og`）：

| 段 | 字节 |
|---|---|
| `.text` | 22,956 |
| `.data` | 1,956 |
| `.bss` | 10,596 |
| **Flash 合计**（text+data） | **24,912 / 65,536（38%）** |
| **RAM 合计**（data+bss） | **12,552 / 20,480（61%）** |

RAM 占用的大头就是那三个缓冲（4 KB + 1 KB + 1 KB）——这是「不阻塞」付的代价，也是本工程的核心取舍。

---

## 五、目录结构

```
.
├── CMakeLists.txt                     # CMake 构建（arm-none-eabi-gcc）
├── build.bat / build.ps1              # 一键编译脚本
├── tools/
│   ├── cmake/arm-none-eabi-gcc.cmake  # 交叉编译工具链文件
│   └── linker/                        # GCC 启动文件 + 链接脚本（64K/20K）
└── USB/
    ├── USB.ioc / .mxproject           # STM32CubeMX 工程配置
    ├── Core/                          # CubeMX 生成：main.c / gpio.c / 中断
    ├── Drivers/                       # ST HAL + CMSIS（ST 官方源码）
    ├── Middlewares/
    │   ├── ST/                        # ST USB Device Library（CDC 类）
    │   └── support/                   # fifo.c/h + sys.h（RoboRTS 简化版）
    ├── USB_DEVICE/                    # CDC 接口 / 描述符 / USB 配置
    └── MDK-ARM/                       # Keil MDK-ARM 工程
```

---

## 六、编译

需要 `arm-none-eabi-gcc`（ARM GNU Toolchain）在 PATH 中；Keil 路线则需要 MDK-ARM。

### 方式 1：Keil MDK-ARM

打开 `USB/MDK-ARM/USB.uvprojx`，直接 Build / Download。

### 方式 2：CMake（推荐）

```bash
cmake -B build -DCMAKE_TOOLCHAIN_FILE=tools/cmake/arm-none-eabi-gcc.cmake -DCMAKE_BUILD_TYPE=Debug
cmake --build build
```

产物：`build/usb_cdc_f103.elf` / `.hex` / `.bin` / `.lss` / `.map`，并打印内存占用。

### 方式 3：一键脚本

```bat
build.bat
```

> ⚠️ `build.bat` 和 `build.ps1` 里**写死了绝对路径**
> （`E:\Robo\RoboRTS-Firmware-icra2021\USBcdc`），换机器/换目录必须先改这两个文件。
> 这也是建议优先用 CMake 的原因。

---

## 七、使用与验证

1. 烧录后插上 USB，系统识别为 USB 串行设备，出现 `COMx`（Windows）或 `/dev/ttyACM0`（Linux）。
2. **先打开串口，再复位开发板**（枚举完成前 FIFO 里的数据主机收不到），应看到：

   ```
   ===== USB CDC F103 START =====
   Send any char, board will echo it back
   ```

3. 发送任意字符，板子原样回显 —— 这就是 `usb_rx_test_callback()` 的回环。
4. 波特率随意设置（CDC 是批量传输，不依赖波特率）。

把回环回调换成你自己的解析函数，就是一个带日志能力的调试通道。

---

## 八、已知限制

- `CDC_Control_FS()` 里的 `SET_LINE_CODING` / `SET_CONTROL_LINE_STATE` 等控制请求**均为空实现**。
- 发送是 **1 ms 主循环轮询**（`usb_tx_flush()` + `HAL_Delay(1)`），不是中断驱动；
  高频日志下吞吐受限于此，可以改为发送完成回调触发。
- FIFO 满时 `CDC_Transmit_FS()` 返回 `USBD_BUSY` 并丢弃该次数据，调用方需自行取舍。
- 未实现 USB 挂起 / 唤醒回调。
- `build.bat` / `build.ps1` 硬编码绝对路径（见上）。
- `build_log.txt` 是一次历史构建的输出日志，非必要文件。

---

## 九、许可证与第三方代码

本仓库**不是全部原创**，分发时请注意：

- `USB/Drivers/**`（STM32F1xx HAL + CMSIS）与 `USB/Middlewares/ST/**`（USB Device Library）
  是 STM32CubeMX 随附的 **ST 官方源码**，版权归 ST，请遵循其条款；
  `USB/Drivers/` 下各目录附有独立的 `LICENSE.txt`。
- 其余工程代码（`CMakeLists.txt`、`tools/`、`USB/USB_DEVICE/`、`USB/Core/` 中的用户代码段）
  尚未指定开源许可证。
