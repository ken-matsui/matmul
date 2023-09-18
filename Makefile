# Compiler settings
CC = clang
CFLAGS = -Wall -Wpedantic -std=gnu99 -fopenmp
RUN_CFLAGS = -O1 -g -fsanitize=address
BENCH_CFLAGS = -O3
LDFLAGS = -L. -lmatmul

# Archiver settings
AR = ar
ARFLAGS = rcs

# Source files
SRCS = Bench.c Matmul.c

# Header files
HEADERS = $(SRCS:.c=.h)

# Object files
OBJS = $(SRCS:.c=.o)

all: naive_bench blis_autotune gemm_autotune

naive_bench: naive_bench.o libmatmul.a $(HEADERS)
	$(CC) $(CFLAGS) $(BENCH_CFLAGS) -o $@ naive_bench.o libmatmul.a $(LDFLAGS)

blis_autotune: blis_autotune.o libmatmul.a $(HEADERS)
	$(CC) $(CFLAGS) $(BENCH_CFLAGS) -o $@ blis_autotune.o libmatmul.a $(LDFLAGS)

gemm_autotune: gemm_autotune.o libmatmul.a $(HEADERS)
	$(CC) $(CFLAGS) $(BENCH_CFLAGS) -o $@ gemm_autotune.o libmatmul.a $(LDFLAGS)

libmatmul.a: $(OBJS) $(HEADERS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $(BENCH_CFLAGS) -c $< -o $@

clean:
	rm -f *.o naive_bench blis_autotune gemm_autotune libmatmul.a
