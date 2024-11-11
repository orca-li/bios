unsigned char 
in(unsigned short _port)
{
    // "=a" (результат) означает: По окончанию, загрузить значение
    // регистра AL в переменную result.
    // "d" (_port) означает: загрузить _port в регистр EDX
    unsigned char result;
    __asm__ ("in %%dx, %%al" : "=a" (result) : "d" (_port));
    return result;
}

void 
out(unsigned short _port, unsigned char _data)
{
    // "a" (_data) означает: загрузить _data в регистр EAX
    // "d" (_port) означает: загрузить _port в регистр EDX
    __asm__ ("out %%al, %%dx" : : "a" (_data), "d" (_port));
}