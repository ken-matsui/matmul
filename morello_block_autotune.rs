#!/usr/bin/env cargo +nightly -Zscript

//! ```cargo
//! [dependencies]
//! anyhow = { version = "1.0", features = ["backtrace"] }
//! morello = { git = "https://github.com/samkaufman/morello.git", rev = "beac888e767314a82bf9c9beeb3c22648a8b43d1" }
//! ```

use anyhow::Result;
use std::fs::File;
use std::io::Write;
use std::panic;
use std::time::Duration;

use morello::codegen::CodeGen;
use morello::common::{DimSize, Dtype, Shape};
use morello::imp::kernels::KernelType;
use morello::layout::{col_major, row_major};
use morello::scheduling_sugar::{SchedulingSugar, Subschedule};
use morello::spec::{LogicalSpec, PrimitiveBasics, PrimitiveSpecType, Spec};
#[cfg(target_arch = "aarch64")]
use morello::target::ArmTarget as CpuTarget;
#[cfg(target_arch = "x86_64")]
use morello::target::X86Target as CpuTarget;
use morello::target::{CpuMemoryLevel, Target};
use morello::tensorspec::TensorSpecAux;

macro_rules! tee {
    ($w:expr, $fmt:expr, $($arg:tt)*) => {
        write!($w, $fmt, $($arg)*)?;
        print!($fmt, $($arg)*);
    };
}
macro_rules! teeln {
    ($w:expr, $fmt:expr, $($arg:tt)*) => {
        writeln!($w, $fmt, $($arg)*)?;
        println!($fmt, $($arg)*);
    };
}

fn matmul(size: DimSize) -> Result<()> {
    let spec = Spec::<CpuTarget>(
        LogicalSpec::Primitive(
            PrimitiveBasics {
                typ: PrimitiveSpecType::Matmul { accum: false },
                spec_shape: Shape::from([size, size, size].as_slice()),
                dtype: Dtype::Uint8,
            },
            vec![
                TensorSpecAux {
                    contig: row_major(2).contiguous_full(),
                    aligned: true,
                    level: CpuMemoryLevel::GL,
                    layout: row_major(2),
                    vector_size: None,
                };
                3
            ],
            true,
        ),
        CpuTarget::max_mem(),
    );

    let mut w = File::create("Morello_block_autotune.txt")?;

    let mut min_time = Duration::from_secs(1000000000);
    let mut min_params = vec![0, 0, 0];
    for mc in 0..12 {
        for nc in 0..12 {
            for kc in 0..12 {
                let mc = 1 << mc;
                let nc = 1 << nc;
                let kc = 1 << kc;
                tee!(w, "(mc: {}, nc: {}, kc: {}): ", mc, nc, kc);

                panic::set_hook(Box::new(|_| {
                    // Do nothing
                }));
                // Manually schedule the matrix multiplication.
                let implementation = panic::catch_unwind(|| {
                    spec
                        // 5th -> 4th
                        .split(kc)
                        // moving the B tensor
                        .move_param(
                            1,
                            CpuMemoryLevel::L1, /* GL -> L3 */
                            row_major(2),
                            None,
                        )
                        // 4th -> 3rd
                        .tile_out(&[nc, kc], false)
                        // moving the A tensor
                        .move_param(
                            0,
                            CpuMemoryLevel::L1, /* GL -> L2 */
                            col_major(2),
                            None,
                        )
                        // 3rd -> 2nd
                        .tile_out(&[kc, mc], false)
                        // purple to blue
                        .move_param(
                            1,
                            CpuMemoryLevel::L1, /* L3 -> L1 */
                            row_major(2),
                            None,
                        )
                        // microkernel
                        .split(1)
                        .move_param(2, CpuMemoryLevel::L1, row_major(2), None)
                        .move_param(0, CpuMemoryLevel::RF, row_major(2), None)
                        .subschedule(&[0], &|move_a| {
                            move_a
                                .tile_out(&[1, 1], false)
                                .place(KernelType::ValueAssign)
                        })
                        .subschedule(&[1], &|matmul_b| {
                            matmul_b.move_param(1, CpuMemoryLevel::RF, col_major(2), None)
                        })
                        .subschedule(&[1, 0], &|move_ba| {
                            move_ba
                                .tile_out(&[1, 1], false)
                                .place(KernelType::ValueAssign)
                        })
                        .subschedule(&[1, 1], &|matmul_bb| {
                            matmul_bb.tile_out(&[1, 1], false).move_param(
                                2,
                                CpuMemoryLevel::RF,
                                row_major(2),
                                None,
                            )
                        })
                        .subschedule(&[1, 1, 0], &|s| s.place(KernelType::ValueAssign))
                        .subschedule(&[1, 1, 1], &|s| s.place(KernelType::Mult))
                        .subschedule(&[1, 1, 2], &|s| s.place(KernelType::ValueAssign))
                    // End
                });
                let _ = panic::take_hook();

                match implementation {
                    Err(_) => {
                        teeln!(w, "Cannot schedule.",);
                    }
                    Ok(imp) => {
                        let bench_samples = imp.estimate_optimal_iters()?;
                        let bench_result = imp.bench(bench_samples, None);
                        match bench_result {
                            Ok(bench_result) => {
                                let secs = bench_result.result.as_secs();
                                let nanos = bench_result.result.subsec_nanos();
                                teeln!(w, "ave. {}s {:09}ns", secs, nanos);

                                if bench_result.result < min_time {
                                    min_time = bench_result.result;
                                    min_params = vec![mc, nc, kc];
                                }
                            }
                            Err(err) => {
                                teeln!(w, "\nFailed to benchmark: {:?}", err);
                            }
                        }
                    }
                }

                teeln!(
                    w,
                    "Current best params: (mc: {}, nc: {}, kc: {}): {}s {:09}ns\n",
                    min_params[0],
                    min_params[1],
                    min_params[2],
                    min_time.as_secs(),
                    min_time.subsec_nanos()
                );
            }
        }
    }

    teeln!(
        w,
        "Best params: (mc: {}, nc: {}, kc: {}): {}s {:09}ns",
        min_params[0],
        min_params[1],
        min_params[2],
        min_time.as_secs(),
        min_time.subsec_nanos()
    );

    Ok(())
}

fn main() -> Result<()> {
    matmul(2048)
}
