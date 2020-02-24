
__global__ void play(int *in, int *out)
{
	int bid = blockIdx.x;
	int tid = threadIdx.x;
	int bdim = blockDim.x;//o arithmos twn thread se ena block
	int gdim = gridDim.x;//o arithmos twn block mesa sto grid
	int live_cells = 0;//metritis live 
	//bid * bdim=arithmos twn threads sto grid
	if (bid * bdim + tid < bdim * gdim)
	{
		// Check to see if the index is correct
		if (bid != 0 && tid != 0 && in[(bid - 1) * bdim + (tid - 1)])
				live_cells++; //Top left
		if (bid != 0 && in[(bid - 1) * bdim + tid])
				live_cells++; //Top	
		if (bid != 0 && tid != bdim - 1 && in[(bid - 1) * bdim + (tid + 1)])
				live_cells++; //Top right
		if (tid != 0 && in[(bid) * bdim + (tid - 1)])
				live_cells++; //left
		//Skipping itself
		if (tid != bdim - 1 && in[(bid) * bdim + (tid + 1)])
				live_cells++; //Right
		if (bid != gdim - 1 && tid != 0 && in[(bid + 1) * bdim + (tid - 1)])
				live_cells++; //Bottom left
		if (bid != gdim - 1 && in[(bid + 1) * bdim + tid])
				live_cells++; //Bottom
		if (bid != gdim - 1 && tid != bdim - 1 && in[(bid + 1) * bdim + (tid + 1)])
				live_cells++; //Bottom right

		int is_live = in[bid * bdim + tid];
		out[bid * bdim + tid] = is_live;
		if (is_live == 0 && live_cells == 2)//an einai off kai exei 2 akrivos on geitones
		{
			out[bid * bdim + tid] = 1;//kanto on
		}
		else if (is_live == 1)//an einai alive 
		{
			out[bid * bdim + tid] = 2;//kanto dying
		}
		else if(is_live == 2)//an einai dying
		{
			out[bid*bdim + tid] = 0;//kanto off
		}
	}
	__syncthreads();
}
