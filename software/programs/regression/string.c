static const char message[] = "Hi";

int main(void)
{
    volatile const char *pointer = message;

    return pointer[0] + pointer[1];
}