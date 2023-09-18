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
EXECS = naive_run naive_bench blis_run blis_bench gemm_run morello_run morello_bench # blis_autotune gemm_autotune

all: $(EXECS)

$(EXECS): %: %.o libmatmul.a $(HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -o $@ $< libmatmul.a $(LDFLAGS)

libmatmul.a: $(OBJS) $(HEADERS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $(MORE_CFLAGS) -c $< -o $@

check: naive_run blis_run gemm_run morello_run
	./naive_run
	./blis_run
	./gemm_run
	./morello_run
	diff -s --brief naive.txt blis.txt
	diff -s --brief naive.txt gemm.txt
	diff -s --brief naive.txt morello.txt

clean:
	rm -f *.o $(EXECS) libmatmul.a
