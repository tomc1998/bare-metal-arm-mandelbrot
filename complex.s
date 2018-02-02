@@ Functions for handling complex numbers.

@@ Complex number struct definition
@ 2 32-bit floats make up a complex number. The first float is the real part,
@ the second is the imaginary part. These are packed next to eachother
@ to make up 64-bits of space. In general, these are passed by pointer to
@ functions.

.global complex_mul
.global complex_add
.global complex_len_2

@ Multiply a complex number with another complex number. 
@
@ r0 stores the address of the first complex number.
@ r1 stores the address of the second complex number.
@ The memory at r0 will be mutated, and will contain the result (the previous
@ r0 value will be lost).
@ 
@ You can also square a number by passing in r0 == r1.
complex_mul:
  push {fp}
  mov fp, sp

  @ (a + ib)(c + id) = ac + iad + ibc - bd
  @ We can use SIMD here to perform all the multiplications at once

  vldr.f32 s0, [r0]
  vldr.f32 s1, [r0]
  vldr.f32 s2, [r0, #0x04]
  vldr.f32 s3, [r0, #0x04]

  vldr.f32 s4, [r1]
  vldr.f32 s5, [r1, #0x04]
  vldr.f32 s6, [r1]
  vldr.f32 s7, [r1, #0x04]

  vmul.f32 q0, q1

  @ Now add together the parts of q0, so that the complex part is in s1 and
  @ real part in s0
  vadd.f32 s1, s2
  vsub.f32 s0, s3
  
  @ Write out the values
  vstr.f32 s0, [r0]
  vstr.f32 s1, [r0, #0x04]

  pop {fp}
  mov pc, lr

@ Add a complex number to another.
@ r0 stores the address of the first complex number.
@ r1 stores the address of the second complex number.
@ The memory at r0 will be mutated, and will contain the result (the previous
@ r0 value will be lost).
complex_add:
  push {fp}
  mov fp, sp

  @ (a + ib) + (c + id) = a + c + i(b + d)
  vldr.f32 s0, [r0]
  vldr.f32 s1, [r0, #0x04]
  vldr.f32 s2, [r1]
  vldr.f32 s3, [r1, #0x04]

  @ Perform add and store in [r0]
  vadd.f32 d0, d1
  vstr.f32 s0, [r0]
  vstr.f32 s1, [r0, #0x04]
  
  pop {fp}
  mov pc, lr

@ Find the length (squared) of a complex number.
@
@ r0 stores the address of the complex number's length to find.
@ r1 will contain the length (squared) of the complex number - r0 will be
@ preserved
complex_len_2:
  push {fp}
  mov fp, sp

  @ a^2 + b^2
  @ Using SIMD to perform all the multiplications at once
  vldr.f32 s0, [r0] @ a
  vldr.f32 s1, [r0, #0x04] @ b
  vldr.f32 s2, [r0] @ a
  vldr.f32 s3, [r0, #0x04] @ b

  @ square and sum
  vmul.f32 d0, d1
  vadd.f32 s0, s2

  @ Store result in r1, then return
  vmov.f32 r1, s0
  pop {fp}
  mov pc, lr

