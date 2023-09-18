#include <stdint.h>  // for uint8_t
#include <stdio.h>   // for printf, fprintf, FILE
#include <stdlib.h>  // for free, malloc, posix_memalign

#include "./Matmul.h"

int main(void) {
  uint8_t *restrict A;
  posix_memalign((void **)&A, 128, M * K * sizeof(uint8_t));
  for (int i = 0; i < M * K; ++i) {
    A[i] = i % 5;
  }

  uint8_t *restrict B;
  posix_memalign((void **)&B, 128, K * N * sizeof(uint8_t));
  for (int i = 0; i < K * N; ++i) {
    B[i] = i % 5;
  }

  uint8_t *restrict C;
  posix_memalign((void **)&C, 128, M * N * sizeof(uint8_t));
  for (int i = 0; i < M * N; ++i) {
    C[i] = 0;
  }

  Gemm(A, B, C, 32, 128, 16);

  // Write the result to gemm.txt
  FILE *fp = fopen("gemm.txt", "w");
  for (int i = 0; i < M; ++i) {
    for (int j = 0; j < N; ++j) {
      fprintf(fp, "%d ", C[i * N + j]);
    }
    fprintf(fp, "\n");
  }

  free(A);
  free(B);
  free(C);

  return 0;
}
