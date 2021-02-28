
#include<stdio.h>
#include<math.h>
#include <time.h>
#include <stdlib.h>
#include <cuda_device_runtime_api.h>
#include <cuda_runtime.h>
#include <iostream>
using namespace std;
#include "device_launch_parameters.h" 
#include<fstream>
#include "malloc.h"
#define SIZE 8
#define L 3
#define Lc 40
#define Es 1
#define Pi 3.14159265358979
#define Epsilon myexp(1)
#pragma warning(disable:4996)


double __device__  myexp(double x) {
    int i, k, m, t;
    int xm = (int)x;
    double sum;
    double e;
    double ef;
    double z;
    double sub = x - xm;
    m = 1;      //阶乘算法分母
    e = 1.0;  //e的xm
    ef = 1.0;
    t = 10;      //算法精度
    z = 1;  //分子初始化
    sum = 1;
    //  printf("x=%f\n",x);
    //  printf("sub=%f\n",sub);
    if (xm < 0) {     //判断xm是否大于0？
        xm = (-xm);
        for (k = 0; k < xm; k++) { ef *= 2.718281; }
        e /= ef;
    }
    else { for (k = 0; k < xm; k++) { e *= 2.718281; } }
    //  printf("e=%f\n",e);
    //  printf("xm=%d\n",xm);
    for (i = 1; i < t; i++) {
        m *= i;
        z *= sub;
        sum += z / m;
    }
    return sum * e;
}

