import sys


headers = """
#include <stdarg.h>  // for va_list, va_start, va_end
#include <stdint.h>  // for uint8_t
#include <stdio.h>   // for vprintf, vfprintf, FILE, fclose, fopen
#include <stdlib.h>  // for rand, free, posix_memalign
#include <time.h>    // for clock_gettime, timespec, CLOCK_MONOTONIC

#include "./Bench.h"
#include "./{name}.h"
"""

tee_function = """
static void tee(const char *format, ...) {{
  va_list args;

  // Print to stdout
  va_start(args, format);
  vprintf(format, args);
  va_end(args);

  // Print to file
  FILE *fp = fopen("{name}_autotune.txt", "a");
  va_start(args, format);
  vfprintf(fp, format, args);
  va_end(args);
  fclose(fp);
}}
"""

call_kernel = """
static struct timespec call_kernel_{mc}_{nc}_{kc}(void) {{
  uint8_t *A;
  posix_memalign((void **)&A, 128, M * K * sizeof(uint8_t));
  for (int i = 0; i < M * K; ++i) {{
    A[i] = (uint8_t)rand();
  }}

  uint8_t *B;
  posix_memalign((void **)&B, 128, K * N * sizeof(uint8_t));
  for (int i = 0; i < K * N; ++i) {{
    B[i] = (uint8_t)rand();
  }}

  uint8_t *restrict C;
  posix_memalign((void **)&C, 128, M * N * sizeof(uint8_t));
  for (int i = 0; i < M * N; ++i) {{
    C[i] = 0;
  }}

  // Inlined kernel follows. This is for warm-up.
  {name}_{mc}_{nc}_{kc}(A, B, C);

  struct timespec start, end;
  struct timespec total_time = {{0, 0}};
  const int num_iterations = 10;
#pragma clang loop unroll(disable)
  for (int i = 0; i < num_iterations; ++i) {{
    clock_gettime(CLOCK_MONOTONIC, &start);
    {name}_{mc}_{nc}_{kc}(A, B, C);
    clock_gettime(CLOCK_MONOTONIC, &end);

    total_time.tv_sec += TsDiff(start, end).tv_sec;
    total_time.tv_nsec += TsDiff(start, end).tv_nsec;
    tee("%d: %lds %ldns\\n", i, TsDiff(start, end).tv_sec,
        TsDiff(start, end).tv_nsec);
  }}
  struct timespec avg_time;
  avg_time.tv_sec = (total_time.tv_sec / num_iterations);
  avg_time.tv_nsec = (total_time.tv_nsec / num_iterations);
  tee("(mc: %d, nc: %d, kc: %d): ave. %lds %ldns\\n", {mc}, {nc}, {kc},
      avg_time.tv_sec, avg_time.tv_nsec);

  free(A);
  free(B);
  free(C);

  return avg_time;
}}
"""

main_prologue = """
struct Param {{
  int mc;
  int nc;
  int kc;
}};

int main(void) {{
  struct timespec min_time = {{1000000000, 0}};
  struct Param min_param = {{0, 0, 0}};
  struct timespec avg_time;

  // Erase the existing content of the file.
  FILE *fp = fopen("{name}_autotune.txt", "w");
  if (fp) {{
    fclose(fp);
  }}
"""

kernel_call = """
  tee("(mc: %d, nc: %d, kc: %d)\\n", {mc}, {nc}, {kc});
  avg_time = call_kernel_{mc}_{nc}_{kc}();
  if (avg_time.tv_sec < min_time.tv_sec ||
      (avg_time.tv_sec == min_time.tv_sec &&
       avg_time.tv_nsec < min_time.tv_nsec)) {{
    min_time = avg_time;
    struct Param new_param = {{{mc}, {nc}, {kc}}};
    min_param = new_param;
  }}
  tee("Current best parameters: (nc: %d, kc: %d, mc: %d): %lds %ldns\\n\\n",
      min_param.nc, min_param.kc, min_param.mc, min_time.tv_sec,
      min_time.tv_nsec);
"""

main_epilogue = """
  tee("Best parameters: (nc: %d, kc: %d, mc: %d): %lds %ldns\\n",
      min_param.nc, min_param.kc, min_param.mc, min_time.tv_sec,
      min_time.tv_nsec);

  return 0;
}
"""


# name: Block or Pack
def generate_code(size, name):
    size = int(size) + 1

    code = "/* Autogenerated file. Do not edit manually. */\n"
    code += headers.format(name=name)
    code += tee_function.format(name=name)
    for mc in range(0, size):
        for nc in range(0, size):
            for kc in range(0, size):
                code += call_kernel.format(
                    name=name, mc=2**mc, nc=2**nc, kc=2**kc
                )
    code += main_prologue.format(name=name)
    for mc in range(0, size):
        for nc in range(0, size):
            for kc in range(0, size):
                code += kernel_call.format(mc=2**mc, nc=2**nc, kc=2**kc)
    code += main_epilogue
    return code


if __name__ == "__main__":
    size, name = sys.argv[1:3]
    print(generate_code(size, name))
