#include "Matmul.h"

#include <stdlib.h>  // for free, malloc

void Naive(uint8_t *restrict A, uint8_t *restrict B, uint8_t *restrict C) {
  for (int j = 0; j < N; ++j) {
    for (int p = 0; p < K; ++p) {
      for (int i = 0; i < M; ++i) {
        C[i * N + j] += A[p * N + j] * B[p * N + i];
      }
    }
  }
}
