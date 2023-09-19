import sys


headers = """
#include "{name}.h"

#include <stdint.h>  // for uint8_t
#include <stdlib.h>  // for free, malloc
"""


impl = """
void {name}_{mc}_{nc}_{kc}(uint8_t *A, uint8_t *B, uint8_t *restrict C) {{
  for (int j = 0; j < N; j += {nc}) {{
    for (int p = 0; p < K; p += {kc}) {{
      for (int i = 0; i < M; i += {mc}) {{
        // Pack into A
        uint8_t *restrict A_block =
            (uint8_t *)malloc({mc} * {kc} * sizeof(uint8_t));
        for (int ii = i; ii < i + {mc}; ++ii) {{
          for (int pp = p; pp < p + {kc}; ++pp) {{
            A_block[(ii - i) * {kc} + (pp - p)] = A[pp * N + ii];
          }}
        }}

        // Pack into B
        uint8_t *restrict B_block =
            (uint8_t *)malloc({kc} * {nc} * sizeof(uint8_t));
        for (int pp = p; pp < p + {kc}; ++pp) {{
          for (int jj = j; jj < j + {nc}; ++jj) {{
            B_block[(pp - p) * {nc} + (jj - j)] = B[pp * N + jj];
          }}
        }}

        // Macrokernel
        for (int jj = 0; jj < {nc}; ++jj) {{
          for (int ii = 0; ii < {mc}; ++ii) {{
            // Microkernel
            for (int pp = 0; pp < {kc}; ++pp) {{
              C[(i + ii) * N + (j + jj)] +=
                  A_block[ii * {kc} + pp] * B_block[pp * {nc} + jj];
            }}
          }}
        }}

        free(A_block);
        free(B_block);
      }}
    }}
  }}
}}
"""


# name: Blis or Gemm
def generate_code(size, name):
    size = int(size)

    code = "/* Autogenerated file. Do not edit manually. */\n"
    code += headers.format(name=name)
    for mc in range(0, size + 1):
        for nc in range(0, size + 1):
            for kc in range(0, size + 1):
                code += impl.format(name=name, mc=2**mc, nc=2**nc, kc=2**kc)
    return code


if __name__ == "__main__":
    size, name = sys.argv[1:3]
    print(generate_code(size, name))