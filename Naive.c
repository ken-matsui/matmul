#include "Naive.h"

void Naive(uint8_t *restrict A, uint8_t *restrict B, uint8_t *restrict C) {
  for (int m = 0; m < M; ++m) {
    for (int n = 0; n < N; ++n) {
      for (int k = 0; k < K; ++k) {
        C[m * N + n] += A[m * K + k] * B[k * N + n];
      }
    }
  }
}
