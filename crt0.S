.text
.code16

rom_size = 0x04                             # Размер ROM в сегментах по 512 байт
os_load_seg = 0x0000
os_code_size = ((rom_size - 1) * 512)
os_code_size16 = (os_code_size / 2)

# ----------------------------------- #
#      Загаловок BIOS расширения      #
# ----------------------------------- #

    .word 0xAA55                                # Байты 1 и 2 сигнатуры BIOS
    .byte rom_size                              # размер данной BIOS
    jmp _init

    .org 0x18
    .word _pci_data_struct                      # Указатель на структуру заголовка
                                                # PCI по 18h

    .word _pnp_header                           # Указатель на расширенный заголовок Plug-and-play

# ----------------------------------- #
#        Структура данных PCI         #
# ----------------------------------- #
_pci_data_struct:
    .ascii "PCIR"                               # Сигнатура заголовка PCI
    .word   0x9004                              # Идентификатор производителя
    .word   0x8178                              # Идентификатор устройства
    .word   0x00                                # Необходимые даннные о продкте (VPD)
    .word   0x18                                # Длина структуры данных PCI (байт)
    .byte   0x00                                # Статус изменения структуры PCI
    .byte   0x02                                # Код базового класса
                                                # 02h == сетевой контроллер
    .byte   0x00                                # Код подкласса == 00h и интерфейс == 00h
    .byte   0x00                                # Код интерфейса, см. спецификацию
                                                # PCI Rev2. в Приложение D.
    .word   rom_size                            # Длина образа в сегментах по 512 байт, прямой порядок байтов
    .word   0x00                                # Статус изменения
    .byte   0x00                                # Тип кода == x86
    .byte   0x80                                # Признак последнего образа
    .word   0x00                                # Зарезервировано

# ----------------------------------- #
# Заголовок BIOS расширения Plug-a... #
# ----------------------------------- #
_pnp_header:
    .ascii "$Pnp"                               # Сигнатура заголовка
                                                # BIOS Plug-and-Play
    .byte 0x01                                  # Статус изменения структуры
    .byte 0x02                                  # Длина структуры заголовка
                                                # В блоках по 16 байт
    .word 0x00                                  # Смещение следующего заголовка(00 если нет)
    .byte 0x00                                  # Зарезервировано
    .byte 0x00                                  # 8-битный crc для заголовка, вычислена и прошита утилитой patch2Plug-and-Playrom
    .long 0x00                                  # Идентификатор устройства
                                                # Plug-and-Play --> 0 в Realtek RPL ROM
    .word 0x00                                  # Указатель на строку идентификатора производителя; пустая строка
    .word 0x00                                  # Указатель на строку идентификатора производителя; пустая строка
    .byte 0x02, 0x00, 0x00                      # Код тип устройства, 3 байта
    .byte 0x14                                  # Признак устройства, 14h из RPL ROM -> см. ст.18 в спецификации Plug-and-Play BIOS,
                                                # Младший полубайт означает что уст-во IPL
    .word 0x00                                  # Вектор BCV, 00h = запрещен
    .word 0x00                                  # Вектор отключения, 00h = запрещен
    .word _start                                # Вектор BEV
    .word 0x00                                  # Вектор получения информации
                                                # о статических ресурсах; 0000h если не используется

# ----------------------------------- #
#  Код инициализации BIOS расширения  #
# ----------------------------------- #
_init:
    andw $0xCF, %ax                         # Сообщаем системной BIOS, что имеется подключенное устройство IPL
    orw $0x20, %ax                          # Plug-and-Play 1.0A.
    lret                                    # Возвращаемся (jmp far) в системную BIOS


.global _start                              # точка входа

_start:
    movw $0x9000, %ax                       # установка временного стека
    movw %ax, %ss                           # ss = 0x9000

# Код копирует сам себя из ROM в RAM
    movw %cs, %ax                           # инициализируем адрес источника
    movw %ax, %ds
    movw $os_load_seg, %ax                  # указываем на сегмент ОС
    movw %ax, %es
    movw %ax, %es
    movl $os_code_size16, %ecx
    subw %di, %di
    subw %si, %si
    cld
    rep
    movsw

    ljmp $os_load_seg, $_setup

