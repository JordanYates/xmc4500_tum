/* Project Includes */
#include <stdarg.h>
#include "VirtualSerial.h"
#include "tinyprintf.h"

void debug_printf(char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	printf(fmt, args);
	va_end(args);

	CDC_Device_USBTask(&VirtualSerial_CDC_Interface);
	USB_USBTask();
}

void tiny_putc(void* p, char c)
{
	CDC_Device_SendByte(&VirtualSerial_CDC_Interface, (const uint8_t)c);
}

int main(void) {
	uint64_t count;
	int i;

	XMC_SCU_CLOCK_EnableUsbPll();
	XMC_SCU_CLOCK_StartUsbPll(2, 64);
	XMC_SCU_CLOCK_SetUsbClockDivider(4);
	XMC_SCU_CLOCK_SetUsbClockSource(XMC_SCU_CLOCK_USBCLKSRC_USBPLL);
	XMC_SCU_CLOCK_EnableClock(XMC_SCU_CLOCK_USB);

	SystemCoreClockUpdate();

	USB_Init();
	init_printf(NULL, tiny_putc);

	while(1) {
		debug_printf("Test String: %d\r\n", i++);

		count = 0x8FFFF0;
		while(--count) ;
	}
	return 0;
}

