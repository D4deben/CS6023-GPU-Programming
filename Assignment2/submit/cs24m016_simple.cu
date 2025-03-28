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
       // sample kernel you can use your own kernel
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
//     printf("hey welcome to my kernel, %d %d\n",row,col);
    if(row<h*k && col<w){
    int f= row/h;
    int mat_row=row%h;
    int sum=0;
    
    for (int ch = 0; ch < c; ch++) {
            for (int fi = 0; fi < r; fi++) {
                for (int fj = 0; fj < s; fj++) {
                    int a = mat_row + fi - (r / 2);
                    int b = col + fj - (s / 2);

                    if (a >= 0 && a < h && b >= 0 && b < w) {
                        int mat_index = (ch * h + a) * w + b;
                        int filter_index = ((f * c + ch) * r + fi) * s + fj;
                        sum += matrix[mat_index] * filter[filter_index];
                    }
                }
            }
        }
        result[row * w + col] = sum;
        //if(f==1) printf("%d\n", sum);
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

    /**
        Do device allocations, kernel launches and copying everything here
        and the final answer should be stored back in h_ans, use cudaFree to free up the allocated memory on GPU
    */
    
    long int *d_mat, *d_filter, *d_ans;
    int BLOCK_SIZE= 32;
    cudaMalloc(&d_ans, h * w * k * sizeof(long int));
    cudaMalloc(&d_filter, r * s * c * k * sizeof(long int));
    cudaMalloc(&d_mat, h * w * c * sizeof(long int));
   // cout<<"mem allocated"<<endl;
    cudaMemcpy(d_mat, h_mat, h * w * c * sizeof(long int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_filter, h_filter, r * s * c * k * sizeof(long int), cudaMemcpyHostToDevice);
   // cout<<"coped to gpu"<<endl;

    dim3 blockDim(BLOCK_SIZE, BLOCK_SIZE);
    dim3 gridDim((w + BLOCK_SIZE-1) / BLOCK_SIZE, ((h*k) + BLOCK_SIZE-1) / BLOCK_SIZE);
//	cout<<"calling kernel"<<endl;
    dkernel<<<gridDim, blockDim>>>(d_mat, d_filter, d_ans, h, w, c, r, s, k);
//	cout<<"kernel call done"<<endl;
    cudaMemcpy(h_ans, d_ans, h * w * k * sizeof(long int), cudaMemcpyDeviceToHost);
  //  cout<<"copied to cpu"<<endl;
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
