# Board problem

From: https://stackoverflow.com/questions/78987960/suggestion-on-which-constraint-to-adds-to-optimize-minizincs-model

## Problem definition:
       
"I have grid of dimensions H and W of boolean variables. The only constraint is that if
a variable is false then at least one of the adjacent variables (top, right, left, bottom,
diagonals don't count) must be true. The goal is to minimize the number of true values in the grid."

## Models

See: https://yetanothermathprogrammingconsultant.blogspot.com/2025/02/small-mip-proving-optimality-is.html


## Results

[Example output of 32x32 board](board.pdf)
