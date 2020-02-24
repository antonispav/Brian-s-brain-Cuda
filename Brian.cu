#include <stdio.h>
#include <sys/time.h>
#include <stdlib.h>
#include <unistd.h>
#include "Brian.v1.h"
#include "Brian.v0.h"
//On=1,Off=0,Dying=2
int SIZE, ITERATIONS, ANIMATE, BLOCKS, THREADS, SEED, UNOPTIMIZED, PRINT, live_cells, dead_cells, dying_cells;
void print_board(int board[], int size, int iteration)
{
	if (iteration != -1)
	{
		printf("Iteration %d\n", iteration);
	}
	for (int i = 0;i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			if (board[i * size + j] == 1)//if it is alive
			{
				printf("\u25A3 ");
				live_cells++;
			}
			else if(board[i * size +j] == 0)//if it is dead
			{
				printf("\u25A2 ");
				dead_cells++;
			}
			else if(board[i * size +j] == 2)//if it is dying
			{
				printf("\u25A7 ");
				dying_cells++;
			}
		}
		printf("\n");
	}
	printf("Live Cells =%d ,Dead Cells =%d Dying Cells =%d\n\n",live_cells, dead_cells, dying_cells);
	live_cells = 0;
	dead_cells = 0;
	dying_cells = 0;
}

void arg_parse(int argc, char *argv[])
{
	int i = 1;
	char c;
	while(i < argc)
	{
		sscanf(argv[i++], "%c", &c);
		if (c == 's')//matrix size
		{
			sscanf(argv[i++], "%d", &SIZE);
		}
		if (c == 'a')//animation or not
		{
			ANIMATE = 1;
			printf("fu");
		}
		if (c == 'i')//iterations
		{
			sscanf(argv[i++], "%d", &ITERATIONS);
		}
		if (c == 'b')//number of blocks
		{
			sscanf(argv[i++], "%d", &BLOCKS);
		}
		if (c == 't')//number of threads
		{
			sscanf(argv[i++], "%d", &THREADS);
		}
		if (c == 'e')//random seed(?)
		{
			sscanf(argv[i++], "%d", &SEED);
		}
		if (c == 'u')//version using global memory
		{
			UNOPTIMIZED = 1;
		}
		if (c == 'p')//print board
		{
			sscanf(argv[i++], "%d", &PRINT);
		}
	}
}

int run()
{
	// run arguments
	int animate = ANIMATE != -1 ? ANIMATE : false; // variable for animation--default False
	int size = SIZE ? SIZE : 64;//matrix size--default 64
	int iterations = ITERATIONS ? ITERATIONS : 6;//generations--default 6
	int no_blocks = BLOCKS ? BLOCKS : size; //number of blocks--default 64
	int no_threads = THREADS ? THREADS : size;//number of thread--default 64
	int unoptimized_run = UNOPTIMIZED ? UNOPTIMIZED : 0;//variable for version--default optimized
	int print = PRINT != -1 ? PRINT : true;

	// Initialize random seed
	srand(SEED != -1 ? SEED : time(NULL));

	// host(cpu) memory
	int *input = (int*)calloc(size * size, sizeof(int));//matrix for production-initialisation
	int *output = (int*)calloc(size * size, sizeof(int));//the matrix we print
	int *devin, *devout, *devtemp;//matrix of gpu

	// device(gpu) memory
	cudaMalloc((void**)&devin, size * size * sizeof(int));//matrix for production-initialisation
	cudaMalloc((void**)&devout, size * size * sizeof(int));//the matrix we print
	cudaMalloc((void**)&devtemp, size * size * sizeof(int));//matrix of next generation

	// production and initialisation of the universe
	for (int i = 0;i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			input[i*size + j] = rand() % 3;// a number from 0,2
		}
	}

	if (print)
		print_board(input, size, 0);

	// initial matrix migration from cpu to gpu
	cudaMemcpy(devin, input, size * size * sizeof(int), cudaMemcpyHostToDevice);

	//the matrix we print
	cudaMemcpy(devout, output, size * size * sizeof(int), cudaMemcpyHostToDevice);

	//used when the size of shared memory is unknown during the compile
	//dynamic memory allocation in shared memory
	//it is used only from version 2
	//containts threads data of a block
	int shared_board_size = (no_threads + 2 * size) * sizeof(int);

	// timer start
	struct timeval  tv1, tv2;
	gettimeofday(&tv1, NULL);

	// choose version
	// 1st version with global memmory
	if (unoptimized_run)
	{

		for (int i = 0;i<iterations;i++)
		{
			if (i == 0)
			{
				//start calculations with first production-initialisation matrix
				play<<<no_blocks,no_threads>>>(devin, devout);
			}
			else
			{
				//continue calculations with next generation matrix
				play<<<no_blocks,no_threads>>>(devtemp, devout);
			}
			//migration of next generation matrix to output matrix of gpu(inside og gpu)
			cudaMemcpy(devtemp, devout, size * size * sizeof(int), cudaMemcpyDeviceToDevice);

			//migration of output matrix from gpu to cpu
			cudaMemcpy(output, devout, size * size * sizeof(int), cudaMemcpyDeviceToHost);

			//print results
			if (animate == true)
			{
				system("clear");
				print_board(output, size, i);
				usleep(100000);
			}
		}
		printf("Unoptimized run\n");
	}
	//2nd version with shared memmory,uses a 3rd matrix for calculations
	else
	{
		for (int i = 0;i<iterations;i++)
		{
			if (i == 0)
			{
				//start calculations with first production-initialisation matrix
				play_with_shared_memory<<<no_blocks,no_threads,shared_board_size>>>(devin, devout, size);
			}
			else
			{
				//continue calculations with next generation matrix
				play_with_shared_memory<<<no_blocks,no_threads,shared_board_size>>>(devtemp, devout, size);
			}
			//migration of next generation matrix to output matrix of gpu(inside og gpu)
			cudaMemcpy(devtemp, devout, size * size * sizeof(int), cudaMemcpyDeviceToDevice);
			//migration of output matrix from gpu to cpu
			cudaMemcpy(output, devout, size * size * sizeof(int), cudaMemcpyDeviceToHost);

			//print results
			if (animate == true)
			{
				system("clear");
				print_board(output, size, i);
				usleep(100000);
			}
		}
	}

	// migration of result from gpu to cpu
	cudaMemcpy(output, devout, size * size * sizeof(int), cudaMemcpyDeviceToHost);

	if (print)
		print_board(output, size, iterations);

	// calculate the run time
	gettimeofday(&tv2, NULL);
	printf ("Total time in kernel = %f seconds\n",(double) (tv2.tv_usec - tv1.tv_usec) / 1000000 + (double) (tv2.tv_sec - tv1.tv_sec));



	// Free device memory
	cudaFree(devin);
	cudaFree(devout);
	cudaFree(devtemp);


    return 0;
}

int main(int argc, char* argv[])
{
	SIZE = 0, ITERATIONS = 0, ANIMATE = -1, BLOCKS = 0, THREADS = 0, UNOPTIMIZED = 0, SEED = -1, PRINT = -1;
	arg_parse(argc, argv);
	run();
	return 0;
}
