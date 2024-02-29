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
    pushq %r11
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    pushq %rdi
    pushq %rsi
    pushq %rbx

    // Extract RGB components of existing color
    call get_r //get red component
    movl %eax, %r10d //store red component
    call get_g //get green component
    movl %eax, %r11d //store green component
    call get_b //get blue component
    movl %eax, %r12d //store blue component

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
    xorl %eax, %eax // Clear eax
    shl $24, %r10d // Shift left 24 bits
    movl %r10d, %eax // Move red component to eax
    //shl $24, %eax // Shift left 24 bits
	shl $16, %r11d  // Shift left 16 bits
    orl %r11d, %eax // Combine with green component
    shl $8, %r12d // Shift left 8 bits
    orl %r12d, %eax // Combine with blue component
	
	orl $255, %eax // Set alpha to 255
    
    popq %rbx
    popq %rsi
    popq %rdi
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %r11
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
    pushq %r8
    pushq %r9
    pushq %r10
    pushq %r11
    pushq %rbx

	subq $16, %rsp  // Align the stack

    call in_bounds // Check if the pixel is in bounds
    cmp $0, %rax // Test the result
    je .out_of_bounds // If not in bounds, jump to out_of_bounds

    movq 8(%rdi), %rbx // Load the image data array
    movl %edx, %r8d // Move the y coordinate to r8d for compute_index
    movl %esi, %r9d  // Move the x coordinate to r9d for compute_index
    call compute_index // Compute the index into the image data array
    movl %eax, %r10d // Move the index to r10d for the address calculation
    //imull $4, %r10d // Multiply the index by 4 to get the byte offset
    //addl %r10d, %ebx // Add the index to the image data array address

    movl %ecx, %edx   // Move the color value to edx for blend_colors
    //movl (%ebx), %edi // Load the existing color value from the image data array
    movl (%rbx, %r10, 4), %edi // Load the existing color value from the image data array
    call blend_colors // Blend the color value with the existing color

    // Store the blended color value in the image data array
	movl %eax, (%rbx, %r10, 4) // Store the blended color value

    addq $16, %rsp  // Restore the stack
    popq %rbx
    popq %r11
    popq %r10
    popq %r9
    popq %r8
	popq %rdi // Restore the image pointer
    ret


.out_of_bounds:
    addq $16, %rsp  // Restore the stack
    popq %rbx
    popq %r11
    popq %r10
    popq %r9
    popq %r8
	popq %rdi // Restore the image pointer
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
    subq $16, %rsp // Align the stack
    pushq %rdi
    pushq %rsi
    pushq %rbp
    movl %edx, %ebp // Store color value in %rbp
    movq %rdi, %r15

    // Load struct Rect fields
    movl RECT_X_OFFSET(%rsi), %ecx // Load x coordinate
    movl RECT_Y_OFFSET(%rsi), %edx // Load y coordinate
    movl RECT_WIDTH_OFFSET(%rsi), %r8d // Load width
    movl RECT_HEIGHT_OFFSET(%rsi), %r9d // Load height

    // Compute start and end coordinates
    movl %ecx, %r10d // Set x_start = x
    cmpl $0, %r10d // Check if x < 0
    jge .x_non_negative // Jump if x >= 0
    xorl %r10d, %r10d // Set x_start = 0
    
.x_non_negative:
    movl %r10d, %r14d
    movl %edx, %r11d // Set y_start = y
    cmpl $0, %r11d // Check if y < 0
    jge .y_non_negative // Jump if y >= 0
    xorl %r11d, %r11d // Set y_start = 0
.y_non_negative:
    movl IMAGE_WIDTH_OFFSET(%rdi), %esi // Load image width
    movl IMAGE_HEIGHT_OFFSET(%rdi), %edi // Load image height

    addl %ecx, %r8d // x_end = x + width
    cmpl %esi, %r8d // Check if x_end > image width
    jle .x_end_within_bounds // Jump if x_end <= image width
    movl %esi, %r8d // Set x_end = image width
