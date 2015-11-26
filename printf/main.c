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
	uint16_t bytesToRead;
	char buffer[32];
	uint32_t bufferOffset = 0;

	uint64_t count;
	int i = 0;

	XMC_SCU_CLOCK_EnableUsbPll();
	XMC_SCU_CLOCK_StartUsbPll(2, 64);
	XMC_SCU_CLOCK_SetUsbClockDivider(4);
	XMC_SCU_CLOCK_SetUsbClockSource(XMC_SCU_CLOCK_USBCLKSRC_USBPLL);
	XMC_SCU_CLOCK_EnableClock(XMC_SCU_CLOCK_USB);

	SystemCoreClockUpdate();

	USB_Init();
	init_printf(NULL, tiny_putc);

	while(1) {
		// Get number of bytes to read
		bytesToRead = CDC_Device_BytesReceived(&VirtualSerial_CDC_Interface);
		// Load bytes into buffer
		bufferOffset = 0;
		while(bytesToRead-- > 0) {
			buffer[bufferOffset++] = CDC_Device_ReceiveByte(&VirtualSerial_CDC_Interface);
		}
		// Ensure Null Terminated
		buffer[bufferOffset] = '\0';

		// Send out an acknowledgment
		if (bufferOffset == 0) {
			debug_printf("Test String: %d\r\n", i++);
		} else {
			debug_printf("Received %d bytes: %s\r\n", bufferOffset, buffer);
		}
		// Wait for approximately 1 second
		count = 0x8FFFF0;
		while(--count) ;
	}
	return 0;
}

