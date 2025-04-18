/*
 * FreeRTOS Kernel V10.5.1+
 * Copyright (C) 2020 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * https://www.FreeRTOS.org
 * https://github.com/FreeRTOS
 *
 */


#include <stdlib.h>

#include "FreeRTOS.h"

/*-----------------------------------------------------------*/

/* We require the address of the pxCurrentTCB variable, but don't want to know
any details of its type. */

typedef void TCB_t;
extern volatile TCB_t * volatile pxCurrentTCB;

/*-----------------------------------------------------------*/

/*
 * Macros to set up, restart (reload), and stop the PRT1 Timer used for
 * the System Tick.
 */

//#define configTICK_RATE_HZ              (256)               /* Timer configured */
#define configISR_ORG                   ASMPC               /* ISR relocation */
#define configISR_IVT                   0xFFE6              /* PRT1 address */

void port_configSETUP_TIMER_INTERRUPT()
{
#asm
    di
    push    af
    push    hl
    EXTERN  _tick_timer_isr
    EXTERN  int_timer_hook
    ld hl, _tick_timer_isr
    ld (int_timer_hook + 1), hl
    ld  a, 0x0CD
    ld (int_timer_hook), a
    pop hl
    pop af
    ei
#endasm
}
#define configSETUP_TIMER_INTERRUPT() void port_configSETUP_TIMER_INTERRUPT()

#define configRESET_TIMER_INTERRUPT() \
    do{ \
    }while(0)   // do nothing


void port_configSTOP_TIMER_INTERRUPT()
{
#asm
    di
    push    af
    push    hl
    EXTERN  int_timer_hook
    ld  hl, 0
    ld (int_timer_hook + 1), hl
    xor a
    ld (int_timer_hook), a
    pop hl
    pop af
    ei
#endasm
}
#define configSTOP_TIMER_INTERRUPT() port_configSTOP_TIMER_INTERRUPT()

/*-----------------------------------------------------------*/

/*
 * Perform hardware setup to enable ticks from Timer.
 */
static void prvSetupTimerInterrupt( void ) __preserves_regs(iyh,iyl);

/*-----------------------------------------------------------*/

/*
 * See header file for description.
 */
StackType_t *pxPortInitialiseStack( StackType_t *pxTopOfStack, TaskFunction_t pxCode, void *pvParameters )
{
    /* Place the parameter on the stack in the expected location. */
    *pxTopOfStack-- = ( StackType_t ) pvParameters;

    /* Place the task return address on stack. Not used */
    *pxTopOfStack-- = ( StackType_t ) 0;

    /* The start of the task code will be popped off the stack last, so place
    it on first. */
    *pxTopOfStack-- = ( StackType_t ) pxCode;

    /* Now the registers. */
    *pxTopOfStack-- = ( StackType_t ) 0xAFAF;   /* AF  */
    *pxTopOfStack-- = ( StackType_t ) 0x0404;   /* IF  */
    *pxTopOfStack-- = ( StackType_t ) 0xBCBC;   /* BC  */
    *pxTopOfStack-- = ( StackType_t ) 0xDEDE;   /* DE  */
    *pxTopOfStack-- = ( StackType_t ) 0xEFEF;   /* HL  */
    *pxTopOfStack-- = ( StackType_t ) 0xFAFA;   /* AF' */
    *pxTopOfStack-- = ( StackType_t ) 0xCBCB;   /* BC' */
    *pxTopOfStack-- = ( StackType_t ) 0xEDED;   /* DE' */
    *pxTopOfStack-- = ( StackType_t ) 0xFEFE;   /* HL' */
    *pxTopOfStack-- = ( StackType_t ) 0xCEFA;   /* IX  */
    *pxTopOfStack   = ( StackType_t ) 0xADDE;   /* IY  */

    return pxTopOfStack;
}
/*-----------------------------------------------------------*/

BaseType_t xPortStartScheduler( void ) __preserves_regs(a,b,c,d,e,iyh,iyl) __naked
{
    /* Setup the relevant timer hardware to generate the tick. */
    prvSetupTimerInterrupt();

    /* Restore the context of the first task that is going to run. */
    portRESTORE_CONTEXT();

    /* Should not get here. */
    return pdFALSE;
}
/*-----------------------------------------------------------*/

void vPortEndScheduler( void ) __preserves_regs(b,c,d,e,h,l,iyh,iyl)
{
    /*
     * It is unlikely that the Z80 port will get stopped.
     * If required simply disable the tick interrupt here.
     */
    configSTOP_TIMER_INTERRUPT();
}
/*-----------------------------------------------------------*/

/*
 * Manual context switch.  The first thing we do is save the registers so we
 * can use a naked attribute. This is called by the application, so we don't have
 * to check which bank is loaded.
 */
void vPortYield( void ) __preserves_regs(a,b,c,d,e,h,l,iyh,iyl) __naked
{
    portSAVE_CONTEXT();
//    vTaskSwitchContext();
    portRESTORE_CONTEXT();
}
/*-----------------------------------------------------------*/

/*
 * Manual context switch callable from ISRs. The first thing we do is save
 * the registers so we can use a naked attribute.
 */
void vPortYieldFromISR(void)  __preserves_regs(a,b,c,d,e,h,l,iyh,iyl) __naked
{
    portSAVE_CONTEXT_IN_ISR();
//    vTaskSwitchContext();
    portRESTORE_CONTEXT_IN_ISR();
}
/*-----------------------------------------------------------*/

/*
 * Initialize Timer (PRT1 for YAZ180, and SCZ180 HBIOS).
 */
void prvSetupTimerInterrupt( void ) __preserves_regs(iyh,iyl)
{
    configSETUP_TIMER_INTERRUPT();
}
/*-----------------------------------------------------------*/

void tick_timer_isr(void) __preserves_regs(a,b,c,d,e,h,l,iyh,iyl) __naked
{
#if configUSE_PREEMPTION == 1
    /*
     * Tick ISR for preemptive scheduler.  We can use a naked attribute as
     * the context is saved at the start of timer_isr().  The tick
     * count is incremented after the context is saved.
     *
     * Context switch function used by the tick.  This must be identical to
     * vPortYield() from the call to vTaskSwitchContext() onwards.  The only
     * difference from vPortYield() is the tick count is incremented as the
     * call comes from the tick ISR.
     */
    portSAVE_CONTEXT_IN_ISR();
    configRESET_TIMER_INTERRUPT();
//    xTaskIncrementTick();
//    vTaskSwitchContext();
    portRESTORE_CONTEXT_IN_ISR();
#else
    /*
     * Tick ISR for the cooperative scheduler.  All this does is increment the
     * tick count.  We don't need to switch context, this can only be done by
     * manual calls to taskYIELD();
     */
    portSAVE_CONTEXT_IN_ISR();
    configRESET_TIMER_INTERRUPT();
//    xTaskIncrementTick();
    portRESTORE_CONTEXT_IN_ISR();
#endif
} // configUSE_PREEMPTION
