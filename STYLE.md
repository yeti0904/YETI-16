# YETI-16 source code style guide

## Lines
Lines must be at most a few characters longer than 80 characters
(counting 4 character width tabs)

If a line is too long with paranthesis, split like this:
```
... (
	...
)
```

## Function calls
This is how a function call must be formatted:
```
myfunc(arg1, arg2);
```
- no space between the name and the (
- space after commas

## Import structure
Order of imports:
1. standard libraries
2. 3rd party libraries
3. imports from this project

Imports must be ordered based on the length of the module name

## Pointer declarations
```
int* b;
```
The pointer symbol must be on the left side

## Statements
```
if (...) {
	foo();
}
else {
	bar();
}

if (...) foo();
```
- } must be on a line on its own
- { must be on the line with the statement
- statements without {} can only be used for `if` statements where the
  operation fits within the 80 column limits

## Naming
- camelCase for variables
- PascalCase for functions
- PascalCase for classes/structs/enums/aliases etc
- camelCase for module names

## Function definitions
```
void myfunc() {
	
}
```

## Comments
- use `//` for single line comments

## Operators
When there are multiple operators in a statement, always surround expressions
with parantheses, unless they are the last to be executed

Example:
```
int a = (b * 5) + (c * 90);
```
