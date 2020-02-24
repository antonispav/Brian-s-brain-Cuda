
__global__ void play_with_shared_memory(int *in, int *out, int size)
{
	int bid = blockIdx.x;
	int tid = threadIdx.x;
	int bdim = blockDim.x;
	int max = size * size;//to megethos tou pinaka
	int i = bid * bdim + tid;//block i
	int mod = i % size;

	extern __shared__ int local_board[];//pinakas pou vriskete sthn sharedmem kai to megethos tou dinete sthn ekinisi tou programm

	int live_cells = 0;//metritis live 

	local_board[tid + size] = in[i];

	// Grab neighbors from next block if possible
	if (i % bdim >= bdim - size && i + size < max)
	{
		local_board[tid + 2 * size] = in[i + size];
	}
	// Grab neighbors from previous block if possible
	if (i % bdim < size && i - size >= 0)
	{
		local_board[tid] = in[i - size];
	}
	// Local Id
	int lid = tid + size;
	__syncthreads();

	// Check to see if the index is correct
	if (mod != 0 && i + size < max && local_board[lid + size - 1])// Top left
	{
		live_cells++;
	}
	if (i + size < max && local_board[lid + size])// Top
	{
		live_cells++;
	}
	if (mod != size - 1 && i + size < max && local_board[lid + size + 1])// Top right
	{
		live_cells++;	
	}
	if (mod != 0 && local_board[lid - 1])// Left
	{
		live_cells++;	
	}
	if (mod != size - 1 && local_board[lid + 1])// Right
	{
		live_cells++;	
	}
	if (i - size>= 0 && mod != 0 && local_board[lid - size - 1])// Bottom left
	{
		live_cells++;	
	}
	if (i - size >= 0 && local_board[lid - size])// Bottom
	{
		live_cells++;	
	}
	if (i - size >= 0 && mod != size - 1 && local_board[lid - size + 1])// Bottom right
	{
		live_cells++;	
	}

	int is_live = local_board[lid];
	int result = is_live;
	if (is_live == 1) // an einai alive
	{
		result = 2;//kanto dying
	}
	else if (is_live == 0 && live_cells == 2)//an einai off kai exei 2 akrivos on geitones
	{
		result = 1;	//kanto on
	}
	else if (is_live == 2)//an einai dying
	{
		result = 0;//kanto off
	}
	out[i] = result;

	__syncthreads();
}
