.global mandelbrot

@ Function to test whether a given coordinates escapes the mandelbrot set.
@ r0 contains a pointer to the complex number to try.
@ r1 contains the number of iterations to use.
@ Returns:
@ * r1 will be 1 if this point escaped, 0 otherwise.
@ * r2 will be the amount of iterations that it took for the point to escape,
@ given that r1 is 1.
@ * r0 will be untouched.
_mandelbrot_escapes:
  push {r0, r4, fp, lr}
  mov fp, sp
  sub sp, #0x10

  @ Store r1 (num iters) at sp + 0x0c
  str r1, [sp, #0x0c]
  @ initialise z on the stack at fp
  mov r1, #0
  vmov s0, r1
  vcvt.f32.u32 s0, s0
  vstr.f32 s0, [sp]
  vstr.f32 s0, [sp, #0x04]
  @ Store r0 at sp + 0x08
  str r0, [sp, #0x08]

  mov r4, #0
  _mandelbrot_escapes_loop:
  @ Square z
  mov r0, sp
  mov r1, sp
  bl complex_mul
  @ Add z to c
  ldr r1, [sp, #0x08]
  bl complex_add
  @ Get len2 and compare to threshold squared (4.0)
  bl complex_len_2
  vmov.f32 s0, #4.0
  vmov.f32 s1, r1
  vcmp.f32 s1, s0
  vmrs APSR_nzcv, FPSCR @ Move vfp flags to integer flags register
  bgt _mandelbrot_escapes_escape
  @ Increment iterations & loop again
  add r4, #1

  ldr r1, [sp, #0x0c]
  cmp r4, r1
  bne _mandelbrot_escapes_loop

  @ If we're here, we didn't escape - return 0
  mov r1, #0
  b end

  _mandelbrot_escapes_escape:
  @ If we're here, we escaped - return 1
  mov r1, #1

  end:
  add sp, #0x10
  mov r2, r4
  pop {r0, r4, fp, pc}

@ Render the mandelbrot set, given a framebuffer, and left / right / top /
@ bottom floating point numbers for scaling the final image to the
@ framebuffer.
@ 
@ r0 contains a pointer to the framebuffer. The framebuffer struct is as
@ follows:
@ u32 pointer to actual framebuffer data
@ u32 framebuffer width in pixels
@ u32 framebuffer height in pixels
@ ***
@ The framebuffer is assumed to be _RGB (4 BPP, with last 3 bytes used on
@ B/8, G/8, R/8, last byte unused).
@
@ r1 contains a pointer to the scaling for the framebuffer. This structure is
@ as follows:
@ f32 left
@ f32 top
@ f32 right
@ f32 bottom
@ These are values in space that the mandelbrot set should be rendered at in
@ the framebuffer. To maintain aspect ratio, frambuffer height / width should
@ be the same as (right - left)/(top - bottom).
@ Example values:
@ left   = -2.0
@ top    =  2.0
@ right  =  2.0
@ bottom = -2.0
@
@ r2 contains the number of iterations to use.
mandelbrot:
  push {r4 - r10, fp, lr}
  mov fp, sp
  sub sp, #0x20

  @ Load sizing into stack
  ldr r4, [r1]
  ldr r5, [r1, #0x04]
  ldr r6, [r1, #0x08]
  ldr r7, [r1, #0x0C]
  str r4, [sp]
  str r5, [sp, #0x04]
  str r6, [sp, #0x08]
  str r7, [sp, #0x0C]
  @ Load max iters into stack
  str r2, [sp, #0x18]

  @ Load FB ptr into r10
  ldr r10, [r0]
  @ Load FB w / h into r6 / r7
  ldr r6, [r0, #0x04]
  ldr r7, [r0, #0x08]
  @ Initialise iterator vars, r4 = rownum, r5 = pixnum (initialised in loop)
  mov r4, #0

  @ First, loop over each row of the framebuffer, then each pixel. 
  mandelbrot_row_loop:
    mov r5, #0

    mandelbrot_column_loop:
    @@ Find x pos and y pos in graph (i.e. the complex number)
    @ Get FB pos as decimal from 0 to 1
    vmov.u32 s0, r5
    vmov.u32 s1, r4
    vmov.u32 s2, r6
    vmov.u32 s3, r7
    vcvt.f32.u32 s0, s0
    vcvt.f32.u32 s1, s1
    vcvt.f32.u32 s2, s2
    vcvt.f32.u32 s3, s3
    vdiv.f32 s0, s0, s2
    vdiv.f32 s1, s1, s3

    @ Get view width / height
    vldr.f32 s2, [sp, #0x08] @ right
    vldr.f32 s3, [sp, #0x04] @ top
    vldr.f32 s4, [sp, #0x00] @ left
    vldr.f32 s5, [sp, #0x0C] @ bottom
    vsub.f32 d1, d2

    @ Mul width / height by decimal positions
    vmul.f32 d0, d1

    @ Now add onto left / bottom to get actual complex number
    vldr.f32 s2, [sp, #0x00] @ left
    vldr.f32 s3, [sp, #0x0C] @ bottom
    vadd.f32 d0, d1

    @ Store complex number in memory, then get pointer to it for
    @ _mandelbrot_escapes function
    vstr.f32 s0, [sp, #0x10]
    vstr.f32 s1, [sp, #0x14]
    add r0, sp, #0x10
    ldr r1, [sp, #0x18]
    bl _mandelbrot_escapes

    @ Find the position in memory to draw the pixel
    mla r8, r4, r6, r5
    mov r0, #4
    mul r8, r8, r0

    @ If escaped, draw a white pixel - otherwise, black
    cmp r1, #1
    beq mandelbrot_draw_escaped

    @ Not escaped
    mov r9, #0xff000000
    str r9, [r10, r8]
    b mandelbrot_end_pixel_loop

    mandelbrot_draw_escaped:
    @ Escaped
    ldr r0, [sp, #0x18]
    vmov.u32 s0, r2
    vmov.u32 s1, r0
    vcvt.f32.u32 s0, s0
    vcvt.f32.u32 s1, s1
    vdiv.f32 s0, s0, s1
    mov r0, #0xff
    vmov.f32 s1, r0
    vcvt.f32.u32 s1, s1
    vmul.f32 s0, s1
    vcvt.u32.f32 s0, s0
    vmov.u32 r0, s0

    mov r9, r0
    str r9, [r10, r8]

    mandelbrot_end_pixel_loop:
    add r5, r5, #1
    cmp r5, r6
    bne mandelbrot_column_loop

  add r4, #1
  cmp r4, r7
  bne mandelbrot_row_loop

  add sp, #0x20
  pop {r4 - r10, fp, pc}

