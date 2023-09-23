#include <stdint.h>  // for uint8_t
#include <stdio.h>   // for printf, fprintf, FILE
#include <stdlib.h>  // for rand, free, malloc, posix_memalign
#include <time.h>    // for clock_gettime, timespec, CLOCK_MONOTONIC

#include "./Bench.h"
#include "./Block.h"

int main(void) {
  uint8_t *restrict A;
  posix_memalign((void **)&A, 128, M * K * sizeof(uint8_t));
  for (int i = 0; i < M * K; ++i) {
    A[i] = (uint8_t)rand();
  }

  uint8_t *restrict B;
  posix_memalign((void **)&B, 128, K * N * sizeof(uint8_t));
  for (int i = 0; i < K * N; ++i) {
    B[i] = (uint8_t)rand();
  }

  uint8_t *restrict C;
  posix_memalign((void **)&C, 128, M * N * sizeof(uint8_t));
  for (int i = 0; i < M * N; ++i) {
    C[i] = 0;
  }

  // Inlined kernel follows. This is for warm-up.
  Block_32_128_4(A, B, C);

  struct timespec start, end;
#pragma clang loop unroll(disable)
  for (int i = 0; i < 10; ++i) {
    clock_gettime(CLOCK_MONOTONIC, &start);
    Block_32_128_4(A, B, C);
    clock_gettime(CLOCK_MONOTONIC, &end);
    printf("%lds %09ldns\n", TsDiff(start, end).tv_sec,
           TsDiff(start, end).tv_nsec);
  }

  free(A);
  free(B);
  free(C);

  return 0;
}
