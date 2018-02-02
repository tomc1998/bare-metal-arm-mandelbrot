/* Memory Maps: */
/* Memory map for Versatile/PB:  */
/* 0x10000000 System registers.  */ 
/* 0x10001000 PCI controller config registers.  */ 
/* 0x10002000 Serial bus interface.  */            
/* 0x10003000 Secondary interrupt controller.  */ 
/* 0x10004000 AACI (audio).  */                    
/* 0x10005000 MMCI0.  */                          
/* 0x10006000 KMI0 (keyboard).  */                
/* 0x10007000 KMI1 (mouse).  */                   
/* 0x10008000 Character LCD Interface.  */         
/* 0x10009000 UART3.  */                          
/* 0x1000a000 Smart card 1.  */                    
/* 0x1000b000 MMCI1.  */                          
/* 0x10010000 Ethernet.  */                       
/* 0x10020000 USB.  */                             
/* 0x10100000 SSMC.  */                            
/* 0x10110000 MPMC.  */                            
/* 0x10000050 CLCD Control Register.  */                
/* 0x10120000 CLCD Controller.  */                
/* 0x10130000 DMA Controller.  */                 
/* 0x10140000 Vectored interrupt controller.  */  
/* 0x101d0000 AHB Monitor Interface.  */           
/* 0x101e0000 System Controller.  */               
/* 0x101e1000 Watchdog Interface.  */              
/* 0x101e2000 Timer 0/1.  */                       
/* 0x101e3000 Timer 2/3.  */                       
/* 0x101e4000 GPIO port 0.  */                     
/* 0x101e5000 GPIO port 1.  */                     
/* 0x101e6000 GPIO port 2.  */                     
/* 0x101e7000 GPIO port 3.  */                     
/* 0x101e8000 RTC.  */                             
/* 0x101f0000 Smart card 0.  */                    
/* 0x101f1000 UART0.  */                          
/* 0x101f2000 UART1.  */                          
/* 0x101f3000 UART2.  */                          
/* 0x101f4000 SSPI.  */                            
/* 0x34000000 NOR Flash */                         

.global _start

@ Function to sleep for r0 cycles
sleep:
  sleep_loop:
  nop
  subs r0, #1
  bne sleep_loop
  mov pc, lr

_start:
  @ Set up stack pointer
	mov sp, #0x08000000
  mov fp, sp

  @ Setup the framebuffer position
  ldr r13, =0x10120000 @ clcd reg base pos
  mov r0, #0x01000000 @ framebuffer pos
  str r0, [r13, #0x10]

  @ Load SYS_CLCD register & turn on
  ldr r13, =0x10000050
  mov r4, #0x3C
  str r4, [r13]

  @ Sleep for a bit before using clcd...
  mov r0, #0x2000
  bl sleep
  @ Power on the CLCD
  ldr r13, =0x10120000 @ clcd reg base pos
  ldr r4, [r13, #0x18]
  orr r4, #1
  str r4, [r13, #0x18]
  @ We need to sleep for a bit again whilst the CLCD stabilises
  mov r0, #0x2000
  bl sleep
  @ Now power on
  orr r4, #0x400
  str r4, [r13, #0x18]

  ldr r13, =0x10120000 
  ldr r0, =0x1313a4c4;
  str r0, [r13]
  ldr r0, =0x0505f657;
  str r0, [r13, #0x04]
  ldr r0, =0x071f1800;
  str r0, [r13, #0x08]
  ldr r0, [r13, #0x18]
  ldr r1, =0x82b; /* control bits */
  orr r0, r1
  str r0, [r13, #0x18]

mov r0, #0x01000000 @ framebuffer pos
ldr r1, =0x00ffffff
ldr r3, =3000000
ldr r13, =0x10120000 @ clcd reg base pos
draw_loop:

  @ Populate framebuffer
  mov r2, #0

  loop:
  str r2, [r0, r2]
  add r2, #4
  cmp r2, r3

  bne loop

  b draw_loop
