
#include<stdio.h>
#include<math.h>
#include<fstream>
#define SIZE 8
#include "cuda_runtime.h"
#include "device_launch_parameters.h" 
#include "malloc.h"
#include <time.h>
#include <iostream>
#include"device_functions.h"
using namespace std;
int __device__ RSC(int a, int* t1, int* t2)  //分量编码器//
{
    int b, c;
    b = a ^ *t1 ^ *t2;
    c = b ^ *t2;
    *t2 = *t1;
    *t1 = b;
    return(c);
}
__global__ void cudaencode(int *dataA, int *A)
{
    int u[SIZE], u1[SIZE], c0[SIZE], c1[SIZE], c2[SIZE];
    int i, * p1, * p2, k, k1, k2, n;
    k1 = 0; k2 = 0; k = 0;
    p1 = &k1; p2 = &k2;
    int j = blockIdx.x*blockDim.x+threadIdx.x;
    if (j < 250000)//线程量约束，可根据数据量大小更改
        //for (j = 0; j < 250000; j++)//red中的j个数据
        //{
    {
        for (i = 7; i >= 0; i--)
        {
            u[i] = dataA[j] % 10;
            dataA[j] /= 10;
        }                      //拆位
        for (i = 0; i < SIZE; i++)    //未经交织的信息序列经分量编码器后的系统输出和校验输出//
        {
            c0[i] = u[i];
            c1[i] = RSC(u[i], p1, p2);
        }
        for (i = 0; i < SIZE; i++)    //倒叙交织器
        {
            u1[i] = u[SIZE - 1 - i];
        }
        p1 = &k1; p2 = &k2;     //移位寄存器置零//
        for (i = 0; i < SIZE; i++)    //交织后的信息序列经分量编码器后的校验输出//
            c2[i] = RSC(u1[i], p1, p2);
        for (i = 0; i < SIZE; i++)    //经删余矩阵复接//
            for (n = 0; n < 2; n++)
                if (n == 0)
                    A[j * 16 + i * 2 + n] = c0[i];
                else
                {
                    if (i % 2 == 0)
                        A[j * 16 + i * 2 + n] = c1[i];
                    else
                        A[j * 16 + i * 2 + n] = c2[i];
                }
    }
      
    //}


}
int main()
{

    int i, j, n;
    int pic_size;
    int* dataA = (int*)malloc(sizeof(int) * 250000);//开三色空间
    int* dataB = (int*)malloc(sizeof(int) * 250000);
    int* dataC = (int*)malloc(sizeof(int) * 250000);
    int *A = (int*)malloc(sizeof(int) * 2 * 8 * 250000);//开三色导出数组空间
    int *B = (int*)malloc(sizeof(int) * 2 * 8 * 250000);
    int *C = (int*)malloc(sizeof(int) * 2 * 8 * 250000);
    int *d_dataA, *d_dataB, *d_dataC, * d_dataAA, * d_dataBB, * d_dataCC;
    cudaMalloc((void**)&d_dataA, sizeof(int) * 250000);//开三色显存空间
    cudaMalloc((void**)&d_dataB, sizeof(int) * 250000);
    cudaMalloc((void**)&d_dataC, sizeof(int) * 250000);
    cudaMalloc((void**)&d_dataAA, sizeof(int) * 2 * 8 * 250000);//开三色显存导出空间
    cudaMalloc((void**)&d_dataBB, sizeof(int) * 2 * 8 * 250000);
    cudaMalloc((void**)&d_dataCC, sizeof(int) * 2 * 8 * 250000);
    FILE* fw_pic = fopen("E:\\matin\\visual studio projects\\turbo_encode\\size.txt", "r");
    fscanf(fw_pic, "%d", &pic_size);    //读取图片大小
    fclose(fw_pic);
    FILE* fw_red = fopen("E:\\matin\\visual studio projects\\turbo_encode\\red_data.txt", "r");
    for (j = 0; j < pic_size; j++)
        fscanf(fw_red, "%d", &dataA[j]);
    fclose(fw_red);           //读取red
    FILE* fw_green = fopen("E:\\matin\\visual studio projects\\turbo_encode\\green_data.txt", "r");
    for (j = 0; j < pic_size; j++)
        fscanf(fw_green, "%d", &dataB[j]);//读取green
    fclose(fw_green);
    FILE* fw_blue = fopen("E:\\matin\\visual studio projects\\turbo_encode\\blue_data.txt", "r");
    for (j = 0; j < pic_size; j++)
        fscanf(fw_blue, "%d", &dataC[j]);//读取blue
    fclose(fw_blue);
    cudaMemcpy(d_dataA, dataA, sizeof(int) * 250000, cudaMemcpyHostToDevice);//原红色数据导入显存
    cudaMemcpy(d_dataAA, A, sizeof(int) * 2 * 8 * 250000, cudaMemcpyHostToDevice);//红色数组空间导入显存
    cudaMemcpy(d_dataB, dataB, sizeof(int) * 250000, cudaMemcpyHostToDevice);//绿色
    cudaMemcpy(d_dataBB, B, sizeof(int) * 2 * 8 * 250000, cudaMemcpyHostToDevice);
    cudaMemcpy(d_dataC, dataC, sizeof(int) * 250000, cudaMemcpyHostToDevice);//蓝色
    cudaMemcpy(d_dataCC, C, sizeof(int) * 2 * 8 * 250000, cudaMemcpyHostToDevice);
    //dim3 dimgrid(32 * 32);
    //dim3 dimblock(64);
    clock_t start = clock();
    cudaencode << <256,1024 >> > (d_dataA, d_dataAA);//cuda编码运算
    cudaencode << <256, 1024 >> > (d_dataB, d_dataBB);
    cudaencode << <256, 1024 >> > (d_dataC, d_dataCC);
    cudaMemcpy(A, d_dataAA, sizeof(int) * 2 * 8 * 250000, cudaMemcpyDeviceToHost);//cuda编码运算结果从显存导入内存
    cudaMemcpy(B, d_dataBB, sizeof(int) * 2 * 8 * 250000, cudaMemcpyDeviceToHost);
    cudaMemcpy(C, d_dataCC, sizeof(int) * 2 * 8 * 250000, cudaMemcpyDeviceToHost);
   clock_t end = clock();
    ofstream out_red("E:\\matin\\visual studio projects\\turbo_encode\\red_encode.txt");
    for (int k = 0; k < 250000 * 16; k++)//rgb编码输出
    {
     
            out_red << A[k];
            if((k+1)%16==0)
            {
                out_red << "\n";
            }
     
    }
    out_red.close();
    ofstream out_green("E:\\matin\\visual studio projects\\turbo_encode\\green_encode.txt");
    for (int k = 0; k < 250000 * 16; k++)//rgb编码输出
    {

        out_green << B[k];
        if ((k + 1) % 16 == 0)
        {
            out_green << "\n";
        }

    }
    out_green.close();
    ofstream out_blue("E:\\matin\\visual studio projects\\turbo_encode\\blue_encode.txt");
    for (int k = 0; k < 250000 * 16; k++)//rgb编码输出
    {

        out_blue << C[k];
        if ((k + 1) % 16 == 0)
        {
            out_blue << "\n";
        }

    }
    out_blue.close();
 
    free(dataA);
    free(dataB);
    free(dataC);
    cudaFree(d_dataA);
    cudaFree(d_dataB);
    cudaFree(d_dataC);
    cudaFree(d_dataAA);
    cudaFree(d_dataBB);
    cudaFree(d_dataCC);
    double endtime = (double)(end - start) / CLOCKS_PER_SEC;
    cout << "totaltime:" << endtime * 1000 << "ms" << endl;
    return 0;
}
