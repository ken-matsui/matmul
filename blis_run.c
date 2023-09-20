#include <stdint.h>  // for uint8_t
#include <stdio.h>   // for printf, fprintf, FILE
#include <stdlib.h>  // for free, malloc, posix_memalign

#include "./Blis.h"

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

  Blis_16_32_128(A, B, C);

  // Write the result to blis.txt
  FILE *fp = fopen("blis.txt", "w");
  for (int i = 0; i < M; ++i) {
    for (int j = 0; j < N; ++j) {
      fprintf(fp, "%d ", C[i * N + j]);
    }
    fprintf(fp, "\n");
  }
  fclose(fp);

  free(A);
  free(B);
  free(C);

  return 0;
}