.x_end_within_bounds:
    addl %edx, %r9d // y_end = y + height
    cmpl %edi, %r9d // Check if y_end > image height
    jle .y_loop // Jump if y_end <= image height
    movl %edi, %r9d // Set y_end = image height
 
.y_loop:
    cmpl %r9d, %r11d // Compare j with y_end
    jge .y_loop_end // If j >= y_end, exit y loop

.x_loop:
    cmpl %r8d, %r10d // Compare i with x_end
    jge .x_loop_end // If i >= x_end, exit x loop
    movq %r15, %rdi
    movl %r11d, %edx // Move y coordinate to rdi for draw_pixel
    movl %r10d, %esi // Move x coordinate to rsi for draw_pixel
    movl %ebp, %ecx // Move color value to rdx for draw_pixel
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %rcx
    pushq %r8
    pushq %r9
    pushq %r10
    pushq %r11
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    call draw_pixel // Draw the pixel
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %r11
    popq %r10
    popq %r9
    popq %r8
    popq %rcx
    popq %rdx
    popq %rsi
    popq %rdi
    incl %r10d // Increment i
    jmp .x_loop // Repeat x loop
.x_loop_end:
    incl %r11d // Increment j
    movl %r14d, %r10d // Reset i to x_start
    jmp .y_loop // Repeat y loop
.y_loop_end:

    popq %rbp
    popq %rsi
    popq %rdi
    addq $16, %rsp // Restore the stack
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
    pushq %rbp
    movq %rsp, %rbp // Save stack frame
    subq $128, %rsp // Make room for variables

    movq %rdi, -8(%rbp) // Save parameters
    movq %rsi, -16(%rbp)
    movq %rdx, -24(%rbp)
    movq %rcx, -32(%rbp)
    movq %r8, -40(%rbp)

    movl 0(%rdi), %r8d // Load image width
    movl 4(%rdi), %r9d // Load image height
    movq -16(%rbp), %r10 // Load x (circle center x)
    movq -24(%rbp), %r11 // Load y (circle center y)
    movq -32(%rbp), %r12 // Load r (radius)
    imulq %r12, %r12 // Square r
    movq %rdi, %rbx

    xorl %esi, %esi // Initialize i (x coordinate)
.y_loop_c:
    cmpl %r8d, %esi // Compare i with image width
    jge .y_loop_end_c // If i >= image width, exit y loop

    xorl %edx, %edx // Initialize j (y coordinate)
.x_loop_c:
    cmpl %r9d, %edx // Compare j with image height
    jge .x_loop_end_c // If j >= image height, exit x loop

    // Calculate radius squared
    movl %esi, %r14d // Move i (x coordinate) to %r14
    subq %r10, %r14 // Subtract circle center x
    imulq %r14, %r14 // Square (x - circle center x)
    movl %edx, %r15d // Move j (y coordinate) to %r15
    subq %r11, %r15 // Subtract circle center y
    imulq %r15, %r15 // Square (y - circle center y)
    addq %r15, %r14 // Add (x - circle center x)^2 + (y - circle center y)^2
    cmpq %r12, %r14 // Compare radius squared with r^2
    jg .skip_draw // If radius squared > r^2, skip drawing pixel

    // Draw pixel
    movq -40(%rbp), %rcx // Move color value to rdx for draw_pixel
    movq %rbx, %rdi // Move image pointer to rdi for draw_pixel
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %rcx
    pushq %r8
    pushq %r9
    pushq %r10
    pushq %r11
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    call draw_pixel // Draw the pixel
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %r11
    popq %r10
    popq %r9
    popq %r8
    popq %rcx
    popq %rdx
    popq %rsi
    popq %rdi

.skip_draw:
    incl %edx // Increment j
    jmp .x_loop_c // Repeat x loop
.x_loop_end_c:
    incl %esi // Increment i
    jmp .y_loop_c // Repeat y loop
.y_loop_end_c:

    movq %rbp, %rsp // Restore stack pointer
    popq %rbp // Restore base pointer
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