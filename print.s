.global print_i

@ Print an integer stored in r0 to UART0
print_i:
  push {r4, r5, r11, fp, lr}
  mov fp, sp

  @ Reserve space for the number as a string - we're going to buffer the number
  @ here then reverse
  sub sp, #16

  @ Pointer to the start of the buffer
  mov r4, sp

  @ Loop until r0 is 0, finding the remainder & printing
  mov r5, #48 @ 48 is ascii for 0
  ldr r11, =0x101f1000 @ UART0 port
  print_i_buffer_loop:
  @ Divide & get remainder in r1
  mov r1, #10
  bl div_i @ r0 / 10
  add r1, r5

  @ Buffer digit
  str r1, [r4]

  add r4, #1
  cmp r0, #0
  bne print_i_buffer_loop

  @ Now print the whole buffer
  print_i_loop:
  ldr r0, [r4]
  str r0, [r11]
  sub r4, #1
  cmp r4, sp
  bge print_i_loop

  add sp, #16

  pop {r4, r5, r11, pc}

print_endl:
