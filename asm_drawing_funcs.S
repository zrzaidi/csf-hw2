/*
 * Assembly-language implementations of the drawing functions
 */

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/* Offsets of struct Rect fields */
#define RECT_X_OFFSET        0
#define RECT_Y_OFFSET        4
#define RECT_WIDTH_OFFSET    8
#define RECT_HEIGHT_OFFSET   12

	.section .text

/***********************************************************************
   Helper functions
   You should declare these as .globl so that
   they can be called from the unit test code.
 ***********************************************************************/

/* TODO: implement your helper functions here */

get_r:
	movq %rdi, %rax
	shrq $24, %rax
	andl $0xFF, %eax
	ret

get_g:
	movq %rdi, %rax
	shrq $16, %rax
	andl $0xFF, %eax
	ret

get_b:
	movq %rdi, %rax
	shrq $8, %rax
	andl $0xFF, %eax
	ret

get_a:
	movq %rdi, %rax
	andl $0xFF, %eax
	ret

compute_index:
	movq 0(%rdi), %rax
	imul %rdx, %rax
	addq %rsi, %rax
	ret

in_bounds:
	cmp %rsi, 0(%rdi)
	jge out_of_bounds_x
	cmp %rdx, 4(%rdi)
	jge out_of_bounds_y
	cmp $0, %rsi
	jl out_of_bounds_x
	cmp $0, %rdx
	jl out_of_bounds_y
	movq $1, %rax
	ret

out_of_bounds_x:
	xorq %rax, %rax
	ret

out_of_bounds_y:
	xorq %rax, %rax
	ret

blend_components:
	movq %rdi, %rax
	imul %rdx, %rax
	movq $255, %rcx
	sub %rdx, %rcx
	imul %rsi, %rcx
	add %rcx, %rax
	movq 255, %r8
	idiv %r8
	ret

blend_colors:
	call get_a

	ret

/***********************************************************************
   Public API functions
 ***********************************************************************/

/*
 * Draw a pixel.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %esi     - x coordinate (pixel column)
 *   %edx     - y coordinate (pixel row)
 *   %ecx     - uint32_t color value
 */
	.globl draw_pixel
draw_pixel:
	call in_bounds
	test %rax, %rax
	je out_of_bounds

	movq %rdx, %r8
	movq %rsi, %r9
	call compute_index
	movq %rax, %r10

	



	ret


/*
 * Draw a rectangle.
 * The rectangle has rect->x,rect->y as its upper left corner,
 * is rect->width pixels wide, and rect->height pixels high.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %rsi     - pointer to struct Rect
 *   %edx     - uint32_t color value
 */
	.globl draw_rect
draw_rect:
	/* TODO: implement */
	ret

/*
 * Draw a circle.
 * The circle has x,y as its center and has r as its radius.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %esi     - x coordinate of circle's center
 *   %edx     - y coordinate of circle's center
 *   %ecx     - radius of circle
 *   %r8d     - uint32_t color value
 */
	.globl draw_circle
draw_circle:
	/* TODO: implement */
	ret

/*
 * Draw a tile by copying all pixels in the region
 * enclosed by the tile parameter in the tilemap image
 * to the specified x/y coordinates of the destination image.
 * No blending of the tile pixel colors with the background
 * colors should be done.
 *
 * Parameters:
 *   %rdi - pointer to Image (dest image)
 *   %esi - x coordinate of location where tile should be copied
 *   %edx - y coordinate of location where tile should be copied
 *   %rcx - pointer to Image (the tilemap)
 *   %r8  - pointer to Rect (the tile)
 */
	.globl draw_tile
draw_tile:
	/* TODO: implement */
	ret

/*
 * Draw a sprite by copying all pixels in the region
 * enclosed by the sprite parameter in the spritemap image
 * to the specified x/y coordinates of the destination image.
 * The alpha values of the sprite pixels should be used to
 * blend the sprite pixel colors with the background
 * pixel colors.
 *
 * Parameters:
 *   %rdi - pointer to Image (dest image)
 *   %esi - x coordinate of location where sprite should be copied
 *   %edx - y coordinate of location where sprite should be copied
 *   %rcx - pointer to Image (the spritemap)
 *   %r8  - pointer to Rect (the sprite)
 */
	.globl draw_sprite
draw_sprite:
	/* TODO: implement */
	ret

/*
vim:ft=gas:
*/
