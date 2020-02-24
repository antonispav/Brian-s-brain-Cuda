# Brian's Brain With Cuda
This application involves the Conway Game of Life in Cuda programming model.

## [Brief Description](https://en.wikipedia.org/wiki/Brian%27s_Brain):
The Conway Game of Life is a cellular automation devised by the British mathematician John Horton Conway in 1970.
The game is a zero-player game, meaning that its evolution is determined by its initial state, requiring no further input.
One interacts with the Game of Life by creating an initial configuration and observing how it evolves.
It is Turing complete and can simulate a universal constructor or any other Turing machine.
Rules

The universe of the Game of Life is an infinite, two-dimensional orthogonal grid of square cells, each of which is in one of two possible states, alive or dead, (or populated and unpopulated, respectively). Every cell interacts with its eight neighbours, which are the cells that are horizontally, vertically, or diagonally adjacent. At each step in time, the following transitions occur:

* Any live cell with fewer than two live neighbours dies, as if by underpopulation.
* Any live cell with two or three live neighbours lives on to the next generation.
* Any live cell with more than three live neighbours dies, as if by overpopulation.
* Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

These rules, which compare the behavior of the automaton to real life, can be condensed into the following:

* Any live cell with two or three neighbors survives.
* Any dead cell with three live neighbors becomes a live cell.
* All other live cells die in the next generation. Similarly, all other dead cells stay dead.

The initial pattern constitutes the seed of the system. The first generation is created by applying the above rules simultaneously to every cell in the seed; births and deaths occur simultaneously, and the discrete moment at which this happens is sometimes called a tick. Each generation is a pure function of the preceding one. The rules continue to be applied repeatedly to create further generations.

## Runing
Compile
```
nvcc -o Brian Brian.cu
```
Running Arguments : ./Brain[s INT][i INT][t INT][b INT][e INT][p 0|1][u][a]
* s : Matrix Size(Width)
* i : Number of generations(Default = 6)
* t : Number of Threads(Default = Width)
* b : Number of Blocks(Default = Width)
* e : Random Seed(Default = Null)
* p : Print Matrix(Default = True)
* u : Run First Version(v0) with Global Memory
* a : Animation(Default = False)

Example
```
 ./Brian s 65 i 6 a
```
