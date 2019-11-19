package edu.ucla.distefanolab.thyrosim.algorithm;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.IOException;
import java.util.Properties;
import org.apache.commons.math3.ode.FirstOrderDifferentialEquations;
import org.apache.commons.math3.ode.FirstOrderIntegrator;
import org.apache.commons.math3.ode.nonstiff.ClassicalRungeKuttaIntegrator;
import org.apache.commons.math3.ode.nonstiff.DormandPrince853Integrator;

public class Thyrosim implements FirstOrderDifferentialEquations
{

    private double p1,  p2,  p3,  p4,  p5,  p6,  p7,  p8,  p9,  p10;
    private double p11, p12, p13, p14, p15, p16, p17, p18, p19, p20;
    private double p21, p22, p23, p24, p25, p26, p27, p28, p29, p30;
    private double p31, p32, p33, p34, p35, p36, p37, p38, p39, p40;
    private double p41, p42, p43, p44, p45, p46, p47, p48;
    private double kdelay, u1, u4, d1, d2, d3, d4;

    // Functions that Java ODE solver needs
    // Declare parameters
    public Thyrosim(double dial1, double dial2, double dial3, double dial4,
                    double inf1,  double inf4,  String thysim)
    {
        u1 = inf1;  // Infusion into plasma T4
        u4 = inf4;  // Infusion into plasma T3
        d1 = dial1; // Dial values
        d2 = dial2;
        d3 = dial3;
        d4 = dial4;

        // Load properties
        Properties prop = new Properties();
        String paramsfile = "../config/" + thysim + ".params";
        InputStream pis = null;

        try {
            pis = new FileInputStream(paramsfile);
        } catch (FileNotFoundException ex) {
            System.out.println("File not found: " + paramsfile);
        }

        try {
            prop.load(pis);
        } catch (IOException io) {
            io.printStackTrace();
        }

        // Convert properties to double
        kdelay = Double.valueOf(prop.getProperty("kdelay"));
        p1  = Double.valueOf(prop.getProperty("p1"));
        p2  = Double.valueOf(prop.getProperty("p2"));
        p3  = Double.valueOf(prop.getProperty("p3"));
        p4  = Double.valueOf(prop.getProperty("p4"));
        p5  = Double.valueOf(prop.getProperty("p5"));
        p6  = Double.valueOf(prop.getProperty("p6"));
        p7  = Double.valueOf(prop.getProperty("p7"));
        p8  = Double.valueOf(prop.getProperty("p8"));
        p9  = Double.valueOf(prop.getProperty("p9"));
        p10 = Double.valueOf(prop.getProperty("p10"));
        p11 = Double.valueOf(prop.getProperty("p11"));
        p12 = Double.valueOf(prop.getProperty("p12"));
        p13 = Double.valueOf(prop.getProperty("p13"));
        p14 = Double.valueOf(prop.getProperty("p14"));
        p15 = Double.valueOf(prop.getProperty("p15"));
        p16 = Double.valueOf(prop.getProperty("p16"));
        p17 = Double.valueOf(prop.getProperty("p17"));
        p18 = Double.valueOf(prop.getProperty("p18"));
        p19 = Double.valueOf(prop.getProperty("p19"));
        p20 = Double.valueOf(prop.getProperty("p20"));
        p21 = Double.valueOf(prop.getProperty("p21"));
        p22 = Double.valueOf(prop.getProperty("p22"));
        p23 = Double.valueOf(prop.getProperty("p23"));
        p24 = Double.valueOf(prop.getProperty("p24"));
        p25 = Double.valueOf(prop.getProperty("p25"));
        p26 = Double.valueOf(prop.getProperty("p26"));
        p27 = Double.valueOf(prop.getProperty("p27"));
        p28 = Double.valueOf(prop.getProperty("p28"));
        p29 = Double.valueOf(prop.getProperty("p29"));
        p30 = Double.valueOf(prop.getProperty("p30"));
        p31 = Double.valueOf(prop.getProperty("p31"));
        p32 = Double.valueOf(prop.getProperty("p32"));
        p33 = Double.valueOf(prop.getProperty("p33"));
        p34 = Double.valueOf(prop.getProperty("p34"));
        p35 = Double.valueOf(prop.getProperty("p35"));
        p36 = Double.valueOf(prop.getProperty("p36"));
        p37 = Double.valueOf(prop.getProperty("p37"));
        p38 = Double.valueOf(prop.getProperty("p38"));
        p39 = Double.valueOf(prop.getProperty("p39"));
        p40 = Double.valueOf(prop.getProperty("p40"));
        p41 = Double.valueOf(prop.getProperty("p41"));
        p42 = Double.valueOf(prop.getProperty("p42"));
        p43 = Double.valueOf(prop.getProperty("p43"));
        p44 = Double.valueOf(prop.getProperty("p44"));
        p45 = Double.valueOf(prop.getProperty("p45"));
        p46 = Double.valueOf(prop.getProperty("p46"));
        p47 = Double.valueOf(prop.getProperty("p47"));
        p48 = Double.valueOf(prop.getProperty("p48"));

        // Post prop load modification
        p44 = p44 * d2;
        p46 = p46 * d4;
    }

