/*** asmMult.s   ***/
/* SOLUTION; used to test C test harness
 * VB 10/14/2023
 */
    
/* Tell the assembler to allow both 16b and 32b extended Thumb instructions */
.syntax unified

#include <xc.h>

/* Tell the assembler that what follows is in data memory    */
.data
.align
 
/* define and initialize global variables that C can access */

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Javier Ayala"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global a_Multiplicand,b_Multiplier,a_Sign,b_Sign,a_Abs,b_Abs,init_Product,final_Product
.type a_Multiplicand,%gnu_unique_object
.type b_Multiplier,%gnu_unique_object
.type rng_Error,%gnu_unique_object
.type a_Sign,%gnu_unique_object
.type b_Sign,%gnu_unique_object
.type prod_Is_Neg,%gnu_unique_object
.type a_Abs,%gnu_unique_object
.type b_Abs,%gnu_unique_object
.type init_Product,%gnu_unique_object
.type final_Product,%gnu_unique_object

/* NOTE! These are only initialized ONCE, right before the program runs.
 * If you want these to be 0 every time asmMult gets called, you must set
 * them to 0 at the start of your code!
 */
a_Multiplicand:  .word     0  
b_Multiplier:    .word     0  
rng_Error:       .word     0 
a_Sign:          .word     0  
b_Sign:          .word     0 
prod_Is_Neg:     .word     0 
a_Abs:           .word     0  
b_Abs:           .word     0 
init_Product:    .word     0
final_Product:   .word     0

 /* Tell the assembler that what follows is in instruction memory    */
.text
.align

.global asmUnpack, asmAbs, asmMult, asmFixSign, asmMain
.type asmUnpack,%function
.type asmAbs,%function
.type asmMult,%function
.type asmFixSign,%function
.type asmMain,%function

/* function: asmUnpack
 *    inputs:   r0: contains the packed value. 
 *                  MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *              r1: address where to store unpacked, 
 *                  sign-extended 32 bit a value
 *              r2: address where to store unpacked, 
 *                  sign-extended 32 bit b value
 *    outputs:  r0: No return value
 *              memory: 
 *                  1) store unpacked A value in location
 *                     specified by r1
 *                  2) store unpacked B value in location
 *                     specified by r2
 */
asmUnpack:   
    
    /*** STUDENTS: Place your asmUnpack code BELOW this line!!! **************/
    
    //this extracts the upper 16 bits by right shifting.
    LSR r3, r0, #16  //moves upper 16 bits to lower half
    LSL r3, r3, #16  //clears out upper bits by shifting left
    ASR r3, r3, #16  //arithmetic shift right to sign extend
    STR r3, [r1]     //stores upper bits into memory location pointed by r1
    
    //this extracts the lower 16 bits and then sign enxtending to 32 bit.
    LSL r4, r0, #16  //shifts lower 16 bits into upper half.
    ASR r4, r4, #16  //the program will sign extend to 32 bit.
    STR r4, [r2]     // this stores the 16 bits that were shifted into upper half
                     // into memory location pointed by r2.
    
    BX LR  // returns from function
    /*** STUDENTS: Place your asmUnpack code ABOVE this line!!! **************/


    /***************  END ---- asmUnpack  ************/

 
/* function: asmAbs
 *    inputs:   r0: contains signed value
 *              r1: address where to store absolute value
 *              r2: address where to store sign bit 0 = "+", 1 = "-")
 *    outputs:  r0: Absolute value of r0 input. Same value as stored to location given in r1
 *              memory: store absolute value in location given by r1
 *                      store sign bit in location given by r2
 */    
asmAbs:  

    /*** STUDENTS: Place your asmAbs code BELOW this line!!! **************/
    MOV r3, r0  //copying input to r3 to preserve original sign
    
    CMP r0,#0  
    BGE store_values // compares r0 to see if it is >= 0, if so then skips negation
    
    RSBS r0, r0, #0  //if the value comes out to be negative, we get its
                     // absolute value by reversing the sign
    
store_values:
    STR r0, [r1]  //stores the absolute value
    
   
    MOV r4, #0    //assumes that the sign is positive
    CMP r3, #0
    BGE store_sign
    MOV r4, #1    // updates to 1 if the original sign was negative
    
store_sign:
    STR r4, [r2]  //this stores the sign bit
    BX LR  // returns from function

    /*** STUDENTS: Place your asmAbs code ABOVE this line!!! **************/


    /***************  END ---- asmAbs  ************/

 
/* function: asmMult
 *    inputs:   r0: contains abs value of multiplicand (a)
 *              r1: contains abs value of multiplier (b)
 *    outputs:  r0: initial product: r0 * r1
 */ 
asmMult:   

    /*** STUDENTS: Place your asmMult code BELOW this line!!! **************/
    MOV r2, #0 
    MOV r3, r1  //copies multiplier to r3 so we can shift it
    MOV r4, r0  //copies multiplicand to r4
    
mult_loop:
    TST r3, #1  //tests if the lowest bit is 1
    BEQ skip_add  //if it is 0 then it will skip the add step
    
    ADD r2, r2, r4  //adds multiplicand to result
    
