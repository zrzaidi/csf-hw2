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
	.globl get_r
get_r:
	movl %edi, %eax //edi color
	shrl $24, %eax //shift right 24 bits
	andl $0xFF, %eax //and with 0xFF
	ret
	
	.globl get_g
get_g:
	movl %edi, %eax //edi color
	shrl $16, %eax //shift right 16 bits
	andl $0xFF, %eax //and with 0xFF
	ret

	.globl get_b
get_b:
	movl %edi, %eax //edi color
	shrl $8, %eax  //shift right 8 bits
	andl $0xFF, %eax //and with 0xFF
	ret

	.globl get_a
get_a:
	movl %edi, %eax //edi color
	andl $0xFF, %eax //and with 0xFF
	ret

	.globl compute_index
compute_index:
	movq 0(%rdi), %rax //width
	imul %rdx, %rax //multiply by y
	addq %rsi, %rax //add x
	ret

	.globl in_bounds
in_bounds:
	cmp $0, %esi //compare x with 0
    jl .out_of_bounds_x //if x < 0, jump to out_of_bounds_x
    cmp $0, %edx //compare y with 0
    jl .out_of_bounds_y //if y < 0, jump to out_of_bounds_y
    cmp %esi, 0(%rdi) //compare x with width
    jle .out_of_bounds_x //if x >= width, jump to out_of_bounds_x
    cmp %edx, 4(%rdi) //compare y with height
    jle .out_of_bounds_y //if y >= height, jump to out_of_bounds_y
    movq $1, %rax //return 1 if in bounds

    ret

.out_of_bounds_x:
	xorq %rax, %rax //return 0 if out of bounds
	ret

.out_of_bounds_y:
	xorq %rax, %rax //return 0 if out of bounds
	ret

	.globl blend_components
blend_components:
    pushq %r8
    pushq %r9
    pushq %rdx
	subq $16, %rsp // Align the stack
    movl %edi, %eax //edi fg, esi bg
    imull %edx, %eax //edx alpha
    movl $255, %r9d // Set up for subl
    subl %edx, %r9d //255 - alpha
    imull %esi, %r9d //bg * (255 - alpha)
    addl %r9d, %eax //fg * alpha + bg * (255 - alpha)
    xorl %edx, %edx  // Clear high bits of dividend
    movl $255, %r8d // Set up for divl
    divl %r8d // Divide by 255
    addq $16, %rsp // Restore the stack
    popq %rdx
    popq %r9
    popq %r8

    ret

	.globl blend_colors
blend_colors:
	subq $16, %rsp // Align the stack
    pushq %r10
    pushq %rdx
    
    movl 0(%ebx), %edi // Load existing color from image data

    // Extract RGB components of existing color
    call get_r //get red component
    movl %eax, %r10d //store red component
    call get_g //get green component
    movl %eax, %r11d //store green component
    call get_b //get blue component
    movl $0, %r12d //store blue component

    // Extract RGB components of incoming color
    movl %edx, %edi  // Incoming color is in ecx
    call get_r //get red component
    movl %eax, %r13d //store red component
    call get_g //get green component
    movl %eax, %r14d //store green component
    call get_b //get blue component
    movl %eax, %r15d //store blue component
	call get_a //get alpha component
	movl %eax, %edx  // Move alpha value to edx for blend_components

    // Blend each component separately
    movl %r10d, %esi // Move existing red component to esi
    movl %r13d, %edi // Move incoming red component to edi
    call blend_components  // For red component
    movl %eax, %r10d // Store blended red component

    movl %r11d, %esi // Move existing green component to esi
    movl %r14d, %edi // Move incoming green component to edi
    call blend_components  // For green component
    movl %eax, %r11d // Store blended green component

    movl %r12d, %esi // Move existing blue component to esi
    movl %r15d, %edi // Move incoming blue component to edi
    call blend_components  // For blue component
    movl %eax, %r12d // Store blended blue component

    // Assemble blended color
    movl %r10d, %eax // Move red component to eax
    shl $24, %eax // Shift left 24 bits
	shl $16, %r11d  // Shift left 16 bits
    orl %r11d, %eax // Combine with green component
    shl $8, %r12d // Shift left 8 bits
    orl %r12d, %eax // Combine with blue component
	
	orl $255, %eax // Set alpha to 255
    popq %rdx
    popq %r10

	addq $16, %rsp // Restore the stack

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
	pushq %rdi
	subq $16, %rsp  // Align the stack

    call in_bounds // Check if the pixel is in bounds
    test %eax, %eax // Test the result
    je out_of_bounds // If not in bounds, jump to out_of_bounds

    movq 8(%rdi), %rbx // Load the image data array
    movl %edx, %r8d // Move the y coordinate to r8d for compute_index
    movl %esi, %r9d  // Move the x coordinate to r9d for compute_index
    call compute_index // Compute the index into the image data array
    movl %eax, %r10d // Move the index to r10d for the address calculation
    imull $4, %r10d // Multiply the index by 4 to get the byte offset
    addl %r10d, %ebx // Add the index to the image data array address

    movl %ecx, %edx   // Move the color value to edx for blend_colors
    call blend_colors // Blend the color value with the existing color

    // Store the blended color value in the image data array
	movl %eax, (%ebx) // Store the blended color value

    addq $16, %rsp  // Restore the stack
	popq %rdi // Restore the image pointer
    ret

	.globl out_of_bounds
