/*
 * brdemo_autotrans_data.c
 *
 * Code generation for model "brdemo_autotrans".
 *
 * Model version              : 1.277
 * Simulink Coder version : 8.9 (R2015b) 13-Aug-2015
 * C source code generated on : Tue Nov 14 14:05:09 2017
 *
 * Target selection: grt.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: 32-bit Generic
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "brdemo_autotrans.h"
#include "brdemo_autotrans_private.h"

/* Block parameters (auto storage) */
P_brdemo_autotrans_T brdemo_autotrans_P = {
  12.094147857312473,                  /* Mask Parameter: Vehicle_Iv
                                        * Referenced by: '<S5>/Vehicle Inertia'
                                        */

  /*  Mask Parameter: TorqueConverter_Kfactor
   * Referenced by: '<S6>/FactorK'
   */
  { 137.4652089938063, 137.06501915685197, 135.86444964598905,
    135.66435472751189, 137.56525645304487, 140.36658531172509,
    145.26891081441539, 152.87251771654735, 162.97731109964374,
    164.2779280697452, 166.17882979527823, 167.97968406157264,
    170.08068070558275, 172.78196210502438, 175.38319604522741,
    179.58518933324765, 183.58708770279083, 189.89007763482121,
    197.69377945543027, 215.90241703685155, 244.51599037908485 },
  0.0,                                 /* Mask Parameter: Vehicle_N20
                                        * Referenced by: '<S5>/Wheel Speed'
                                        */
  3.23,                                /* Mask Parameter: Vehicle_Rfd
                                        * Referenced by:
                                        *   '<S5>/Final Drive Ratio1'
                                        *   '<S5>/FinalDriveRatio2'
                                        *   '<S5>/Wheel Speed'
                                        */
  1.0,                                 /* Mask Parameter: Vehicle_Rw
                                        * Referenced by: '<S5>/LinearSpeed'
                                        */

  /*  Mask Parameter: TorqueConverter_Torkratio
   * Referenced by: '<S6>/TorqueRatio'
   */
  { 2.2319999999999998, 2.075, 1.975, 1.8459999999999999, 1.72, 1.564, 1.409,
    1.254, 1.0959999999999999, 1.08, 1.061, 1.043, 1.028, 1.012, 1.002, 1.002,
    1.001, 0.998, 0.99900000000000011, 1.001, 1.002 },

  /*  Mask Parameter: TorqueConverter_speedratio
   * Referenced by:
   *   '<S6>/FactorK'
   *   '<S6>/TorqueRatio'
   */
  { 0.0, 0.1, 0.2, 0.30000000000000004, 0.4, 0.5, 0.60000000000000009,
    0.70000000000000007, 0.8, 0.81, 0.82000000000000006, 0.83000000000000007,
    0.84, 0.85, 0.86, 0.87, 0.88, 0.89, 0.9, 0.92, 0.94 },

  /*  Expression: downth
   * Referenced by: '<S3>/interp_down'
   */
  { 0.0, 5.0, 40.0, 50.0, 90.0, 100.0 },

  /*  Expression: [1:4]
   * Referenced by: '<S3>/interp_down'
   */
  { 1.0, 2.0, 3.0, 4.0 },

  /*  Expression: downtab
   * Referenced by: '<S3>/interp_down'
   */
  { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 5.0, 5.0, 5.0, 30.0, 30.0, 20.0, 20.0,
    25.0, 30.0, 50.0, 50.0, 35.0, 35.0, 40.0, 50.0, 80.0, 80.0 },

  /*  Expression: upth
   * Referenced by: '<S3>/interp_up'
   */
  { 0.0, 25.0, 35.0, 50.0, 90.0, 100.0 },

  /*  Expression: [1:4]
   * Referenced by: '<S3>/interp_up'
   */
  { 1.0, 2.0, 3.0, 4.0 },

  /*  Expression: uptab
   * Referenced by: '<S3>/interp_up'
   */
  { 10.0, 10.0, 15.0, 23.0, 40.0, 40.0, 30.0, 30.0, 30.0, 41.0, 70.0, 70.0, 50.0,
    50.0, 50.0, 60.0, 100.0, 100.0, 1.0E+6, 1.0E+6, 1.0E+6, 1.0E+6, 1.0E+6,
    1.0E+6 },
  2.0,                                 /* Expression: TWAIT
                                        * Referenced by: '<Root>/ShiftLogic'
                                        */
  0.011363636363636364,                /* Expression: 60/5280
                                        * Referenced by: '<S5>/mph'
                                        */
  1000.0,                              /* Expression: 1000
                                        * Referenced by: '<S1>/Integrator'
                                        */
  6000.0,                              /* Expression: 6000
                                        * Referenced by: '<S1>/Integrator'
                                        */
  600.0,                               /* Expression: 600
                                        * Referenced by: '<S1>/Integrator'
                                        */

  /*  Expression: thvec
   * Referenced by: '<S1>/EngineTorque'
   */
  { 0.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0 },

  /*  Expression: nevec
   * Referenced by: '<S1>/EngineTorque'
   */
  { 799.99999999999989, 1200.0, 1599.9999999999998, 1999.9999999999998, 2400.0,
    2800.0000000000005, 3199.9999999999995, 3599.9999999999995,
    3999.9999999999995, 4400.0, 4800.0 },

  /*  Expression: emap
   * Referenced by: '<S1>/EngineTorque'
   */
  { -40.0, 215.0, 245.0, 264.0, 264.0, 267.0, 267.0, 267.0, 267.0, 267.0, -44.0,
    117.0, 208.0, 260.0, 279.0, 290.0, 297.0, 301.0, 301.0, 301.0, -49.0, 85.0,
    178.0, 241.0, 282.0, 293.0, 305.0, 308.0, 312.0, 312.0, -53.0, 66.0, 148.0,
    219.0, 275.0, 297.0, 305.0, 312.0, 319.0, 319.0, -57.0, 44.0, 122.0, 193.0,
    260.0, 290.0, 305.0, 319.0, 327.0, 327.0, -61.0, 29.0, 104.0, 167.0, 238.0,
    275.0, 301.0, 323.0, 327.0, 334.0, -65.0, 10.0, 85.0, 152.0, 223.0, 260.0,
    293.0, 319.0, 327.0, 334.0, -70.0, -2.0, 66.0, 133.0, 208.0, 256.0, 282.0,
    316.0, 327.0, 334.0, -74.0, -13.0, 48.0, 119.0, 189.0, 234.0, 267.0, 297.0,
    312.0, 319.0, -78.0, -22.0, 33.0, 96.0, 171.0, 212.0, 249.0, 279.0, 293.0,
    305.0, -82.0, -32.0, 18.0, 85.0, 152.0, 193.0, 226.0, 253.0, 267.0, 275.0 },

  /*  Expression: [1 2 3 4]
   * Referenced by: '<S7>/Look-Up Table'
   */
  { 1.0, 2.0, 3.0, 4.0 },

  /*  Expression: [2.393 1.450 1.000 0.677]
   * Referenced by: '<S7>/Look-Up Table'
   */
  { 2.393, 1.45, 1.0, 0.677 },
  45.472138452209627                   /* Expression: 1/Iei
                                        * Referenced by: '<S1>/engine + impeller inertia'
                                        */
};
