
void print(char *);

void main() {
  char msg[] = "        \0";
  print(&msg[0]);
}

void print(char *string) {
  int r;
  int t;
  while (1) {
    r = string[t];
    if (r == 0) break;
    *(char *)(0xb8000 + t*2) = r;
    *(char *)(0xb8000 + t*2 + 1) = 0x6f;
    t++;
  }
}


