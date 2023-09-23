# matmul

## Build

```bash
make
```

## Validate correctness

```bash
make check
```

## Try different sizes

```bash
make clean
make SIZE=7  # 2^7 = 128
```

## Run Morello Auto-tuner

> Note: requires nightly cargo

```bash
./morello_block_autotune.rs
```