    public int getDimension()
    {
        return 19;
        //return 21;
    }

    public void computeDerivatives(double t, double[] q, double[] qDot)
    {
        double q4F, q1F, SR3, SR4, fCIRC, SRTSH, fdegTSH, fLAG, f4, NL;

// Auxillary equations
q1F = (p7 +p8 *q[0]+p9 *Math.pow(q[0],2)+p10*Math.pow(q[0],3))*q[0]; // FT4p
q4F = (p24+p25*q[0]+p26*Math.pow(q[0],2)+p27*Math.pow(q[0],3))*q[3]; // FT3p
SR3 = (p19*q[18])*d3; // Brain delay
SR4 = (p1 *q[18])*d1; // Brain delay
fCIRC = 1+(p32/(p31*Math.exp(-q[8]))-1)*(1/(1+Math.exp(10*q[8]-55)));
SRTSH = (p30+p31*fCIRC*Math.sin(Math.PI/12*t-p33))*Math.exp(-q[8]);
fdegTSH = p34+p35/(p36+q[6]);
fLAG = p41+2*Math.pow(q[7],11)/(Math.pow(p42,11)+Math.pow(q[7],11));
f4 = p37+5*p37/(1+Math.exp(2*q[7]-7));
NL = p13/(p14+q[1]);

// ODEs
qDot[0] = SR4+p3*q[1]+p4*q[2]-(p5+p6)*q1F+p11*q[10]+u1;         // T4dot
qDot[1] = p6*q1F-(p3+p12+NL)*q[1];                              // T4fast
qDot[2] = p5*q1F-(p4+p15/(p16+q[2])+p17/(p18+q[2]))*q[2];       // T4slow
qDot[3] = SR3+p20*q[4]+p21*q[5]-(p22+p23)*q4F+p28*q[12]+u4;     // T3pdot
qDot[4] = p23*q4F+NL*q[1]-(p20+p29)*q[4];                       // T3fast
qDot[5] = p22*q4F+p15*q[2]/(p16+q[2])+p17*q[2]/(p18+q[2])-p21*q[5];// T3slow
qDot[6] = SRTSH-fdegTSH*q[6];                                   // TSHp
qDot[7] = f4/p38*q[0]+p37/p39*q[3]-p40*q[7];                    // T3B
qDot[8] = fLAG*(q[7]-q[8]);                                     // T3B LAG
qDot[9] = -p43*q[9];                                            // T4PILLdot
qDot[10]=  p43*q[9]-(p44+p11)*q[10];                            // T4GUTdot
qDot[11]= -p45*q[11];                                           // T3PILLdot
qDot[12]=  p45*q[11]-(p46+p28)*q[12];                           // T3GUTdot

// Delay ODEs
qDot[13] = -kdelay*q[13] +q[6];                                 // delay1
qDot[14] = kdelay*(q[13] -q[14]);                               // delay2
qDot[15] = kdelay*(q[14] -q[15]);                               // delay3
qDot[16] = kdelay*(q[15] -q[16]);                               // delay4
qDot[17] = kdelay*(q[16] -q[17]);                               // delay5
qDot[18] = kdelay*(q[17] -q[18]);                               // delay6

// Additional values
//qDot[19] = q1F; // FT4p
//qDot[20] = q4F; // FT3p
    }

