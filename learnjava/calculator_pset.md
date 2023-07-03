# Calculator App Requirements

You are to design a calculator application that can perform a variety of operations. At each stage, your goal is to make the most user friendly calculator possible, while still meeting the requirements for that stage.

**Make sure to save your code for each stage in a separate file. They might be useful in later stages**

## Stage 1
Design a calculator that can perform the following operations:
- Addition (+)
- Subtraction (-)
- Multiplication (*)
- Division (/)

The calculator should be able to take in exactly two numbers and an operator, and return the result of the operation. The calculator should be able to handle both integers and floating point numbers. If the number is an exact integer, it should be displayed as an integer. Otherwise, it should be displayed as a floating point number.

Notes:
- Floating point precision errors are not a concern at this stage.
- The calculator should be able to handle both positive and negative numbers.
- The calculator should be able to handle division by zero. In this case, the calculator should display an error message.
- The calculator should be able to handle invalid operators. In this case, the calculator should display an error message.
- The calculator should be able to handle invalid numbers. In this case, the calculator should display an error message.

Example 1:
```
Enter first number: 5
Enter second number: 3
Enter operator: +
5 + 3 = 8
```

Example 2:
```
Enter first number: 5.0
Enter second number: 3.0
Enter operator: +
5.0 + 3.0 = 8
```

Example 3:
```
Enter first number: 5.5
Enter second number: 3.5
Enter operator: *
5.5 * 3.5 = 19.25
```

Example 4:
```
Enter first number: 5
Enter second number: 0
Enter operator: /
Cannot divide by zero
```

Example 5:
```
Enter first number: 5
Enter second number: 3
Enter operator: &
Invalid operator
```

Example 6:
```
Enter first number: 5
Enter second number: 3.1
Enter operator: +
5 + 3.1 = 8.1
```

Example 7:
```
Enter first number: 5
Enter second number: 3
Enter operator: /
5 / 3 = 1.6666666666666667
```

Example 8:
```
Enter first number: 6
Enter second number: 3
Enter operator: /
6 / 3 = 2
```

## Stage 2
Add the following operations to your calculator:
- Exponentiation (^)
- Modulo (%)

All rules from stage 1 apply. In addition, the calculator should be able to handle negative exponents and negative modulo values, as well as modulo values of zero. In these cases, the calculator should display an error message.

Display the result of any operation that results in an exact integer as an integer. Otherwise, display the result as a floating point number.

Notes:
- Floating point precision errors are not a concern at this stage.
- The ^ operator in Java is NOT the exponentiation operator. Instead, it is the bitwise XOR operator. You'll need to figure out what to use instead.

Example 1:
```
Enter first number: 5
Enter second number: 3
Enter operator: ^
5 ^ 3 = 125
```

Example 2:
```
Enter first number: 5
Enter second number: -3
Enter operator: ^
5 ^ -3 = 0.008
```

Example 3:
```
Enter first number: 5
Enter second number: 3
Enter operator: %
5 % 3 = 2
```

Example 4:
```
Enter first number: 5
Enter second number: 0
Enter operator: %
Cannot modulo by zero
```

Example 5:
```
Enter first number: 5
Enter second number: -3
Enter operator: %
5 % -3 = -1
```

## Stage 3
Reformat your calculator such that the user only needs to press "enter" once. That is, your calculator should take handle all inputs on a single line.

As before, all error messages, floating point precision errors, and integer vs. floating point number display rules from stage 1 and 2 apply.

Notes:
- The calculator should be able to handle both positive and negative numbers.
- White spaces are allowed, but not required, between the numbers and the operator. There may or may not be white spaces between the numbers, operators, and outside of the expression.


Example 1:
```
Enter expression: 5 + 3
5 + 3 = 8
```

Example 2:
```
Enter expression: 5.0 + 3.0
5.0 + 3.0 = 8
```

Example 3:
```
Enter expression: 5.5 * 3.5
5.5 * 3.5 = 19.25
```

Example 4:
```
Enter expression: 5/3
5 / 3 = 1.6666666666666667
```

Example 5:
```
Enter expression: 5 /0
Cannot divide by zero
```

Example 6:
```
Enter expression: 5 & 3
Invalid operator
```

