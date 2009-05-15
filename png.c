#include <stdio.h>
#include <stdlib.h>

#define PNG_DEBUG 3
#include <png.h>

int main()
{
  unsigned char header[8];
  FILE *fp = fopen("./32.png", "rb");
  fread(header, 1, 8, fp);
  if(png_sig_cmp(header, 0, 8))
  {
    printf("Not a png file\n");
    exit(0);
  }
  
  png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  png_infop info_ptr = png_create_info_struct(png_ptr);
  if(setjmp(png_jmpbuf(png_ptr)))
  {
    printf("libpng error\n");
    exit(0);
  }
  png_init_io(png_ptr, fp);
  png_set_sig_bytes(png_ptr, 8);
  png_read_info(png_ptr, info_ptr);
  
  int width = info_ptr->width;
  int height = info_ptr->height;
  
  png_bytep *row_pointers = (png_bytep*)malloc(sizeof(png_bytep)*height);
  int x,y;
  for(y = 0; y < height; y++)
    row_pointers[y] = (png_byte*)malloc(info_ptr->rowbytes);
  png_read_image(png_ptr, row_pointers);
  
  for(y=0;y<height;y++)
  {
    png_byte *row = row_pointers[y];
    for(x=0;x<info_ptr->rowbytes;x++)
    {
      printf("%d\n", row[x]);
    }
  }
  
  printf("done\n");
  exit(0);
}