    public static void main(String[] args)
    {
        double IC1   = Double.parseDouble(args[0]);
        double IC2   = Double.parseDouble(args[1]);
        double IC3   = Double.parseDouble(args[2]);
        double IC4   = Double.parseDouble(args[3]);
        double IC5   = Double.parseDouble(args[4]);
        double IC6   = Double.parseDouble(args[5]);
        double IC7   = Double.parseDouble(args[6]);
        double IC8   = Double.parseDouble(args[7]);
        double IC9   = Double.parseDouble(args[8]);
        double IC10  = Double.parseDouble(args[9]);
        double IC11  = Double.parseDouble(args[10]);
        double IC12  = Double.parseDouble(args[11]);
        double IC13  = Double.parseDouble(args[12]);
        double IC14  = Double.parseDouble(args[13]);
        double IC15  = Double.parseDouble(args[14]);
        double IC16  = Double.parseDouble(args[15]);
        double IC17  = Double.parseDouble(args[16]);
        double IC18  = Double.parseDouble(args[17]);
        double IC19  = Double.parseDouble(args[18]);
        double t1d   = Double.parseDouble(args[19]);
        double t2d   = Double.parseDouble(args[20]);
        double dial1 = Double.parseDouble(args[21]);
        double dial2 = Double.parseDouble(args[22]);
        double dial3 = Double.parseDouble(args[23]);
        double dial4 = Double.parseDouble(args[24]);
        double inf1  = Double.parseDouble(args[25]);
        double inf4  = Double.parseDouble(args[26]);
        String thysim = args[27];

        FirstOrderIntegrator integrator = new DormandPrince853Integrator(1.0e-8,100.0,1.0e-10,1.0e-10);
        // FirstOrderIntegrator integrator = new GraggBulirschStoerIntegrator(1.0e-8, 100.0, 1.0e-10, 1.0e-10);

        // Initial state
        double[] q = new double[] {IC1, IC2, IC3, IC4, IC5, IC6,
                                   IC7, IC8, IC9, IC10,IC11,IC12,
                                   IC13,IC14,IC15,IC16,IC17,IC18,IC19};
                                   //IC13,IC14,IC15,IC16,IC17,IC18,IC19,0,0};
        Thyrosim ode = new Thyrosim(dial1,dial2,dial3,dial4,inf1,inf4,thysim);

        int t1 = (int)Math.round(t1d);
        int t2 = (int)Math.round(t2d);

        // The below uses the same numbering system as Octave thyrosim.m
        double[] q1  = new double[t2 - t1 + 1];
        double[] q2  = new double[t2 - t1 + 1];
        double[] q3  = new double[t2 - t1 + 1];
        double[] q4  = new double[t2 - t1 + 1];
        double[] q5  = new double[t2 - t1 + 1];
        double[] q6  = new double[t2 - t1 + 1];
        double[] q7  = new double[t2 - t1 + 1];
        double[] q8  = new double[t2 - t1 + 1];
        double[] q9  = new double[t2 - t1 + 1];
        double[] q10 = new double[t2 - t1 + 1];
        double[] q11 = new double[t2 - t1 + 1];
        double[] q12 = new double[t2 - t1 + 1];
        double[] q13 = new double[t2 - t1 + 1];
        double[] q14 = new double[t2 - t1 + 1];
        double[] q15 = new double[t2 - t1 + 1];
        double[] q16 = new double[t2 - t1 + 1];
        double[] q17 = new double[t2 - t1 + 1];
        double[] q18 = new double[t2 - t1 + 1];
        double[] q19 = new double[t2 - t1 + 1];
        //double[] q20 = new double[t2 - t1 + 1]; // FT4p values
        //double[] q21 = new double[t2 - t1 + 1]; // FT3p values
        double[] ts  = new double[t2 - t1 + 1];
        double[] ft4 = new double[t2 - t1 + 1]; // FT4p values
        double[] ft3 = new double[t2 - t1 + 1]; // FT3p values
        for (int i = t1; i <= t2; i++) {
            q1[i]  = q[0];
            q2[i]  = q[1];
            q3[i]  = q[2];
            q4[i]  = q[3];
            q5[i]  = q[4];
            q6[i]  = q[5];
            q7[i]  = q[6];
            q8[i]  = q[7];
            q9[i]  = q[8];
            q10[i] = q[9];
            q11[i] = q[10];
            q12[i] = q[11];
            q13[i] = q[12];
            q14[i] = q[13];
            q15[i] = q[14];
            q16[i] = q[15];
            q17[i] = q[16];
            q18[i] = q[17];
            q19[i] = q[18];
            //q20[i] = q[19];
            //q21[i] = q[20];
            ts[i]  = i;

// Copy/paste equations from computeDerivatives
ft4[i] = (ode.p7 +ode.p8 *q[0]+ode.p9 *Math.pow(q[0],2)+ode.p10*Math.pow(q[0],3))*q[0]; // FT4p
ft3[i] = (ode.p24+ode.p25*q[0]+ode.p26*Math.pow(q[0],2)+ode.p27*Math.pow(q[0],3))*q[3]; // FT3p

            integrator.integrate(ode,i,q,i+1,q);
        }

        System.out.println("START_q1_START");
        printArray(q1);
        System.out.println("END_q1_END");

        System.out.println("START_q2_START");
        printArray(q2);
        System.out.println("END_q2_END");

        System.out.println("START_q3_START");
        printArray(q3);
        System.out.println("END_q3_END");

        System.out.println("START_q4_START");
        printArray(q4);
        System.out.println("END_q4_END");

        System.out.println("START_q5_START");
        printArray(q5);
        System.out.println("END_q5_END");

        System.out.println("START_q6_START");
        printArray(q6);
        System.out.println("END_q6_END");

        System.out.println("START_q7_START");
        printArray(q7);
        System.out.println("END_q7_END");

        System.out.println("START_q8_START");
        printArray(q8);
        System.out.println("END_q8_END");

        System.out.println("START_q9_START");
        printArray(q9);
        System.out.println("END_q9_END");

        System.out.println("START_q10_START");
        printArray(q10);
        System.out.println("END_q10_END");

        System.out.println("START_q11_START");
        printArray(q11);
        System.out.println("END_q11_END");

        System.out.println("START_q12_START");
        printArray(q12);
        System.out.println("END_q12_END");

        System.out.println("START_q13_START");
        printArray(q13);
        System.out.println("END_q13_END");

        System.out.println("START_q14_START");
        printArray(q14);
        System.out.println("END_q14_END");

        System.out.println("START_q15_START");
        printArray(q15);
        System.out.println("END_q15_END");

        System.out.println("START_q16_START");
        printArray(q16);
        System.out.println("END_q16_END");

        System.out.println("START_q17_START");
        printArray(q17);
        System.out.println("END_q17_END");

        System.out.println("START_q18_START");
        printArray(q18);
        System.out.println("END_q18_END");

        System.out.println("START_q19_START");
        printArray(q19);
        System.out.println("END_q19_END");

//--------------------------------------------------
//         System.out.println("START_q20_START");
//         printArray(q20);
//         System.out.println("END_q20_END");
// 
//         System.out.println("START_q21_START");
//         printArray(q21);
//         System.out.println("END_q21_END");
//-------------------------------------------------- 

        System.out.println("START_t_START");
        printArray(ts);
        System.out.println("END_t_END");

        System.out.println("START_ft4_START");
        printArray(ft4);
        System.out.println("END_ft4_END");

        System.out.println("START_ft3_START");
        printArray(ft3);
        System.out.println("END_ft3_END");

    }

    public static void printArray(double[] arr)
    {
        for (int i = 0; i < arr.length; i++) {
            System.out.println(arr[i]);
        }
    }
}
