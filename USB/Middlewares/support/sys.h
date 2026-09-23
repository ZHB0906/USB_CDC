/****************************************************************************
 *  F103 USB CDC 简化版 sys.h
 *  只保留 FIFO 库需要的基础定义,去掉 F407/FreeRTOS 依赖
 ***************************************************************************/

#ifndef __SYS_INCLUDES_H__
#define __SYS_INCLUDES_H__

#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#include "stm32f1xx.h"
#include "stm32f1xx_hal.h"

/* boolean type definitions */
#ifndef TRUE
    #define TRUE  1
#endif

#ifndef FALSE
    #define FALSE 0
#endif

#ifndef ENABLE
    #define ENABLE  1
#endif

#ifndef DISABLE
    #define DISABLE 0
#endif

/* Cortex-M3 中断控制宏 */
#define INT_STATE              uint32_t
#define MASTER_INT_STATE_GET() __get_PRIMASK()
#define MASTER_INT_ENABLE()    do{__enable_irq();  }while(0)
#define MASTER_INT_DISABLE()   do{__disable_irq(); }while(0)
#define MASTER_INT_RESTORE(x)  do{__set_PRIMASK(x);}while(0)

#define var_cpu_sr() register unsigned long cpu_sr

#define enter_critical()      \
  do                          \
  {                           \
    cpu_sr = __get_PRIMASK(); \
    __disable_irq();          \
  } while (0)

#define exit_critical()    \
  do                       \
  {                        \
    __set_PRIMASK(cpu_sr); \
  } while (0)

/* FIFO 使用的互斥锁 — 用关中断实现 */
#define MUTEX_DECLARE(mutex) unsigned long mutex
#define MUTEX_INIT(mutex)    do{mutex = 0;}while(0)
#define MUTEX_LOCK(mutex)    do{__disable_irq();}while(0)
#define MUTEX_UNLOCK(mutex)  do{__enable_irq();}while(0)

#endif /* __SYS_INCLUDES_H__ */