_setup:
    movw %cs, %ax                           # инициализируем регистры сегмента
    movw %ax, %ds

enable_a20:
    cli

    call a20wait
    movb $0xAD, %al
    outb %al, $0x64

    call a20wait2
    inb $0x60, %al
    pushl %eax

    call a20wait
    movb $0xD1, %al
    outb %al, $0x64

    call a20wait
    popl %eax
    or $2, %al
    outb %al, $0x64

    call a20wait
    jmp continue

# a20wait:
#     movl $65536, %ecx
#     inb $0x64, %al
#     test $2, %al
#     jz 0x3f
#     loop 0x2B
#     jmp 0x1b
#     ret

# a20wait2:
#     movl $65536, %ecx
#     inb $0x64, %al
#     test $1, %al
#     jnz 0x3f
#     loop 0x2b
#     jmp 0x1b
#     ret

a20wait:
    movl $65536, %ecx
a20wait_loop:
    inb $0x64, %al
    test $2, %al
    jz a20wait_done
    dec %ecx
    jnz a20wait_loop
a20wait_done:
    ret

a20wait2:
    movl $65536, %ecx 
a20wait2_loop:
    inb $0x64, %al
    test $1, %al
    jnz a20wait2_done
    dec %ecx
    jnz a20wait2_loop
a20wait2_done:
    ret 

# Переключаемся в защищенный режим и делаем безусловный переход в ядро;
# Здесь нужен 32-битны режим, т.к. код будет исполняться в 32-битном режиме

continue:
    sti                                     # Включаем прерывания

    cli                                     # Выключаем прерывания

    lgdt gdt_desc                           # Загрузить GDT в GDTR

    movl %cr0, %eax                         # Переключаемся в защищенный режим
    or $1, %eax
    movl %eax, %cr0                         # Еще не в защищенном режиме,
                                            # нужно сделать FAR переход
    .byte 0x66, 0xEA                        # prefix + jmpi-opcode (это приводит к
                                            # принудительному входу в защищенный режим,
                                            # т.е. обновить регистр CS)
    .long do_pm                             # 32-битный линейный адрес
                                            # (назначение перехода)    
    .word SEG_CODE_SEL                      # Селектор сегмента кода                                            

do_pm:
    xorl %esi, %esi
    xorl %edi, %edi
    movw $0x10, %ax                         # Сохраняем идентификатор сегмента
                                            # данных (см. GDT)

    movw %ax, %ds
    movw $0x18, %ax                         # Сохраняем идентификатор сегмента стека
    movw %ax, %ss
    movl $0x90000, %esp

    jmp main
    .align 8                                # Выравниваем GDT по границе 8-байтного параграфа

# Определение GDT
gdt_marker:                                 # Фиктивный дескриптор сегмента GDT
    .long 0
    .long 0

SEG_CODE_SEL = (. - gdt_marker)
SegDesc1:                                   # Ядро CS (08h) PL0, 08h - идентификатор
    .word 0xffff                            # seg_length0_15
    .word 0                                 # base_addr0_15
    .byte 0                                 # base_addr16_23
    .byte 0x9A                              # Флаги
    .byte 0xCF                              # Доступ
    .byte 0                                 # base_addr24_31

SEG_DATA_SEL = (. - gdt_marker)
SegDesc2:                                   # Ядро DS (10h) PL0
    .word 0xffff                            # seg_length0_15
    .word 0                                 # base_addr0_15
    .byte 0                                 # base_addr16_23
    .byte 0x92                              # Флаги
    .byte 0xCF                              # Доступ
    .byte 0                                 # base_addr24_31

SEG_STACK_SEL = (. - gdt_marker)
SegDesc3:                                   # Ядро SS (18h) PL0
    .word 0xffff                            # seg_length0_15
    .word 0                                 # base_addr0_15
    .byte 0                                 # base_addr16_23
    .byte 0x92                              # Флаги
    .byte 0xCF                              # Доступ
    .byte 0                                 # base_addr24_31

gdt_end:

gdt_desc: .word (gdt_end - gdt_marker - 1)
# Предел GDT
    .long gdt_marker # Физический адрес GDT