double __device__    mk(double a, double s, double p, int c, int u)  //Mk(e)的计算//
{
    double mk;
    if (u == 1)
        mk = a - log(1 + myexp(a)) + 1 / 2 * s + 1 / 2 * p * (2 *double(c) - 1);
    else
        mk = -log(1 + myexp(a)) - 1 / 2 * s + 1 / 2 * p * (2 * double(c) - 1);
    return(mk);
}
 double __device__  abk(double t1, double k1, double t2, double k2)  //Ak(e)和Bk(e)的计算//
{
    double s1, s2, s;
    s1 = exp(t1 + k1); s2 = exp(t2 + k2);
    s = log(s1 + s2);
    return(s);
}
//分量译码器//
 void __device__   DEC(double a[SIZE + 1], double ys[SIZE + 1], double yp[SIZE + 1], double e[SIZE])
{
    double me1[SIZE + 1], me2[SIZE + 1], me3[SIZE + 1], me4[SIZE + 1], me5[SIZE + 1], me6[SIZE + 1], me7[SIZE + 1], me8[SIZE + 1];
    double a0[SIZE], a1[SIZE], a2[SIZE], a3[SIZE], b0[SIZE + 1], b1[SIZE + 1], b2[SIZE + 1], b3[SIZE + 1];
    int i, u, c;
    for (i = 1; i <= SIZE; i++)
    {
        c = 0; u = 0;
        me1[i] = mk (a[i], ys[i], yp[i], c, u);
        c = 1; u = 1;
        me2[i] = mk (a[i], ys[i], yp[i], c, u);
        c = 0; u = 1;
        me3[i] = mk (a[i], ys[i], yp[i], c, u);
        c = 1; u = 0;
        me4[i] = mk  (a[i], ys[i], yp[i], c, u);
        c = 0; u = 0;
        me5[i] = mk  (a[i], ys[i], yp[i], c, u);
        c = 1; u = 1;
        me6[i] = mk  (a[i], ys[i], yp[i], c, u);
        c = 0; u = 1;
        me7[i] = mk  (a[i], ys[i], yp[i], c, u);
        c = 1; u = 0;
        me8[i] = mk  (a[i], ys[i], yp[i], c, u);
    }
    a0[0] = 1; a1[0] = 0; a2[0] = 0; a3[0] = 0;
    b0[SIZE] = 0; b1[SIZE] = 0; b2[SIZE] = 1; b3[SIZE] = 0;
    for (i = 1; i < SIZE; i++)
    {
        a0[i] = abk(a0[i - 1], me1[i], a2[i - 1], me6[i]);
        a1[i] = abk(a0[i - 1], me2[i], a2[i - 1], me5[i]);
        a2[i] = abk(a1[i - 1], me4[i], a3[i - 1], me7[i]);
        a3[i] = abk(a1[i - 1], me3[i], a3[i - 1], me8[i]);
    }
    for (i = SIZE - 1; i >= 1; i--)
    {
        b0[i] = abk(b0[i + 1], me1[i + 1], b1[i + 1], me2[i + 1]);
        b1[i] = abk(b3[i + 1], me3[i + 1], b2[i + 1], me4[i + 1]);
        b2[i] = abk(b1[i + 1], me5[i + 1], b0[i + 1], me6[i + 1]);
        b3[i] = abk(b2[i + 1], me7[i + 1], b3[i + 1], me8[i + 1]);
    }
    for (i = 1; i < SIZE; i++)
        e[i] = log(myexp(a0[i - 1] + 1 / 2 * yp[i] + b1[i]) + myexp(a1[i - 1] - 1 / 2 * yp[i] + b2[i]) + myexp(a2[i - 1] + 1 / 2 * yp[i] + b0[i]) + myexp(a3[i - 1] - 1 / 2 * yp[i] + b3[i])) - log(myexp(a0[i - 1] - 1 / 2 * yp[i] + b0[i]) + myexp(a1[i - 1] + 1 / 2 * yp[i] + b3[i]) + myexp(a2[i - 1] - 1 / 2 * yp[i] + b1[i]) + myexp(a3[i - 1] + 1 / 2 * yp[i] + b2[i]));
}
 void  __device__   interlace(double a[SIZE + 1], double b[SIZE + 1])  //交织器//
{
    int i;
    for (i = 1; i < SIZE + 1; i++)    //倒叙交织器
    {
        b[i] = a[SIZE + 1 - i];
    }
}
 void  __device__   uninterlace(double a[SIZE + 1], double b[SIZE + 1])  //解交织器//
{
    int i;
    for (i = 1; i < SIZE + 1; i++)    //倒叙解交织
    {
        b[i] = a[SIZE + 1 - i];
    }
}
__global__ void cudadecode(double *dataA, double *A)
{
    int x[SIZE + 1][SIZE + 1], y[SIZE + 1][3], y0[SIZE + 1], y1[SIZE + 1], y2[SIZE + 1];
    double y0_in[SIZE + 1], y00_in[SIZE + 1], y1_in[SIZE + 1], y2_in[SIZE + 1];
    double a[SIZE + 1], e[SIZE+1];
    double out1[SIZE + 1], out2[SIZE + 1];
    int i, j, k;
    int data1[16];
    int p = blockIdx.x * blockDim.x + threadIdx.x;

    if (p < 250000)//线程量约束，可根据数据量大小更改
    {
        k = 0;
        for (i = 15; i >= 0; i--)
        {
            data1[i] = int(dataA[p] - floor(dataA[p] / 10) * 10);
            dataA[p] /= 10;
        }
        for (i = 1; i <= SIZE; i++)
            for (j = 1; j < 3; j++)
            {
                x[i][j] = data1[k];
                k++;
                if (k == 15)
                    k = 0;
            }
        for (i = 1; i <= SIZE; i++)
            for (j = 1; j < 3; j++)
            {
                y[i][j] = double(2 * x[i][j] - 1);
            }
        for (i = 1; i <= SIZE; i++)   //串并转换，信道置信度加权//
            for (j = 1; j < 3; j++)
            {
                if (j == 1)
                {
                    y0[i] = y[i][j];
                    y0_in[i] = Lc * double(y0[i]);
                }
                else
                {
                    if (i % 2 == 1)
                    {
                        y1[i] = y[i][j];
                        y1_in[i] = Lc * double(y1[i]);
                        y2[i] = 0;
                        y2_in[i] = Lc * double(y2[i]);
                    }
                    else
                    {
                        y1[i] = 0;
                        y1_in[i] = Lc * double(y1[i]);
                        y2[i] = y[i][j];
                        y2_in[i] = Lc * double(y2[i]);
                    }
                }
            }
        for (i = 1; i <= SIZE; i++)
            a[i] = 0;
        interlace(y0_in, y00_in);
        for (k = 1; k < 6; k++)    //迭代6次//
        {
            DEC(a, y0_in, y1_in, e);
            interlace(e, a);
            DEC(a, y00_in, y2_in, e);
            uninterlace(e, a);
        }
        DEC(a, y0_in, y1_in, e);
        interlace(e, a);
        DEC(a, y00_in, y2_in, e);
        for (i = 1; i <= SIZE; i++)
            out1[i] = a[i] + e[i] + y00_in[i];
        uninterlace(out1, out2);
        for (i = 1; i <= SIZE; i++)  //硬判决，输出译码后的码字//
        {
            if (out2[i] >= 0)
                A[8 * p + i - 1] = 1;
            else
                A[8 * p + i - 1] = 0;
            ;
        }
    }
}

