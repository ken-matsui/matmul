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

#define nc 12
#define kc 128
#define mc 16

void Blis(uint8_t *A, uint8_t *B, uint8_t *restrict C) {
  for (int j = 0; j < N; j += nc) {
    for (int p = 0; p < K; p += kc) {
      for (int i = 0; i < M; i += mc) {
        // Pack into A
        uint8_t *restrict A_block =
            (uint8_t *)malloc(mc * kc * sizeof(uint8_t));
        for (int ii = i; ii < i + mc; ++ii) {
          for (int pp = p; pp < p + kc; ++pp) {
            A_block[(ii - i) * kc + (pp - p)] = A[pp * N + ii];
          }
        }

        // Pack into B
        uint8_t *restrict B_block =
            (uint8_t *)malloc(kc * nc * sizeof(uint8_t));
        for (int pp = p; pp < p + kc; ++pp) {
          for (int jj = j; jj < j + nc; ++jj) {
            B_block[(pp - p) * nc + (jj - j)] = B[pp * N + jj];
          }
        }

        // Macrokernel
        for (int jj = 0; jj < nc; ++jj) {
          for (int ii = 0; ii < mc; ++ii) {
            // Microkernel
            for (int pp = 0; pp < kc; ++pp) {
              C[(i + ii) * N + (j + jj)] +=
                  A_block[ii * kc + pp] * B_block[pp * nc + jj];
            }
          }
        }

        free(A_block);
        free(B_block);
      }
    }
  }
}

void Gemm(uint8_t *A, uint8_t *B, uint8_t *restrict C) {
  for (int j = 0; j < N; j += nc) {
    for (int p = 0; p < K; p += kc) {
      // Pack into B
      uint8_t *restrict B_block = (uint8_t *)malloc(kc * nc * sizeof(uint8_t));
      for (int pp = p; pp < p + kc; ++pp) {
        for (int jj = j; jj < j + nc; ++jj) {
          B_block[(pp - p) * nc + (jj - j)] = B[pp * N + jj];
        }
      }

      for (int i = 0; i < M; i += mc) {
        // Pack into A
        uint8_t *restrict A_block =
            (uint8_t *)malloc(mc * kc * sizeof(uint8_t));
        for (int ii = i; ii < i + mc; ++ii) {
          for (int pp = p; pp < p + kc; ++pp) {
            A_block[(ii - i) * kc + (pp - p)] = A[pp * N + ii];
          }
        }

        // Macrokernel
        for (int jj = 0; jj < nc; ++jj) {
          for (int ii = 0; ii < mc; ++ii) {
            // Microkernel
            for (int pp = 0; pp < kc; ++pp) {
              C[(i + ii) * N + (j + jj)] +=
                  A_block[ii * kc + pp] * B_block[pp * nc + jj];
            }
          }
        }

        free(A_block);
      }
      free(B_block);
    }
  }
}
