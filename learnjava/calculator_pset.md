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

## Stage 6
Rewrite your calculator so that the user can toggle between the modes in stage 2 and stage 5. That is, the user should be able to choose at the beginning of the program whether they want to enter expressions on a single line or on multiple lines.

Notes:
- This is a long section. It will require multiple steps.
- You must use this template class, 
- You must minimize code duplication. That is, 

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

