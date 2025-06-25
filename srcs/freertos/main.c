// 

#include <FreeRTOS.h>
#include <task.h>
//#include <queue.h>
//#include <timers.h>
#include <semphr.h>

#include <stdio.h>

#ifndef FALSE
#define FALSE 0
#define TRUE 1
#endif

static void BlinkTask( void * parameters )
{
    unsigned char F_Blink = FALSE;

    //
    vTaskDelay( 1000 ); /* delay 1000 ticks */
    ( void ) printf( ">>> Start Blink\n" );

    //
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
    xTaskCreate( BlinkTask, "Blink",
				 configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 1,
				 NULL ); // <-- ( pxCreatedTask * )NULL ???

    /* Start the scheduler. */
    vTaskStartScheduler();

    for( ; ; );
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
