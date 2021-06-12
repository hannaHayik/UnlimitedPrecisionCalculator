# UnlimitedPrecisionCalculator
An unlimited precision calculator that can perform basic math operations on very large numbers  
The calculator uses Reversed Polish Notation (RPN) and operates on a stack.  

The operations to be supported by your calculator are:  
‘q’ – quit  
‘+’ – unsigned addition    
pop two operands from operand stack, and push one result, their sum  
‘p’ – pop-and-print  
pop one operand from the operand stack, and print its value to stdout  
‘d’ – duplicate  
push a copy of the top of the operand stack onto the top of the operand stack  
‘^’ - X*2^Y, with X being the top of operand stack and Y the element next to x in the operand stack. If Y>200 this is considered an error  
pop two operands from the operand stack, and push one result  
‘v’ – X*2^(-Y), with X and Y as above. This number may be not an integer.  
pop two operands from the operand stack, and push one result  
‘n’ – number of '1' bits  
pop one operand from the operand stack, and push one result    

This is a run example of the program  
![alt text](https://www.cs.bgu.ac.il/~caspl192/wiki.files/assign2/assignment2Images3.png)  

Put both files in same folder and run : make 
