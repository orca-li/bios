void 
out(unsigned short _port, unsigned char _data);
unsigned char 
in(unsigned short _port);

void
clrscr()
{
    unsigned char *vidmem = (unsigned char *)0xB8000;
    const long size = 80 * 25;
    long loop;

    // Очищаем видимую видео память
    for (loop = 0; loop < size; loop++)
    {
        *vidmem++ = 0;
        *vidmem++ = 0xF;
    }

    out(0x3D4, 14);
    out(0x3D5, 0);
    out(0x3D4, 15);
    out(0x3D5, 0);
}

void
print(const char *_message)
{
    unsigned short offset;
    unsigned long i;
    unsigned char *vidmem = (unsigned char *)0xB8000;

    // Считываем позицию курсора
    out(0x3D4, 14);
    offset = in(0x3D5) << 8;
    out(0x3D4, 15);
    offset |= in(0x3D5);

    // Начинаем вывод с позиции курсора
    vidmem += offset*2;

    // Продолжаем до символа нуля
    i = 0;
    while(_message[i] != 0)
    {
        *vidmem = _message[i++];
        vidmem += 2;
    }

    // Устанавливаем новую позицию курсора
    offset += i;
    out(0x3D5, (unsigned char)(offset));
    out(0x3D4, 14);
    out(0x3D5, (unsigned char)(offset >> 8));
}