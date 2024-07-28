void print(char *string) {
  char r;
  int t;
  while (1) {
    r = string[t];
    if (r == 0) break;
    *(char *)(0xb8000 + t*2) = r;
    t++;
  }
}

void main() {
  char msg[] = "Hello world\0";
  print(&msg[0]);
}