skip_add:
    LSR r3, r3, #1  //this shifts the multiplier right by 1
    LSL r4, r4, #1  //shifts multiplicand left by 1
    CMP r3, #0  
    BNE mult_loop  //loop until all bits are processed
    
    MOV r0, r2  // the result now moves into r0
    BX LR  // returns from function

    /*** STUDENTS: Place your asmMult code ABOVE this line!!! **************/

   
    /***************  END ---- asmMult  ************/


    
/* function: asmFixSign
 *    inputs:   r0: initial product from previous step: 
 *              (abs value of A) * (abs value of B)
 *              r1: sign bit of originally unpacked value
 *                  of A
 *              r2: sign bit of originally unpacked value
 *                  of B
 *    outputs:  r0: final product:
 *                  sign-corrected version of initial product
 */ 
asmFixSign:   
    
    /*** STUDENTS: Place your asmFixSign code BELOW this line!!! **************/
    //we are comparing the sign bits and if they are different, the product should be negative
    EOR r3, r1, r2
    CMP r3, #0
    BEQ done_fix  //if the sign is the same, then it is done
    
    RSBS r0, r0, #0 //if the sign is different, negate the product
done_fix:
    BX LR  //return from function
    
    /*** STUDENTS: Place your asmFixSign code ABOVE this line!!! **************/


    /***************  END ---- asmFixSign  ************/



    
/* function: asmMain
 *    inputs:   r0: contains packed value to be multiplied
 *                  using shift-and-add algorithm
 *           where: MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *    outputs:  r0: final product: sign-corrected product
 *                  of the two unpacked A and B input values
 *    NOTE TO STUDENTS: 
 *           To implement asmMain, follow the steps outlined
 *           in the comments in the body of the function
 *           definition below.
 */  
asmMain:   
    
    /*** STUDENTS: Place your asmMain code BELOW this line!!! **************/
    
    PUSH {LR}  //this stores the original return adress on the stack
    /* Step 1:
     * call asmUnpack. Have it store the output values in a_Multiplicand
     * and b_Multiplier.
     */
    
    //This makes sure that the upper 16 bits go into the multiplicand
    //and the lower 16 bits will go into the multiplier so that we separate 
    // the two operands for the other functions
    LDR r1, =a_Multiplicand
    LDR r2, =b_Multiplier
    BL asmUnpack

     /* Step 2a:
      * call asmAbs for the multiplicand (a). Have it store the absolute value
      * in a_Abs, and the sign in a_Sign.
      */
     
     //This will give us the absolute value of the multiplicand plus it
     //will determine if it is negative or positive. We use absolute values
     //because when using shift and add, it's going to assume we're using
     //positive numbers. Later we will fix the sign.
    LDR r0, =a_Multiplicand
    LDR r0, [r0]  //loads the actual value into r0
    LDR r1, =a_Abs  //r1 will store the absolute value
    LDR r2, =a_Sign  // r2 will store the sign(0 for positive or 1 for negative)
    BL asmAbs  // calls the asmAbs function

     /* Step 2b:
      * call asmAbs for the multiplier (b). Have it store the absolute value
      * in b_Abs, and the sign in b_Sign.
      */
    
     //This is the same thing as above, which will give us the absolute value of the multiplier plus it
     //will determine if it is negative or positive. We use absolute values
     //because when using shift and add, it's going to assume we're using
     //positive numbers. Later we will fix the sign.
    LDR r0, =b_Multiplier
    LDR r0, [r0]
    LDR r1, =b_Abs
    LDR r2, =b_Sign
    BL asmAbs

    /* Step 3:
     * call asmMult. Pass a_Abs as the multiplicand, 
     * and b_Abs as the multiplier.
     * asmMult returns the initial (positive) product in r0.
     * In this function (asmMain), store the output value  
     * returned asmMult in r0 to mem location init_Product.
     */
    
    //Now this will perform the multiplication which only works with
    //non-negative values, so we are using the absolute values taken in 
    //the previous function
    LDR r3, =a_Abs
    LDR r0, [r3]
    LDR r4, =b_Abs
    LDR r1, [r4]
    BL asmMult
    
    //this will save the product for use in the next step which fixes the sign
    LDR r2, =init_Product
    STR r0, [r2]


    /* Step 4:
     * call asmFixSign. Pass in the initial product, and the
     * sign bits for the original a and b inputs. 
     * asmFixSign returns the final product with the correct
     * sign. Store the value returned in r0 to mem location 
     * final_Product.
     */
    
    //This step will fix the sign since we have the absolute multiplication 
    //product. 
    LDR r1, =a_Sign
    LDR r1, [r1]
    LDR r2, =b_Sign
    LDR r2, [r2]
    BL asmFixSign
    
    LDR r1, =final_Product
    STR r0, [r1]  //stores the final signed product
    
     /* Step 5:
      * END! Return to caller. Make sure of the following:
      * 1) Stack has been correctly managed.
      * 2) the final answer is stored in r0, so that the C call 
      *    can access it.
      */
    POP {LR}  //this will restore the original return adsress 
    BX LR //returns to caller


    
    /*** STUDENTS: Place your asmMain code ABOVE this line!!! **************/


    /***************  END ---- asmMain  ************/

 
    
    
.end   /* the assembler will ignore anything after this line. */