int main()
{

    int i, j, k;
    double* dataA = (double*)malloc(sizeof(double) * 250000);//开三色空间
    double* dataB = (double*)malloc(sizeof(double) * 250000);
    double* dataC = (double*)malloc(sizeof(double) * 250000);
    double *A = (double*)malloc(sizeof(double) *  8 * 250000);//开三色导出数组空间
    double *B = (double*)malloc(sizeof(double) *  8 * 250000);
    double *C = (double*)malloc(sizeof(double) *  8 * 250000);
    double *d_dataA, *d_dataB, *d_dataC, *d_dataAA, *d_dataBB, *d_dataCC;
    cudaMalloc((void**)&d_dataA, sizeof(double) * 250000);//开三色显存空间
    cudaMalloc((void**)&d_dataB, sizeof(double) * 250000);
    cudaMalloc((void**)&d_dataC, sizeof(double) * 250000);
    cudaMalloc((void**)&d_dataAA, sizeof(double)  * 8 * 250000);//开三色显存导出空间
    cudaMalloc((void**)&d_dataBB, sizeof(double)  * 8 * 250000);
    cudaMalloc((void**)&d_dataCC, sizeof(double)  * 8 * 250000);
    memset(dataA, 0, sizeof(double) * 250000);
    memset(dataB, 0, sizeof(double) * 250000);
    memset(dataC, 0, sizeof(double) * 250000);
    memset(A, 0, sizeof(double) * 8*250000);
    memset(B, 0, sizeof(double) * 8*250000);
    memset(C, 0, sizeof(double) *8* 250000);
    cudaMemset((void**)&d_dataA, 0, sizeof(double) * 250000);
    cudaMemset((void**)&d_dataB, 0, sizeof(double) * 250000);
    cudaMemset((void**)&d_dataC, 0, sizeof(double) * 250000);
    cudaMemset((void**)&d_dataAA, 0, sizeof(double) *8* 250000);
    cudaMemset((void**)&d_dataBB, 0, sizeof(double) *8* 250000);
    cudaMemset((void**)&d_dataCC, 0, sizeof(double) *8* 250000);

   
    FILE* fw_red = fopen("/home/nvidia/project/transport/red_encode.txt", "r");
    for (i = 0; i < 250000; i++)
        fscanf(fw_red, "%lf", &dataA[i]);
    fclose(fw_red);          
    FILE* fw_green = fopen("/home/nvidia/project/transport/green_encode.txt", "r");
    for (j = 0; j < 250000; j++)
        fscanf(fw_green, "%lf", &dataB[j]);
    fclose(fw_green);
    FILE* fw_blue = fopen("/home/nvidia/project/transport/blue_encode.txt", "r");
    for (k = 0; k < 250000; k++)
        fscanf(fw_blue, "%lf", &dataC[k]);
    fclose(fw_blue);

    clock_t start = clock();
     cudaMemcpy(d_dataA, dataA, sizeof(double) * 250000, cudaMemcpyHostToDevice);//原红色数据导入显存
    cudaMemcpy(d_dataAA, A, sizeof(double) * 8 * 250000, cudaMemcpyHostToDevice);//红色数组空间导入显存
    cudaMemcpy(d_dataB, dataB, sizeof(double) * 250000, cudaMemcpyHostToDevice);//绿色
    cudaMemcpy(d_dataBB, B, sizeof(double) * 8 * 250000, cudaMemcpyHostToDevice);
    cudaMemcpy(d_dataC, dataC, sizeof(double) * 250000, cudaMemcpyHostToDevice);//蓝色
    cudaMemcpy(d_dataCC, C, sizeof(double) * 8 * 250000, cudaMemcpyHostToDevice);
    cudadecode << <256, 1024 >> > (d_dataA, d_dataAA);//cuda译码运算
    cudadecode << <256, 1024 >> > (d_dataB, d_dataBB);//cuda译码运算
    cudadecode << <256, 1024 >> > (d_dataC, d_dataCC);//cuda译码运算
    cudaMemcpy(A, d_dataAA, sizeof(double)  * 8 * 250000, cudaMemcpyDeviceToHost);//cuda译码运算结果从显存导入内存
    cudaMemcpy(B, d_dataBB, sizeof(double)* 8 * 250000, cudaMemcpyDeviceToHost);
    cudaMemcpy(C, d_dataCC, sizeof(double)  * 8 * 250000, cudaMemcpyDeviceToHost);
    clock_t end = clock();
    double endtime = (double)(end - start) / CLOCKS_PER_SEC;
    cout << "totaltime:" << endtime * 1000 << "ms" << endl;
    ofstream out_red("/home/nvidia/project/transport/red_decode.txt");
    for (int i = 0; i < 250000 * 8; i++)//rgb编码输出
    {

        out_red << A[i];
        if ((i + 1) % 8 == 0)
        {
            out_red << "\n";
        }

    }
    out_red.close();
    ofstream out_green("/home/nvidia/project/transport/green_decode.txt");
    for (int j = 0; j < 250000 * 8; j++)//rgb编码输出
    {

        out_green << B[j];
        if ((j + 1) % 8 == 0)
        {
            out_green << "\n";
        }

    }
    out_green.close();
    ofstream out_blue("/home/nvidia/project/transport/blue_decode.txt");
    for (int k = 0; k < 250000 * 8; k++)//rgb编码输出
    {

        out_blue << C[k];
        if ((k + 1) % 8 == 0)
        {
            out_blue << "\n";
        }

    }
    
    free(dataA);
    free(dataB);
    free(dataC);
    cudaFree(d_dataA);
    cudaFree(d_dataB);
    cudaFree(d_dataC);
    cudaFree(d_dataAA);
    cudaFree(d_dataBB);
    cudaFree(d_dataCC);
}