out_of_bounds:
    ret // Return if the pixel is out of bounds


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
    pushq %rbp
    movq %rsp, %rbp

    /* Load parameters */
    movq %rdi, %rbx         // img
    movq %rsi, %rcx         // rect
    movl %edx, %r8d         // color

    /* Calculate start and end coordinates */
    movl RECT_X_OFFSET(%rcx), %eax          // rect->x
    cmpl $0, %eax                           // Compare with 0
    jge .x_start_positive                   // If x >= 0, jump to x_start_positive
    xorl %eax, %eax                         // Set x_start to 0
    jmp .x_start_done                       // Jump to x_start_done

.x_start_positive:
    movl %eax, %r9d                         // Store x in r9d
    movl RECT_WIDTH_OFFSET(%rcx), %edx      // rect->width
    addl %edx, %eax                         // x + width
    movl IMAGE_WIDTH_OFFSET(%rbx), %edx     // img->width
    cmpl %eax, %edx                         // Compare x + width with img->width
    jge .x_start_done                       // If x + width >= img->width, jump to x_start_done
    movl %eax, %r9d                         // Store x + width in r9d
    jmp .x_start_done                       // Jump to x_start_done

.x_start_done:
    movl RECT_Y_OFFSET(%rcx), %eax          // rect->y
    cmpl $0, %eax                           // Compare with 0
    jge .y_start_positive                   // If y >= 0, jump to y_start_positive
    xorl %eax, %eax                         // Set y_start to 0
    jmp .y_start_done                       // Jump to y_start_done

.y_start_positive:
    movl %eax, %r10d                        // Store y in r10d
    movl RECT_HEIGHT_OFFSET(%rcx), %edx     // rect->height
    addl %edx, %eax                         // y + height
    movl IMAGE_HEIGHT_OFFSET(%rbx), %edx    // img->height
    cmpl %eax, %edx                         // Compare y + height with img->height
    jge .y_start_done                       // If y + height >= img->height, jump to y_start_done
    movl %eax, %r10d                        // Store y + height in r10d
    jmp .y_start_done                       // Jump to y_start_done

.y_start_done:
    /* Draw the rectangle */
    movl %r9d, %eax                         // x_start
    movl %r10d, %edx                        // y_start
    jmp .check_x_end                        // Jump to check_x_end

.draw_loop:
    movl %edx, %r10d                        // y
    pushq %r10                              // Push y to the stack
    pushq %rax                              // Push x to the stack
    movl %r8d, %esi                         // color
    movq %rbx, %rdi                         // img
    call draw_pixel                         // Call draw_pixel(img, x, y, color)
    popq %rax                               // Restore x from the stack
    incl %eax                               // Increment x
    cmp %r9d, %eax                          // Compare x with x_end
    jl .draw_loop                           // If x < x_end, loop back to draw_loop

.check_x_end:
    cmpl %r9d, %eax                         // Compare x with x_end
    jl .draw_loop                           // If x < x_end, jump to draw_loop

    popq %rbp
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