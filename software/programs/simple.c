const char message[] = "Hi";

int main(void)
{
    volatile const char *p = message;
    return p[0];
}