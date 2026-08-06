static int add(int a, int b)
{
    return a + b;
}

static int increment(int value)
{
    return value + 1;
}

int main(void)
{
    return add(increment(3), increment(4));
}