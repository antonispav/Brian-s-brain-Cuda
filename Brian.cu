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
			if (board[i * size + j] == 1)//an einai alive
			{
				printf("\u25A3 ");
				live_cells++;
			}
			else if(board[i * size +j] == 0)//an einai dead
			{
				printf("\u25A2 ");
				dead_cells++;
			}
			else if(board[i * size +j] == 2)//an einai dying
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
		if (c == 's')//to megethos tou pinaka
		{
			sscanf(argv[i++], "%d", &SIZE);
		}
		if (c == 'a')//animation h oxi
		{
			ANIMATE = 1;
			printf("fu");
		}
		if (c == 'i')//epanalipseis
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
	// orismata gia to run tou programm
	int animate = ANIMATE != -1 ? ANIMATE : false; // metavliti gia to an tha uparxei h oxi animation
	int size = SIZE ? SIZE : 64;//megethos pinaka--default 64
	int iterations = ITERATIONS ? ITERATIONS : 6;//genies--default 6
	int no_blocks = BLOCKS ? BLOCKS : size; //arithmos twn block--default 64
	int no_threads = THREADS ? THREADS : size;//arithmos twn thread--default 64
	int unoptimized_run = UNOPTIMIZED ? UNOPTIMIZED : 0;//metavliti gia to pia ekdosi epilegthike--default optimized
	int print = PRINT != -1 ? PRINT : true;

	// Initialize random seed
	srand(SEED != -1 ? SEED : time(NULL));

	// desmeush mnhmhs ston host(cpu)
	int *input = (int*)calloc(size * size, sizeof(int));//pinakas gia paragwgh-arxikopoihsh
	int *output = (int*)calloc(size * size, sizeof(int));//o pinakas pou emfanizete
	int *devin, *devout, *devtemp;//pinakes ths gpu

	//desmeush mnhmhs ston device(gpu)
	cudaMalloc((void**)&devin, size * size * sizeof(int));//pinakas gia paragwgh-arxikopoihsh
	cudaMalloc((void**)&devout, size * size * sizeof(int));//o pinakas pou emfanizete
	cudaMalloc((void**)&devtemp, size * size * sizeof(int));//o pinakas epomenhs genias

	// paragwgh kai arxikopoihsh sympantos
	for (int i = 0;i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			input[i*size + j] = rand() % 3;// enas arithmos apo to 0,2
		}
	}

	if (print)
		print_board(input, size, 0);

	// antigrafi tou pinaka arxikopoihshs apo cpu->gpu
	cudaMemcpy(devin, input, size * size * sizeof(int), cudaMemcpyHostToDevice);

	//o pinakas pou emfanizete
	cudaMemcpy(devout, output, size * size * sizeof(int), cudaMemcpyHostToDevice);

	//xrhsimopoieitai otan den einai gnwsto to megethos ths shared memory kata thn metaglwtish tou programmatos
	//desmeuei dynamika mnhmh sthn shared memory
	// xrhsimopoieitai mono apo thn 2h ekdosh
	//periexei ta stoixeia twn threads enos block
	int shared_board_size = (no_threads + 2 * size) * sizeof(int);

	// xekina to xronometro
	struct timeval  tv1, tv2;
	gettimeofday(&tv1, NULL);

	// dialexe ekdosh
	// 1h ekdosi me global memmory
	if (unoptimized_run)
	{

		for (int i = 0;i<iterations;i++)
		{
			if (i == 0)
			{
				//xekina na upologizeis me prwto pinaka paragwghs-arxikopoihshs
				play<<<no_blocks,no_threads>>>(devin, devout);
			}
			else
			{
				//sinexise na upologizeis me ton pinaka epomenhs genias
				play<<<no_blocks,no_threads>>>(devtemp, devout);
			}
			//antigrafh tou pinakas epomenhs genias ston pinaka exwdou ths gpu(eswterika ths gpu)
			cudaMemcpy(devtemp, devout, size * size * sizeof(int), cudaMemcpyDeviceToDevice);

			//antigrafi tou pinaka exwdou apo gpu->cpu
			cudaMemcpy(output, devout, size * size * sizeof(int), cudaMemcpyDeviceToHost);

			//apeikonish apotelesmatwn
			if (animate == true)
			{
				system("clear");
				print_board(output, size, i);
				usleep(100000);
			}
		}
		printf("Unoptimized run\n");
	}
	// 2h ekdosi me shared memmory,xrisimopoiei enan 3o pinaka gia tous upologismous
	else
	{
		for (int i = 0;i<iterations;i++)
		{
			if (i == 0)
			{
				//xekina na upologizeis me prwto pinaka paragwghs-arxikopoihshs
				play_with_shared_memory<<<no_blocks,no_threads,shared_board_size>>>(devin, devout, size);
			}
			else
			{
				//sinexise na upologizeis me ton pinaka epomenhs genias
				play_with_shared_memory<<<no_blocks,no_threads,shared_board_size>>>(devtemp, devout, size);
			}
			//antigrafh tou pinakas epomenhs genias ston pinaka exwdou ths gpu(eswterika ths gpu)
			cudaMemcpy(devtemp, devout, size * size * sizeof(int), cudaMemcpyDeviceToDevice);
			//antigrafi tou pinaka exwdou apo gpu->cpu
			cudaMemcpy(output, devout, size * size * sizeof(int), cudaMemcpyDeviceToHost);

			//apeikonish apotelesmatwn
			if (animate == true)
			{
				system("clear");
				print_board(output, size, i);
				usleep(100000);
			}
		}
	}

	// antigrafi tou apotelesmatos apo gpu->cpu
	cudaMemcpy(output, devout, size * size * sizeof(int), cudaMemcpyDeviceToHost);

	if (print)
		print_board(output, size, iterations);

	// Ypologise ton xrono ektelesis
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
