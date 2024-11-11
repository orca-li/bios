void
clrscr();
void
print(const char *_message);

int main()
{
    const char *hello = "Hello World!";
    clrscr();
    print(hello);

    for(;;);

    return 0;
}