#define UART_TX_ADDR 0x10000000u

static volatile unsigned char *const UART_TX =
    (volatile unsigned char *)UART_TX_ADDR;

static void uart_putc(char c)
{
    *UART_TX = (unsigned char)c;
}

int main(void)
{
    uart_putc('H');
    uart_putc('i');
    uart_putc('\n');

    return 0;
}