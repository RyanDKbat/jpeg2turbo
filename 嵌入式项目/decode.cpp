#include<stdio.h>
#include<math.h>
#include <stdlib.h>
#include<fstream>
#define SIZE 8
#define L 3
#define Lc 40
#define Es 1
#define Pi 3.14159265358979
#define Epsilon exp(1)
#define _CRT_SECURE_NO_WARNINGS
#pragma warning(disable:4996)
using namespace std;


double mk(double a, double s, double p, int c, int u)  //Mk(e)的计算//
{
    double mk;
    if (u == 1)
        mk = a - log(1 + exp(a)) + 1 / 2 * s + 1 / 2 * p * (2 * c - 1);
    else
        mk = -log(1 + exp(a)) - 1 / 2 * s + 1 / 2 * p * (2 * c - 1);
    return(mk);
}
double abk(double t1, double k1, double t2, double k2)  //Ak(e)和Bk(e)的计算//
{
    double s1, s2, s;
    s1 = exp(t1 + k1); s2 = exp(t2 + k2);
    s = log(s1 + s2);
    return(s);
}
//分量译码器//
void DEC(double a[SIZE + 1], double ys[SIZE + 1], double yp[SIZE + 1], double e[SIZE])
{
    double me1[SIZE + 1], me2[SIZE + 1], me3[SIZE + 1], me4[SIZE + 1], me5[SIZE + 1], me6[SIZE + 1], me7[SIZE + 1], me8[SIZE + 1];
    double a0[SIZE], a1[SIZE], a2[SIZE], a3[SIZE], b0[SIZE + 1], b1[SIZE + 1], b2[SIZE + 1], b3[SIZE + 1];
    int i, u, c;
    for (i = 1; i <= SIZE; i++)
    {
        c = 0; u = 0;
        me1[i] = mk(a[i], ys[i], yp[i], c, u);
        c = 1; u = 1;
        me2[i] = mk(a[i], ys[i], yp[i], c, u);
        c = 0; u = 1;
        me3[i] = mk(a[i], ys[i], yp[i], c, u);
        c = 1; u = 0;
        me4[i] = mk(a[i], ys[i], yp[i], c, u);
        c = 0; u = 0;
        me5[i] = mk(a[i], ys[i], yp[i], c, u);
        c = 1; u = 1;
        me6[i] = mk(a[i], ys[i], yp[i], c, u);
        c = 0; u = 1;
        me7[i] = mk(a[i], ys[i], yp[i], c, u);
        c = 1; u = 0;
        me8[i] = mk(a[i], ys[i], yp[i], c, u);
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
        e[i] = log(exp(a0[i - 1] + 1 / 2 * yp[i] + b1[i]) + exp(a1[i - 1] - 1 / 2 * yp[i] + b2[i]) + exp(a2[i - 1] + 1 / 2 * yp[i] + b0[i]) + exp(a3[i - 1] - 1 / 2 * yp[i] + b3[i])) - log(exp(a0[i - 1] - 1 / 2 * yp[i] + b0[i]) + exp(a1[i - 1] + 1 / 2 * yp[i] + b3[i]) + exp(a2[i - 1] - 1 / 2 * yp[i] + b1[i]) + exp(a3[i - 1] + 1 / 2 * yp[i] + b2[i]));
}
void interlace(double a[SIZE + 1], double b[SIZE + 1])  //交织器//
{
    int i;
    for (i = 1; i < SIZE + 1; i++)    //倒叙交织器
    {
        b[i] = a[SIZE + 1 - i];
    }
}
void uninterlace(double a[SIZE + 1], double b[SIZE + 1])  //解交织器//
{
    int i;
    for (i = 1; i < SIZE + 1; i++)    //倒叙解交织
    {
        b[i] = a[SIZE + 1 - i];
    }
}
void decode(double* dataA, double* A) {
    int x[SIZE + 1][SIZE + 1], y[SIZE + 1][3], y0[SIZE + 1], y1[SIZE + 1], y2[SIZE + 1];
    double y0_in[SIZE + 1], y00_in[SIZE + 1], y1_in[SIZE + 1], y2_in[SIZE + 1];
    double a[SIZE + 1], e[SIZE + 1];
    double out1[SIZE + 1], out2[SIZE + 1];
    int i, j, k,p;
    int data1[16];
    for (p = 0; p < 250000; p++)
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
                y[i][j] = sqrt(Es) * (2 * x[i][j] - 1);
            }
        for (i = 1; i <= SIZE; i++)   //串并转换，信道置信度加权//
            for (j = 1; j < 3; j++)
            {
                if (j == 1)
                {
                    y0[i] = y[i][j];
                    y0_in[i] = Lc * (y0[i]);
                }
                else
                {
                    if (i % 2 == 1)
                    {
                        y1[i] = y[i][j];
                        y1_in[i] = Lc * (y1[i]);
                        y2[i] = 0;
                        y2_in[i] = Lc * (y2[i]);
                    }
                    else
                    {
                        y1[i] = 0;
                        y1_in[i] = Lc * (y1[i]);
                        y2[i] = y[i][j];
                        y2_in[i] = Lc * (y2[i]);
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
                A[8*p+i-1] = 1;
            else
                A[8*p+i-1] = 0;
            ;
        }
    }
}

int main()
{
    int x[SIZE + 1][SIZE + 1], y[SIZE + 1][3], y0[SIZE + 1], y1[SIZE + 1], y2[SIZE + 1], u[SIZE + 1];
    double y0_in[SIZE + 1], y00_in[SIZE + 1], y1_in[SIZE + 1], y2_in[SIZE + 1];
    double a[SIZE + 1], e[SIZE + 1];
    double out1[SIZE + 1], out2[SIZE + 1];
    int i, j, k;
    int data1[16];
    double* dataA = (double*)malloc(sizeof(double) * 250000);//开三色空间
    double* dataB = (double*)malloc(sizeof(double) * 250000);
    double* dataC = (double*)malloc(sizeof(double) * 250000);
    double* A = (double*)malloc(sizeof(double) * 8 * 250000);//开三色导出数组空间
    double* B = (double*)malloc(sizeof(double) * 8 * 250000);
    double* C = (double*)malloc(sizeof(double) * 8 * 250000);
    FILE* red_fw = fopen("E:\\matin\\visual studio projects\\turbo_encode\\red_encode.txt", "r");
    for (i = 0; i < 250000; i++)
    {
        fscanf(red_fw, "%lf", &dataA[i]);
    }
    fclose(red_fw);
    FILE* green_fw = fopen("E:\\matin\\visual studio projects\\turbo_encode\\green_encode.txt", "r");
    for (i = 0; i < 250000; i++)
    {
        fscanf(green_fw, "%lf", &dataB[i]);
    }
    fclose(green_fw);
    FILE* blue_fw = fopen("E:\\matin\\visual studio projects\\turbo_encode\\blue_encode.txt", "r");
    for (i = 0; i < 250000; i++)
    {
        fscanf(blue_fw, "%lf", &dataC[i]);
    }

    fclose(blue_fw);
    decode(dataA, A);
    decode(dataB, B);
    decode(dataC, C);
    ofstream out_red("E:\\matin\\visual studio projects\\turbo_decode\\red_encode.txt");
    for (int k = 0; k < 250000 *8; k++)//rgb编码输出
    {

        out_red << A[k];
        if ((k + 1) % 8 == 0)
        {
            out_red << "\n";
        }

    }
    out_red.close();
    ofstream out_green("E:\\matin\\visual studio projects\\turbo_decode\\green_encode.txt");
    for (int k = 0; k < 250000 * 8; k++)//rgb编码输出
    {

        out_green << B[k];
        if ((k + 1) % 8 == 0)
        {
            out_green << "\n";
        }

    }
    out_green.close();
    ofstream out_blue("E:\\matin\\visual studio projects\\turbo_decode\\blue_encode.txt");
    for (int k = 0; k < 250000 * 8; k++)//rgb编码输出
    {

        out_blue << C[k];
        if ((k + 1) % 8 == 0)
        {
            out_blue << "\n";
        }

    }
    out_blue.close();
    free(dataA);
    free(dataB);
    free(dataC);
    free(A);
    free(B);
    free(C);
}

