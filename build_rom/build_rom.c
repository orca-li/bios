#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

enum {
    MAX_FILE_NAME = 100,

    ITEM_COUNT = 1,
    ROM_SIZE_INDEX = 0x2,
    Plug_and_Play_HDR_PTR = 0x1A,
    Plug_and_Play_CHKSUM_INDEX = 0x9,
    Plug_and_Play_HDR_SIZE_INDEX = 0x5,
    ROM_CHKSUM = 0x10
};

static int
ZeroExtend(char *f_name, u32 target_size)
{
    FILE *f_in;
    long file_size, target_file_size, padding_size;
    char *pch_buff;

    target_file_size = target_size; // Приводим тип ulong к типу long

    if ((f_in = fopen(f_name, "ab")) == NULL)
    {
        printf("Не удалось открыть файл\nПрограмма закрывается...\n");
        return -1;
    }
    
    if (fseek(f_in, 0, SEEK_END) != 0)
    {
        printf("Не удалось открыть файл\nПрограмма закрывается...\n");
        fclose(f_in);
        return -1;
    }

    if ((file_size = ftell(f_in)) == -1)
    {
        printf("Не удалось вычислить размер файла\nПрограмма закрывается...\n");
        fclose(f_in);
        return -1;
    }

    if (file_size >= target_file_size)
    {
        printf("Ошибка ввода - Размер файла назначения меньше, чем размер исходного файла\n");
        fclose(f_in);
        return -1;
    }

    /*
     * Добавляем нулевые байты в файл назначения
     */
    padding_size = target_file_size - file_size;
    pch_buff = (char*)malloc(sizeof(char) * padding_size);
    if (NULL != pch_buff)
    {
        memset(pch_buff, 0, sizeof(char) * padding_size);
        fseek(f_in, 0, SEEK_END);
        fwrite(pch_buff, sizeof(char), padding_size, f_in);
        fclose(f_in);
        free(pch_buff);
        return 0; // Success
    } else {
        fclose(f_in);;
        return -1;
    }
}

static u8 CalcCheckSum(FILE *fp, u32 size)
{
    u32 position = 0x00; /* указатель позиции в файле */
    u8 checksum = 0x00;

    /* устанавливаем указатель позиции на начало файла */
    if (!fseek(fp, 0, SEEK_SET))
    {
        /**
         * вычисляем 8-битную crc u8
         * размер файла = размер * 512 байт = размер * 0x200
         */
        
        for (; position < (size * 0x200); position++)
        {
            checksum = ((checksum + fgetc(fp)) % 0x100);
        }

        printf("calculated checksum = %#x\n", checksum);
    } 
    else
    {
        printf("function CalcChecksum:Failed to seek through"
            "the beginning of file\n");
    }

    return checksum;
}

static int
Patch2Plug_and_PlayRom(char *f_name)
{
    FILE *fp;
    u8 checksum_byte;
    u32 rom_size; /* Размер исходного кода BIOS расширения в блоках по 512 байт */
    u8 Plug_and_Play_header_pos;
    u8 Plug_and_Play_checksum = 0x00;
}