// C implementations of drawing functions (and helper functions)

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include "drawing_funcs.h"

////////////////////////////////////////////////////////////////////////
// Helper functions
////////////////////////////////////////////////////////////////////////

// TODO: implement helper functions

uint8_t get_r(uint32_t color) {
  uint32_t shifted = color >> 24;
  return shifted & 0xFF;
}

uint8_t get_g(uint32_t color) {
  uint32_t shifted = color >> 16;
  return shifted & 0xFF;
}

uint8_t get_b(uint32_t color) {
  uint32_t shifted = color >> 8;
  return shifted & 0xFF;
}

uint8_t get_a(uint32_t color) {
  return color & 0xFF;
}

bool in_bounds(struct Image *img, int32_t x, int32_t y) {
  if (x >= img->width || y >= img->height || x < 0 || y < 0) {
    return false;
  }
  return true;
}

uint32_t compute_index(struct Image *img, int32_t x, int32_t y) {
  return img->width * y + x;
}

int32_t clamp(int32_t val, int32_t min, int32_t max) {
  if (val < min) {
    return min;
  } else if (val > max) {
    return max;
  }
  return val;

}

uint8_t blend_components(uint32_t fg, uint32_t bg, uint32_t alpha) {
  return (alpha * fg + (255 - alpha) * bg) / 255;
}

uint32_t blend_colors(uint32_t fg, uint32_t bg) {
  // blend foreground and background colors using the foreground color’s alpha value
  uint32_t fg_alpha = get_a(fg);
  return blend_components(get_r(fg), get_r(bg), fg_alpha);
}

////////////////////////////////////////////////////////////////////////
// API functions
////////////////////////////////////////////////////////////////////////

//
// Draw a pixel.
//
// Parameters:
//   img   - pointer to struct Image
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)
//   color - uint32_t color value
//
void draw_pixel(struct Image *img, int32_t x, int32_t y, uint32_t color) {
  uint32_t index = 0;
  if (in_bounds(img, x, y)) {
    index = compute_index(img, x, y);
  } else {
    return;
  }
  uint32_t background = img->data[index];
  uint32_t newColor = 0;
  if (get_a(color) == 255) {
    newColor = color;
  } else {
    newColor = ((get_a(color)*get_r(color) + (255 - get_a(color)) * get_r(background)) / 255) << 24;
    newColor = newColor | ((get_a(color)*get_g(color) + (255 - get_a(color)) * get_g(background)) / 255) << 16;
    newColor = newColor | ((get_a(color)*get_b(color) + (255 - get_a(color)) * get_b(background)) / 255) << 8;
    newColor = newColor | 255;
  }
  img->data[index] = newColor;
}

//
// Draw a rectangle.
// The rectangle has rect->x,rect->y as its upper left corner,
// is rect->width pixels wide, and rect->height pixels high.
//
// Parameters:
//   img     - pointer to struct Image
//   rect    - pointer to struct Rect
//   color   - uint32_t color value
//
void draw_rect(struct Image *img,
               const struct Rect *rect,
               uint32_t color) {
  
  int32_t x_start = rect->x < 0 ? 0 : rect->x;
  int32_t y_start = rect->y < 0 ? 0 : rect->y;
  int32_t x_end = rect->x + rect->width > img->width ? img->width : rect->x + rect->width;
  int32_t y_end = rect->y + rect->height > img->height ? img->height : rect->y + rect->height;

  for (int32_t i = x_start; i < x_end; i++) {
    for (int32_t j = y_start; j < y_end; j++) {
        draw_pixel(img, i, j, color);
    }
  }
}

