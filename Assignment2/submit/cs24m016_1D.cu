#include <chrono>
#include <fstream>
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cuda_runtime.h>

using namespace std;

using std::cin;
using std::cout;

typedef long long ll;

__global__ void dkernel(long int *matrix, long int *filter, long int *result, int h, int w, int c, int r, int s, int k)
{
    // Calculate unique thread index in 1D grid
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int total_threads = gridDim.x * blockDim.x;

    // Load filter into shared memory in chunks (reduces shared memory usage)
    extern __shared__ long int mini_filter[];

    for (int i = threadIdx.x; i < c * r * s * k; i += blockDim.x)
    {
        mini_filter[i] = filter[i];
    }

    __syncthreads();

    // Each thread handles one output pixel
    while (tid < h * w * k)
    {
        int col = tid % w;
        int row = (tid / w) % h;
        int f = tid / (h * w); // Filter index

        ll sum = 0; // Use long long to prevent overflow

        for (int ch = 0; ch < c; ch++)
        {
            for (int fi = 0; fi < r; fi++)
            {
                for (int fj = 0; fj < s; fj++)
                {
                    int a = row + fi - (r / 2);
                    int b = col + fj - (s / 2);

                    if (a >= 0 && a < h && b >= 0 && b < w)
                    {
                        int mat_index = (ch * h + a) * w + b;
                        int filter_index = ((f * c + ch) * r + fi) * s + fj;
                        sum += (ll)matrix[mat_index] * (ll)mini_filter[filter_index]; // Prevent overflow
                    }
                }
            }
        }
        result[tid] = (long int)sum;

        tid += total_threads; // Ensure all elements are covered
    }
}

int main(int argc, char **argv)
{
    int h, w, c;

    cin >> h >> w >> c;
    long int *h_mat = new long int[h * w * c];
    for (long int i = 0; i < h * w * c; i++)
    {
        cin >> h_mat[i];
    }

    int cf, r, s, k;
    cin >> cf >> r >> s >> k;

    long int *h_filter = new long int[r * s * c * k];
    for (long int i = 0; i < r * s * c * k; i++)
    {
        cin >> h_filter[i];
    }
    long int *h_ans = new long int[h * w * k];

    /**
     *
     * DO NOT CHANGE ANYTHING ABOVE THIS LINE
     *
     **/

    auto start = std::chrono::high_resolution_clock::now(); // keep it just before the kernel launch

    /****************************************************Start Here***********************************************************/

    long int *d_mat, *d_filter, *d_ans;
    int BLOCK_SIZE = 256; // Optimal for memory coalescing
    int TOTAL_THREADS = h * w * k;
    int GRID_SIZE = (TOTAL_THREADS + BLOCK_SIZE - 1) / BLOCK_SIZE; // Ensuring full coverage

    cudaMalloc(&d_ans, h * w * k * sizeof(long int));
    cudaMalloc(&d_filter, r * s * c * k * sizeof(long int));
    cudaMalloc(&d_mat, h * w * c * sizeof(long int));

    cudaMemcpy(d_mat, h_mat, h * w * c * sizeof(long int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_filter, h_filter, r * s * c * k * sizeof(long int), cudaMemcpyHostToDevice);

    int sharedMemSize = c * r * s * k * sizeof(long int);

    dkernel<<<GRID_SIZE, BLOCK_SIZE, sharedMemSize>>>(d_mat, d_filter, d_ans, h, w, c, r, s, k);

    cudaMemcpy(h_ans, d_ans, h * w * k * sizeof(long int), cudaMemcpyDeviceToHost);

    cudaFree(d_mat);
    cudaFree(d_filter);
    cudaFree(d_ans);

    /*$$$$$$$$$$$$$$$$$$$$$$$$Make sure your final output from the device is stored in h_ans.$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
    auto end = std::chrono::high_resolution_clock::now(); // keep it just after the kernel launch
    std::chrono::duration<double> elapsed1 = end - start;

    /**
     *
     * DO NOT CHANGE ANYTHING BELOW THIS LINE
     *
     */

    cudaDeviceSynchronize();
    std::ofstream file("cuda.out");
    if (file.is_open())
    {
        for (long int i = 0; i < h * k; i++)
        {
            for (long int j = 0; j < w; j++)
            {
                file << h_ans[i * w + j] << " ";
            }
            file << "\n";
        }
        file.close();
    }
    else
    {
        std::cout << "Unable to open file";
    }

    std::ofstream file2("cuda_timing.out");
    if (file2.is_open())
    {
        file2 << elapsed1.count() << "\n";
        file2.close();
    }
    else
    {
        std::cout << "Unable to open file";
    }

    return 0;
}

