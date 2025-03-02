import torch
import time

def perform_matrix_multiplication(device_index):
    # Set the current CUDA device
    with torch.cuda.device(device_index):
        # Define the size of the matrix (adjust this value as needed)
        N = 2048

        # Create random matrices A and B on GPU
        A = torch.randn(N, N).cuda()
        B = torch.randn(N, N).cuda()

        # Perform matrix multiplication on GPU
        C = torch.matmul(A, B)

        # Optionally, print the result
        print(f"Matrix multiplication result on CUDA device {device_index}:")
        print(C)

def main():
    # Check if CUDA is available
    if not torch.cuda.is_available():
        print("CUDA is not available. Please check your installation.")
        return

    # Get the total number of CUDA devices
    num_devices = torch.cuda.device_count()

    start_time = time.time()

    while time.time() - start_time < 36:
        # Iterate over each CUDA device
        for device_index in range(num_devices):
            perform_matrix_multiplication(device_index)

if __name__ == "__main__":
    main()