#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hi, {name}!")
}

use num_bigint::BigUint;
use std::time::Instant;

#[flutter_rust_bridge::frb(sync)]
pub fn calculate_fibonacci(n: u32) -> String {
    let start = Instant::now();
    
    let result = if n <= 1 {
        BigUint::from(n)
    } else {
        let mut prev = BigUint::from(0u32);
        let mut current = BigUint::from(1u32);
        
        for _ in 1..n {
            let next = &prev + &current;
            prev = current;
            current = next;
        }
        current
    };
    
    let duration = start.elapsed();
    format!("Result: {}\nTime taken: {:?}", result, duration)
}

#[flutter_rust_bridge::frb(sync)]
pub fn heavy_compute(size: i32) -> String {
    let size = size as usize;
    
    // Use a flat vector for better memory layout
    let matrix1: Vec<f64> = vec![1.0; size * size];
    let matrix2: Vec<f64> = vec![2.0; size * size];
    let mut result: Vec<f64> = vec![0.0; size * size];
    
    let start = std::time::Instant::now();
    
    // Perform matrix multiplication 1000 times
    for _ in 0..1000 {
        // Reset result vector
        result.fill(0.0);

        // Optimized matrix multiplication with flat arrays
        for i in 0..size {
            for k in 0..size {
                let m1_ik = matrix1[i * size + k];
                let row_offset = i * size;
                
                // Help auto-vectorization with chunk iteration
                for j in (0..size).step_by(4) {
                    if j + 4 <= size {
                        // Process 4 elements at once
                        let j1 = j;
                        let j2 = j + 1;
                        let j3 = j + 2;
                        let j4 = j + 3;
                        
                        result[row_offset + j1] += m1_ik * matrix2[k * size + j1];
                        result[row_offset + j2] += m1_ik * matrix2[k * size + j2];
                        result[row_offset + j3] += m1_ik * matrix2[k * size + j3];
                        result[row_offset + j4] += m1_ik * matrix2[k * size + j4];
                    } else {
                        // Handle remaining elements
                        for j_rem in j..size {
                            result[row_offset + j_rem] += m1_ik * matrix2[k * size + j_rem];
                        }
                        break;
                    }
                }
            }
        }
    }
    
    // Calculate checksum
    let checksum: f64 = result.iter().sum();
    
    let duration = start.elapsed();
    format!(
        "Checksum: {:.2}\nTime taken for 1000 iterations: {:?}\nAverage time per iteration: {:?}", 
        checksum, 
        duration,
        duration / 1000
    )
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
