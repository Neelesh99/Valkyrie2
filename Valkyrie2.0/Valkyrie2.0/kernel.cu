﻿
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "antlr4-runtime.h"
#include "libs/qasm2Lexer.h"
#include "libs/qasm2Parser.h"
#include "libs/qasm2Visitor.h"
#include "libs/qasm2BaseVisitor.h"
#include "libs/staging.h"
#include "libs/CPUDevice.h"
#include "libs/GPUDevice.cuh"
#include <Windows.h>
#include <string>
#include <fstream>
#include <iostream>
#include <chrono>

#include <stdio.h>

using namespace antlr4;

std::string getexepath()
{
    char result[MAX_PATH];
    return std::string(result, GetModuleFileName(NULL, result, MAX_PATH));
}

cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);
void DisplayHeader();

__global__ void addKernel(int *c, const int *a, const int *b)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
}

void timeCPUExecution() {
    auto begin = std::chrono::high_resolution_clock::now();
    std::ifstream stream;    
    stream.open("output.qasm");
    ANTLRInputStream input(stream);

    qasm2Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    qasm2Parser parser(&tokens);

    qasm2Parser::MainprogContext* tree = parser.mainprog();

    qasm2BaseVisitor visitor;
    visitor.visitMainprog(tree);
    std::vector<Register> registers = visitor.getRegisters();
    std::vector<GateRequest> gateRequests = visitor.getGates();
    Stager stage = Stager();
    std::vector<ConcurrentBlock> blocks = stage.stageInformation(registers, gateRequests);
    CPUDevice device = CPUDevice();
    device.run(stage.getRegisters(), blocks);
    auto end = std::chrono::high_resolution_clock::now();
    std::cout << std::chrono::duration_cast<std::chrono::nanoseconds>(end - begin).count() << std::endl;
    device.prettyPrintQubitStates(device.revealQuantumState());
}

void timeGPUExecution() {
    auto begin = std::chrono::high_resolution_clock::now();
    std::ifstream stream;
    stream.open("output.qasm");
    ANTLRInputStream input(stream);

    qasm2Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    qasm2Parser parser(&tokens);

    qasm2Parser::MainprogContext* tree = parser.mainprog();

    qasm2BaseVisitor visitor;
    visitor.visitMainprog(tree);
    std::vector<Register> registers = visitor.getRegisters();
    std::vector<GateRequest> gateRequests = visitor.getGates();
    Stager stage = Stager();
    std::vector<ConcurrentBlock> blocks = stage.stageInformation(registers, gateRequests);
    GPUDevice deviceG = GPUDevice();
    deviceG.run(stage.getRegisters(), blocks);
    auto end = std::chrono::high_resolution_clock::now();
    std::cout << std::chrono::duration_cast<std::chrono::nanoseconds>(end - begin).count() << std::endl;
    deviceG.prettyPrintQubitStates(deviceG.revealQuantumState());
}



int main()
{
    const int arraySize = 5;
    const int a[arraySize] = { 1, 2, 3, 4, 5 };
    const int b[arraySize] = { 10, 20, 30, 40, 50 };
    int c[arraySize] = { 0 };

    //// Add vectors in parallel.
    cudaError_t cudaStatus = addWithCuda(c, a, b, arraySize);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 1;
    }

    printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
        c[0], c[1], c[2], c[3], c[4]);

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }
    /*std::cout << getexepath() << std::endl;
    std::ifstream stream;
     h q[0];
    stream.open("output.qasm");
    ANTLRInputStream input(stream);

    qasm2Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    qasm2Parser parser(&tokens);

    qasm2Parser::MainprogContext* tree = parser.mainprog();

    qasm2BaseVisitor visitor;
    visitor.visitMainprog(tree);    
    std::vector<Register> registers = visitor.getRegisters();
    std::vector<GateRequest> gateRequests = visitor.getGates();
    Stager stage = Stager();    
    std::vector<ConcurrentBlock> blocks = stage.stageInformation(registers, gateRequests);    
    CPUDevice device = CPUDevice();
    device.run(stage.getRegisters(), blocks);
    device.prettyPrintQubitStates(device.revealQuantumState());    
    GPUDevice deviceG = GPUDevice();
    deviceG.run(stage.getRegisters(), blocks);    
    deviceG.prettyPrintQubitStates(deviceG.revealQuantumState());
    DisplayHeader();*/
    for (int i = 0; i < 1; i++) {
        timeGPUExecution();
    }
    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size)
{
    int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    addKernel<<<1, size>>>(dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);
    
    return cudaStatus;
}

void DisplayHeader()
{
    const int kb = 1024;
    const int mb = kb * kb;
    std::cout << "NBody.GPU" << std::endl << "=========" << std::endl << std::endl;

    std::cout << "CUDA version:   v" << CUDART_VERSION << std::endl;

    int devCount;
    cudaGetDeviceCount(&devCount);
    std::cout << "CUDA Devices: " << std::endl << std::endl;

    for (int i = 0; i < devCount; ++i)
    {
        cudaDeviceProp props;
        cudaGetDeviceProperties(&props, i);
        std::cout << i << ": " << props.name << ": " << props.major << "." << props.minor << std::endl;
        std::cout << "  Global memory:   " << props.totalGlobalMem / mb << "mb" << std::endl;
        std::cout << "  Shared memory:   " << props.sharedMemPerBlock / kb << "kb" << std::endl;
        std::cout << "  Constant memory: " << props.totalConstMem / kb << "kb" << std::endl;
        std::cout << "  Block registers: " << props.regsPerBlock << std::endl << std::endl;

        std::cout << "  Warp size:         " << props.warpSize << std::endl;
        std::cout << "  Threads per block: " << props.maxThreadsPerBlock << std::endl;
        std::cout << "  Max block dimensions: [ " << props.maxThreadsDim[0] << ", " << props.maxThreadsDim[1] << ", " << props.maxThreadsDim[2] << " ]" << std::endl;
        std::cout << "  Max grid dimensions:  [ " << props.maxGridSize[0] << ", " << props.maxGridSize[1] << ", " << props.maxGridSize[2] << " ]" << std::endl;
        std::cout << std::endl;
    }
}
