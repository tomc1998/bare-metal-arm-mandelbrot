.global div_i

@ Div a0 by a1, and return the result in a0 with the remainder in a1
div_i:
  push {fp}
  mov fp, sp

  mov r2, #0

  div_i_loop:
  subs r0, r1
  bmi  div_i_end
  add  r2, #1
  b    div_i_loop

  div_i_end:
  add r0, r1
  mov r1, r0
  mov r0, r2

  pop {fp}

  mov pc, lr

