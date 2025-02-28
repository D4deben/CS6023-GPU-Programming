
#include <stdio.h>
#include <stdlib.h>

// Function to perform convolution
void convolve(int Hi, int Wi, int Ci,long int img[][Wi], 
              int Hf, int Wf, int Cf, int f,long int filters[][Wf], 
              long int output[][Wi]) {
    
    for (int filter_idx = 0; filter_idx < f; filter_idx++) { // Each filter
        for (int i = 0; i < Hi; i++) { // Image height
            for (int j = 0; j < Wi; j++) { // Image width for filter application
                long sum = 0;
                
                for (int ch = 0; ch < Ci; ch++) { // Iterate over channels
                    for (int fi = 0; fi < Hf; fi++) { // Filter height
                        for (int fj = 0; fj < Wf; fj++) { // Filter width
                             int a= i+fi - (Hf/2);
                             int b= j+ fj - (Wf/2);
                             
                             if((a>=0&& a<Hi)&&(b>=0 && b<Wi)){
                                sum+= img[(ch*Hi)+a][b]*filters[(Cf*Hf*filter_idx)+(ch*Hf)+fi][fj];
                             // if(i==2&&j==5&&filter_idx==0 ) printf("img is %ld while filtr is %ld and sum is %ld \n", img[(ch*Hi)+a][b],filters[(Cf*Hf*filter_idx)+(ch*Hf)+fi][fj], sum);
                            }
                        }
                    }
                }
                
                output[i+filter_idx*Hi][j] = sum;
            }
        }
    }
}

int main() {
    int Hi, Wi, Ci;
    printf("Enter Image Dimensions (Hi Wi Ci): ");
    scanf("%d %d %d", &Hi, &Wi, &Ci);

    long int img[Hi * Ci][Wi]; // Image Matrix
    printf("Enter Image Matrix (%d x %d):\n", Hi * Ci, Wi);
    for (int i = 0; i < Hi * Ci; i++) {
        for (int j = 0; j < Wi; j++) {
            scanf("%ld", &img[i][j]);
        }
    }

    int Cf, Hf, Wf, f;
    printf("Enter Filter Dimensions (Cf Hf Wf Number_of_Filters): ");
    scanf("%d %d %d %d", &Cf, &Hf, &Wf, &f);

    long int filters[Hf * Cf* f][Wf]; // Filter Matrix
    printf("Enter Filter Matrix (%d x %d):\n", Hf * Cf*f, Wf);
    for (int i = 0; i < Hf * Cf*f; i++) {
        for (int j = 0; j < Wf; j++) {
            scanf("%ld", &filters[i][j]);
        }
    }

    long int output[Hi * f][Wi]; // Output Matrix
    convolve(Hi, Wi, Ci, img, Hf, Wf, Cf, f, filters, output);

    printf("Output Matrix (%d x %d):\n", Hi * f, Wi);
    for (int i = 0; i < Hi * f; i++) {
        for (int j = 0; j < Wi; j++) {
            printf("%ld ", output[i][j]);
        }
        printf("\n");
    }

    return 0;
}