Example 7:
```
Enter expression:                         5+3.1
5 + 3.1 = 8.1
```

Example 8:
```
Enter expression: 5^3
5 ^ 3 = 125
```

Example 9:
```
Enter expression: 5^-3
5 ^ -3 = 0.008
```

Example 10:
```
Enter expression: 5%3
5 % 3 = 2
```

Example 11:
```
Enter expression: 5%0
Cannot modulo by zero
```

## Stage 4
Make the calculator so that it does not require the user to run the program again for each expression. Instead, the calculator should continue to run until the user types "exit".

Example 1:
```
Enter expression: 5 + 3
5 + 3 = 8
Enter expression: 5.0 + 3.0
5.0 + 3.0 = 8
Enter expression: 5.5 * 3.5
5.5 * 3.5 = 19.25
Enter expression: 5/3
5 / 3 = 1.6666666666666667
Enter expression: 5 /0
Cannot divide by zero
Enter expression: 5 & 3
Invalid operator
Enter expression:                         5+3.1
5 + 3.1 = 8.1
Enter expression: 5^3
5 ^ 3 = 125
Enter expression: 5^-3
5 ^ -3 = 0.008
Enter expression: 5%3
5 % 3 = 2
Enter expression: exit
Bye!
```

## Stage 5
Package the logic in your calculator into a function called ```public static String calculate(String expression)```. This function should take a single string as input and return a string as output. The input string will be any single-line expression mentioned in previous stages (even invalid ones). The output string should be the result of the expression, or an error message if the expression is invalid.

Notes:
- You may place this method in the same class as your main method for now.
- The inputs and outputs for this method will be the same as the inputs for your main method in previous stages.
- This time, your code will be judged by an automatic grader. Make sure that your method is named exactly as specified, and that it takes and returns exactly what is specified. Otherwise, the grader will not be able to run your code.

Example 1:
```
Input into calculate(): "5 + 3"
Output from calculate(): "5 + 3 = 8"
```

Example 2:
```
Input into calculate(): "5.0 + 3.0"
Output from calculate(): "5.0 + 3.0 = 8"
```

Example 3:
```
Input into calculate(): "5.5 * 3.5"
Output from calculate(): "5.5 * 3.5 = 19.25"
```

## Stage 6
Here is a template class you must use for this stage:
```java
class Calculator {

    private double lastAnswer; // This variable should be used to store the result of the last valid  calculation.
    private double timesRun; // This variable should be used to store the number of times the calculator has run.

    class Calculator() {
        
    }

    public void runNextStep() {
        // This method should read the next line of input from the user, and then call the calculate() method below.
        // If the user types "exit", then this method should call the exit() method below.
    }
    public String calculate(String expression) {
        // This method should be nearly the same as the calculate() method from stage 5.
    }

    public void exit() {
        // This method should print "Bye! You ran the calculator X times", where X is the number of times the calculator has run.
    }

    public double handleOperator(double first, double second, char operator) {
        // returns the result of the expression [first] [operator] [second]
    }
}
```

Rewrite your calculator so that it uses the template class above. The calculator should continue to run until the user types "exit".

In your main function, you should only have the following code:
```java
Calculator calculator = new Calculator();
// run calculator.runNextStep() in a loop until the user types "exit"
calculator.exit();
```

Notes:
- You must use this template class.

The calculator should function exactly like in stage 4, except that it should now use the template class above.



## Stage 7
Rewrite your calculator so that the user can toggle between the modes in stage 2 and stage 6. That is, the user should be able to choose at the beginning of the program whether they want to enter expressions on a single line or on multiple lines.

Notes:
- You must use this template class from stage 6.
- You must minimize code duplication. That is, the code for handling the single line mode and the multiple line mode should be reused as much as possible. You will need to use concepts of inheritance and polymorphism to do this.
- You may place the Calculator class in a separate file if you wish.

Tips:
- You'll have to the learn about inheritance before you learn about arrays
- Make a total of 3 classes: BaseCalculator, SingleLineCalculator, and MultiLineCalculator.
- BaseCalculator should contain all the code that is common between the two modes. SingleLineCalculator and MultiLineCalculator should extend BaseCalculator, and should contain the code that is specific to each mode. Therefore, methods such as `runNextStep()` should be overridden in the child classes, however methods such as `calculate()` or `exit()` should not be overridden.


