#define WIDTH 80
#define HEIGHT 25
#define DEAD 0x00
#define ALIVE 0xff

unsigned short lfsr;
unsigned bit;

int screen[WIDTH * HEIGHT];
int count[WIDTH * HEIGHT];

void init_screen();
void print_screen(int *);
unsigned rand();
void iteration();

// kernel entry point function
void main() {
  lfsr = 0xACE1u;
  init_screen();
  while (1) {
    print_screen(&screen[0]);
    iteration();
  }
}

void init_screen() {
  for (int h = 1; h < HEIGHT-1; ++h) {
    for (int w = 1; w < WIDTH-1; ++w) {
      screen[w + h * WIDTH] = (rand()%10 != 1) ? DEAD : ALIVE;
      count[w + h * WIDTH] = 0;
    }
  }
}

void print_screen(int *screen) {
  int t = 0;
  while (1) {
    *(char *)(0xb8000 + t*2) = ' ';
    *(char *)(0xb8000 + t*2 + 1) = screen[t];
    t++;
    if (t >= HEIGHT * WIDTH) break;
  }
}

unsigned rand(){
  bit  = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5) ) & 1;
  return lfsr = (lfsr >> 1) | (bit << 15);
}

void iteration() {

}

