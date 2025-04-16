/*
 * FreeRTOS Kernel V11.1.0
 * Copyright (C) 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * SPDX-License-Identifier: MIT
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

/*
 * This is a simple main that will start the FreeRTOS-Kernel and run a periodic task
 * that only delays if compiled with the template port, this project will do nothing.
 * For more information on getting started please look here:
 * https://freertos.org/FreeRTOS-quick-start-guide.html
 */

/* FreeRTOS includes. */
#include <FreeRTOS.h>
#include <task.h>
#include <queue.h>
#include <timers.h>
#include <semphr.h>

/* Standard includes. */
#include <stdio.h>

#ifndef FALSE
#define FALSE 0
#define TRUE 1
#endif

/*-----------------------------------------------------------*/

static void BlinkTask( void * parameters );

/*-----------------------------------------------------------*/

static void BlinkTask( void * parameters )
{
    unsigned char F_Blink = FALSE;

    /* Unused parameters. */
    ( void ) parameters; // <-- ???

    ( void ) printf( "Example FreeRTOS Project\n" );

    while( 1 )
    {
        if( F_Blink == FALSE )
        {
            F_Blink = TRUE;
        }
        else
        {
            F_Blink = FALSE;
        }

        vTaskDelay( 1000 ); /* delay 1000 ticks */
    }
}
/*-----------------------------------------------------------*/

extern unsigned short get_int_counter_16( void ); // freertos_crt0.asm

void main( void )
{
    static StaticTask_t BlinkTaskTCB;
    static StackType_t BlinkTaskStack[ configMINIMAL_STACK_SIZE ];
    unsigned int wait;
    TickType_t xDelayTime;

    wait = 500;
	xDelayTime = xTaskGetTickCount();
	vTaskDelayUntil( &xDelayTime, wait );

    ( void ) xTaskCreateStatic( BlinkTask,
                                "example",
                                configMINIMAL_STACK_SIZE,
                                NULL,
                                configMAX_PRIORITIES - 1U,
                                &( BlinkTaskStack[ 0 ] ),
                                &( BlinkTaskTCB ) );

    /* Start the scheduler. */
    vTaskStartScheduler();

    for( ; ; )
    {
        /* Should not reach here. */
    }
}
/*-----------------------------------------------------------*/

#if ( configCHECK_FOR_STACK_OVERFLOW > 0 )

    void vApplicationStackOverflowHook( TaskHandle_t xTask,
                                        char * pcTaskName )
    {
        /* Check pcTaskName for the name of the offending task,
         * or pxCurrentTCB if pcTaskName has itself been corrupted. */
        ( void ) xTask;
        ( void ) pcTaskName;
    }

#endif /* #if ( configCHECK_FOR_STACK_OVERFLOW > 0 ) */
/*-----------------------------------------------------------*/
