# Compiler settings
CC = clang
CFLAGS = -Wall -Wpedantic -O3 -std=gnu99 -fopenmp
LDFLAGS = -L./src -lmatmul

# Archiver settings
AR = ar
ARFLAGS = rcs

# Source files
SRCS = src/Bench.c src/Matmul.c

# Header files
HEADERS = $(SRCS:.c=.h)

# Object files
OBJS = $(SRCS:.c=.o)

all: naive blis gemm

naive: src/naive.o src/libmatmul.a $(HEADERS)
	$(CC) $(CFLAGS) -o $@ src/naive.o src/libmatmul.a $(LDFLAGS)

blis: src/blis.o src/libmatmul.a $(HEADERS)
	$(CC) $(CFLAGS) -o $@ src/blis.o src/libmatmul.a $(LDFLAGS)

gemm: src/gemm.o src/libmatmul.a $(HEADERS)
	$(CC) $(CFLAGS) -o $@ src/gemm.o src/libmatmul.a $(LDFLAGS)

src/libmatmul.a: $(OBJS) $(HEADERS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f src/*.o naive blis src/libmatmul.a
