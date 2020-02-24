
__global__ void play(int *in, int *out)
{
	int bid = blockIdx.x;
	int tid = threadIdx.x;
	int bdim = blockDim.x;//number of threads in a block
	int gdim = gridDim.x;//number of blocks in the grid
	int live_cells = 0;//live counter
	//bid * bdim=number of threads in the grid
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
		if (is_live == 0 && live_cells == 2)//if it is OFF and has exactly 2 ON neighbors
		{
			out[bid * bdim + tid] = 1;//now it is on
		}
		else if (is_live == 1)//if it is alive
		{
			out[bid * bdim + tid] = 2;//now it is dying
		}
		else if(is_live == 2)//if it is dying
		{
			out[bid*bdim + tid] = 0;//now it is off
		}
	}
	__syncthreads();
}