Example 1:
```
Enter mode (1 - single line, 2 - multiple line): 1
Enter expression: 5 + 3
5 + 3 = 8
Enter expression: 5.0 + 3.0
5.0 + 3.0 = 8
Enter expression: 5.5 * 3.5
5.5 * 3.5 = 19.25
[etc]
Enter expression: exit
Bye!
```

Example 2:
```
Enter mode (1 - single line, 2 - multiple line): 2
Enter first number: 5
Enter second number: 3
Enter operator: +
5 + 3 = 8
Enter first number: 5.0
Enter second number: 3.0
Enter operator: +
5.0 + 3.0 = 8
Enter first number: 5.5
Enter second number: 3.5
Enter operator: *
5.5 * 3.5 = 19.25
[etc]
Enter first number: exit
Bye!
```
## Stage 8
Add a new type of calculator, called VariableCalculator that can handle variables. The calculator should be able to store variables and use them in expressions.

Notes:
- Variables are guaranteed to be a single letter, and are case sensitive. That is, the variable "a" is not the same as the variable "A".
- Variables can only be assigned to numbers (`double `s). That is, the expression "a = b" is invalid, but "a=-5.3928" is valid.
- Variables can be used in expressions. That is, the expression "a + 5" is valid if "a" is a variable that has been assigned a value. If "a" has not been assigned a value, then the expression is invalid, and the calculator should print "Unknown variable".
- The calculator should be able to handle all the operators from previous stages, and should be able to handle all 52 possible variables (a-z and A-Z).
- Variables can be reassigned. If the expression "a = 5" is entered, then the variable "a" should be assigned to 5. If the expression "a = 3" is later entered, then the variable "a" should be reassigned to 3.
- Instead of printing "`Enter expression: `" when asking for input, print "`> `". This is to distinguish between the VariableCalculator and the other calculators.

Tips:
- You might want to first use an ArrayList to store the variables.

Example 1:
```
> a = 5
> b = 3
> a + b
8
> a = 3
> a + b
6
> c=7.3
> a+c
10.3
> a*b
9
> a*5
15
> a^b
27
> c*d
Unknown variable
> exit
```


## Stage 9
Allow your calculator to handle variables of any length. A variable can be any sequence of letters, and is case sensitive. That is, the variable "a" is not the same as the variable "A". There will not be any spaces or numbers in the variable name.

All other rules from stage 8 still apply.

## Stage 10
If your implementation was implemented in `O(n)` time, where `n` is the number of total variables (likely if you used an array or ArrayList), then rewrite your calculator so that it is implemented in `O(log(n))` time.

Bonus: Use some other data structure to implement your variable finding algorithm in `O(1)` time.

## Stage 11
Add support for the following operations that only take one argument:
- `sqrt`: square root
- `log`: logarithm with base 10
- `ln`: logarithm with base e
- `sin`: sine
- `cos`: cosine
- `tan`: tangent
- `asin`: arcsine
- `acos`: arccosine
- `atan`: arctangent

Note that variables can be used as arguments for these operations. However, a variable name cannot be the same as the name of an operation. That is, the variable name "sin" is invalid.

Trigonometric functions should be calculated in radians.

These operations should be inputted as follows:
- `sqrt(4)`: square root of 4
- `log(100)`: logarithm of 100 with base 10
- `ln(100)`: logarithm of 100 with base e

These operations should be implemented in all three calculators (SingleLineCalculator, MultiLineCalculator, and VariableCalculator).

Example 1:
```
> a = 5
> b = 3
> a + b
8
> a = 3
> a + b
6
> sqrt(4)
2
> sqrt(a)
1.7320508075688772
> tan(1)
1.5574077246549023
> tan(a)
-0.1425465430742778
> exit
```

## Stage 12
In VariableCalculator and MultiLineCalculator, make your calculator to be able to handle an unlimited number of variables and expressions. That is, the calculator should be able to handle expressions such as:
```
a = 5
3+8*(5+2)-sqrt(a+(2+3)^2)
```

This stage is very hard and will require you to use recursion. You also might need to use the `StringTokenizer` class to split the expression into tokens.

