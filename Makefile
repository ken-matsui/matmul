# Compiler settings
CC = clang
CFLAGS = -Wall -Wpedantic -std=gnu99 -fopenmp

# MORE_CFLAGS = -O1 -g -fsanitize=address
MORE_CFLAGS = -O3

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

# Executable files
EXECS = naive_bench naive_run blis_autotune blis_run gemm_autotune gemm_run

all: $(EXECS)

$(EXECS): %: %.o libmatmul.a $(HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< libmatmul.a $(LDFLAGS)

libmatmul.a: $(OBJS) $(HEADERS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

check: naive_run blis_run gemm_run
	./naive_run
	./blis_run
	./gemm_run
	diff -s naive.txt blis.txt
	diff -s naive.txt gemm.txt

clean:
	rm -f *.o *.txt $(EXECS) libmatmul.a