//
// Draw a circle.
// The circle has x,y as its center and has r as its radius.
//
// Parameters:
//   img     - pointer to struct Image
//   x       - x coordinate of circle's center
//   y       - y coordinate of circle's center
//   r       - radius of circle
//   color   - uint32_t color value
//
void draw_circle(struct Image *img,
                 int32_t x, int32_t y, int32_t r,
                 uint32_t color) {
  for(uint32_t i = 0; i < img->width; i++){
    for(uint32_t j = 0; j < img->height; j++){
      uint32_t rad = (x - i)*(x - i) + (y - j)*(y - j);
      if (rad <= r*r) {
        draw_pixel(img, i, j, color);
      }
    }
  }
}

//
// Draw a tile by copying all pixels in the region
// enclosed by the tile parameter in the tilemap image
// to the specified x/y coordinates of the destination image.
// No blending of the tile pixel colors with the background
// colors should be done.
//
// Parameters:
//   img     - pointer to Image (dest image)
//   x       - x coordinate of location where tile should be copied
//   y       - y coordinate of location where tile should be copied
//   tilemap - pointer to Image (the tilemap)
//   tile    - pointer to Rect (the tile)
//
void draw_tile(struct Image *img,
               int32_t x, int32_t y,
               struct Image *tilemap,
               const struct Rect *tile) {
  // copy all pixels in the region enclosed by the tile parameter in the tilemap image to the specified x/y coordinates of the destination image
  uint32_t temp_pixel = 0;
  printf("tilemap width: %d\n", tilemap->width);
  printf("tilemap height: %d\n", tilemap->height);
  printf("img width: %d\n", img->width);
  printf("img height: %d\n", img->height);

  for(uint32_t row = 0; row < img->height; row++){
    for(uint32_t col = 0; col < img->width; col++){
      // check if the pixel is within the tile
      if (((row >= tile->y) && (row < (tile->y + tile->height))) && ((col >= tile->x) && (col < (tile->x + tile->width)))) {
        // store pixel from tilemap into temp_pixel
        temp_pixel = tilemap->data[compute_index(tilemap, col, row)];
        img->data[compute_index(img, col, row)] = temp_pixel;

        //draw_pixel(img, col, row, temp_pixel);
        
        printf("temp_pixel: %d\n", temp_pixel);
        printf("img pixel: %d\n", img->data[compute_index(img, row, col)]);
      }
    }
  }

  // printf("pixels meant to be copied and pasted: %d\n", tile->width * tile->height);
  // printf("pixels copied and pasted: %d\n", i);
}

//
// Draw a sprite by copying all pixels in the region
// enclosed by the sprite parameter in the spritemap image
// to the specified x/y coordinates of the destination image.
// The alpha values of the sprite pixels should be used to
// blend the sprite pixel colors with the background
// pixel colors.
//
// Parameters:
//   img       - pointer to Image (dest image)
//   x         - x coordinate of location where sprite should be copied
//   y         - y coordinate of location where sprite should be copied
//   spritemap - pointer to Image (the spritemap)
//   sprite    - pointer to Rect (the sprite)
//
void draw_sprite(struct Image *img,
                 int32_t x, int32_t y,
                 struct Image *spritemap,
                 const struct Rect *sprite) {
  // TODO: implement
  // copy all pixels in the region enclosed by the sprite parameter in the spritemap image to the specified x/y coordinates of the destination image
  // The alpha values of the sprite pixels should be used to blend the sprite pixel colors with the background pixel colors.
  uint32_t* temp_pixel = (uint32_t *)malloc(sizeof(uint32_t));

  for(uint32_t col = 0; col < img->width; col++){
    for(uint32_t row = 0; row < img->height; row++){
      // check if the pixel is within the sprite
      if ((row >= sprite->y) && (row < (sprite->y + sprite->height)) && (col >= sprite->x) && (col < (sprite->x + sprite->width))) {
        // store pixel from spritemap into temp_pixel
        *temp_pixel = spritemap->data[spritemap->width * row + col];
        // store temp_pixel into img (destination image)
        img->data[img->width * row + col] = blend_colors(*temp_pixel, img->data[img->width * row + col]);
      }
    }
  }

  free(temp_pixel);
}