/*
 * brdemo_autotrans.c
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

/* Named constants for Chart: '<Root>/ShiftLogic' */
#define brdemo_autot_IN_NO_ACTIVE_CHILD ((uint8_T)0U)
#define brdemo_autotran_IN_downshifting ((uint8_T)1U)
#define brdemo_autotran_IN_steady_state ((uint8_T)2U)
#define brdemo_autotrans_CALL_EVENT    (-1)
#define brdemo_autotrans_IN_first      ((uint8_T)1U)
#define brdemo_autotrans_IN_fourth     ((uint8_T)2U)
#define brdemo_autotrans_IN_second     ((uint8_T)3U)
#define brdemo_autotrans_IN_third      ((uint8_T)4U)
#define brdemo_autotrans_IN_upshifting ((uint8_T)3U)
#define brdemo_autotrans_event_DOWN    (0)
#define brdemo_autotrans_event_UP      (1)

/* Block signals (auto storage) */
B_brdemo_autotrans_T brdemo_autotrans_B;

/* Continuous states */
X_brdemo_autotrans_T brdemo_autotrans_X;

/* Block states (auto storage) */
DW_brdemo_autotrans_T brdemo_autotrans_DW;

/* External inputs (root inport signals with auto storage) */
ExtU_brdemo_autotrans_T brdemo_autotrans_U;

/* External outputs (root outports fed by signals with auto storage) */
ExtY_brdemo_autotrans_T brdemo_autotrans_Y;

/* Real-time model */
RT_MODEL_brdemo_autotrans_T brdemo_autotrans_M_;
RT_MODEL_brdemo_autotrans_T *const brdemo_autotrans_M = &brdemo_autotrans_M_;

/* Forward declaration for local functions */
static void brdemo_autotrans_gear_state(void);
static void rate_scheduler(void);

/*
 *   This function updates active task flag for each subrate.
 * The function is called at model base rate, hence the
 * generated code self-manages all its subrates.
 */
static void rate_scheduler(void)
{
  /* Compute which subrates run during the next base time step.  Subrates
   * are an integer multiple of the base rate counter.  Therefore, the subtask
   * counter is reset when it reaches its limit (zero means run).
   */
  (brdemo_autotrans_M->Timing.TaskCounters.TID[2])++;
  if ((brdemo_autotrans_M->Timing.TaskCounters.TID[2]) > 3) {/* Sample time: [0.04s, 0.0s] */
    brdemo_autotrans_M->Timing.TaskCounters.TID[2] = 0;
  }

  brdemo_autotrans_M->Timing.sampleHits[2] =
    (brdemo_autotrans_M->Timing.TaskCounters.TID[2] == 0);
}

/*
 * This function updates continuous states using the ODE5 fixed-step
 * solver algorithm
 */
static void rt_ertODEUpdateContinuousStates(RTWSolverInfo *si )
{
  /* Solver Matrices */
  static const real_T rt_ODE5_A[6] = {
    1.0/5.0, 3.0/10.0, 4.0/5.0, 8.0/9.0, 1.0, 1.0
  };

  static const real_T rt_ODE5_B[6][6] = {
    { 1.0/5.0, 0.0, 0.0, 0.0, 0.0, 0.0 },

    { 3.0/40.0, 9.0/40.0, 0.0, 0.0, 0.0, 0.0 },

    { 44.0/45.0, -56.0/15.0, 32.0/9.0, 0.0, 0.0, 0.0 },

    { 19372.0/6561.0, -25360.0/2187.0, 64448.0/6561.0, -212.0/729.0, 0.0, 0.0 },

    { 9017.0/3168.0, -355.0/33.0, 46732.0/5247.0, 49.0/176.0, -5103.0/18656.0,
      0.0 },

    { 35.0/384.0, 0.0, 500.0/1113.0, 125.0/192.0, -2187.0/6784.0, 11.0/84.0 }
  };

  time_T t = rtsiGetT(si);
  time_T tnew = rtsiGetSolverStopTime(si);
  time_T h = rtsiGetStepSize(si);
  real_T *x = rtsiGetContStates(si);
  ODE5_IntgData *id = (ODE5_IntgData *)rtsiGetSolverData(si);
  real_T *y = id->y;
  real_T *f0 = id->f[0];
  real_T *f1 = id->f[1];
  real_T *f2 = id->f[2];
  real_T *f3 = id->f[3];
  real_T *f4 = id->f[4];
  real_T *f5 = id->f[5];
  real_T hB[6];
  int_T i;
  int_T nXc = 2;
  rtsiSetSimTimeStep(si,MINOR_TIME_STEP);

  /* Save the state values at time t in y, we'll use x as ynew. */
  (void) memcpy(y, x,
                (uint_T)nXc*sizeof(real_T));

  /* Assumes that rtsiSetT and ModelOutputs are up-to-date */
  /* f0 = f(t,y) */
  rtsiSetdX(si, f0);
  brdemo_autotrans_derivatives();

  /* f(:,2) = feval(odefile, t + hA(1), y + f*hB(:,1), args(:)(*)); */
  hB[0] = h * rt_ODE5_B[0][0];
  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0]);
  }

  rtsiSetT(si, t + h*rt_ODE5_A[0]);
  rtsiSetdX(si, f1);
  brdemo_autotrans_output();
  brdemo_autotrans_derivatives();

  /* f(:,3) = feval(odefile, t + hA(2), y + f*hB(:,2), args(:)(*)); */
  for (i = 0; i <= 1; i++) {
    hB[i] = h * rt_ODE5_B[1][i];
  }

  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0] + f1[i]*hB[1]);
  }

  rtsiSetT(si, t + h*rt_ODE5_A[1]);
  rtsiSetdX(si, f2);
  brdemo_autotrans_output();
  brdemo_autotrans_derivatives();

  /* f(:,4) = feval(odefile, t + hA(3), y + f*hB(:,3), args(:)(*)); */
  for (i = 0; i <= 2; i++) {
    hB[i] = h * rt_ODE5_B[2][i];
  }

  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0] + f1[i]*hB[1] + f2[i]*hB[2]);
  }

  rtsiSetT(si, t + h*rt_ODE5_A[2]);
  rtsiSetdX(si, f3);
  brdemo_autotrans_output();
  brdemo_autotrans_derivatives();

  /* f(:,5) = feval(odefile, t + hA(4), y + f*hB(:,4), args(:)(*)); */
  for (i = 0; i <= 3; i++) {
    hB[i] = h * rt_ODE5_B[3][i];
  }

  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0] + f1[i]*hB[1] + f2[i]*hB[2] +
                   f3[i]*hB[3]);
  }

  rtsiSetT(si, t + h*rt_ODE5_A[3]);
  rtsiSetdX(si, f4);
  brdemo_autotrans_output();
  brdemo_autotrans_derivatives();

  /* f(:,6) = feval(odefile, t + hA(5), y + f*hB(:,5), args(:)(*)); */
  for (i = 0; i <= 4; i++) {
    hB[i] = h * rt_ODE5_B[4][i];
  }

  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0] + f1[i]*hB[1] + f2[i]*hB[2] +
                   f3[i]*hB[3] + f4[i]*hB[4]);
  }

  rtsiSetT(si, tnew);
  rtsiSetdX(si, f5);
  brdemo_autotrans_output();
  brdemo_autotrans_derivatives();

  /* tnew = t + hA(6);
     ynew = y + f*hB(:,6); */
  for (i = 0; i <= 5; i++) {
    hB[i] = h * rt_ODE5_B[5][i];
  }

  for (i = 0; i < nXc; i++) {
    x[i] = y[i] + (f0[i]*hB[0] + f1[i]*hB[1] + f2[i]*hB[2] +
                   f3[i]*hB[3] + f4[i]*hB[4] + f5[i]*hB[5]);
  }

  rtsiSetSimTimeStep(si,MAJOR_TIME_STEP);
}

/* Function for Chart: '<Root>/ShiftLogic' */
static void brdemo_autotrans_gear_state(void)
{
  /* During 'gear_state': '<S2>:2' */
  switch (brdemo_autotrans_DW.is_gear_state) {
   case brdemo_autotrans_IN_first:
    /* During 'first': '<S2>:6' */
    if (brdemo_autotrans_DW.sfEvent == brdemo_autotrans_event_UP) {
      /* Transition: '<S2>:12' */
      brdemo_autotrans_DW.is_gear_state = brdemo_autotrans_IN_second;

      /* Entry 'second': '<S2>:4' */
      brdemo_autotrans_B.gear = 2.0;
    }
    break;

   case brdemo_autotrans_IN_fourth:
    /* During 'fourth': '<S2>:3' */
    if (brdemo_autotrans_DW.sfEvent == brdemo_autotrans_event_DOWN) {
      /* Transition: '<S2>:14' */
      brdemo_autotrans_DW.is_gear_state = brdemo_autotrans_IN_third;

      /* Entry 'third': '<S2>:5' */
      brdemo_autotrans_B.gear = 3.0;
    }
    break;

   case brdemo_autotrans_IN_second:
    /* During 'second': '<S2>:4' */
    if (brdemo_autotrans_DW.sfEvent == brdemo_autotrans_event_UP) {
      /* Transition: '<S2>:11' */
      brdemo_autotrans_DW.is_gear_state = brdemo_autotrans_IN_third;

      /* Entry 'third': '<S2>:5' */
      brdemo_autotrans_B.gear = 3.0;
    } else {
      if (brdemo_autotrans_DW.sfEvent == brdemo_autotrans_event_DOWN) {
        /* Transition: '<S2>:16' */
        brdemo_autotrans_DW.is_gear_state = brdemo_autotrans_IN_first;

        /* Entry 'first': '<S2>:6' */
        brdemo_autotrans_B.gear = 1.0;
      }
    }
    break;

   case brdemo_autotrans_IN_third:
    /* During 'third': '<S2>:5' */
    if (brdemo_autotrans_DW.sfEvent == brdemo_autotrans_event_UP) {
      /* Transition: '<S2>:10' */
      brdemo_autotrans_DW.is_gear_state = brdemo_autotrans_IN_fourth;

      /* Entry 'fourth': '<S2>:3' */
      brdemo_autotrans_B.gear = 4.0;
    } else {
      if (brdemo_autotrans_DW.sfEvent == brdemo_autotrans_event_DOWN) {
        /* Transition: '<S2>:15' */
        brdemo_autotrans_DW.is_gear_state = brdemo_autotrans_IN_second;

        /* Entry 'second': '<S2>:4' */
        brdemo_autotrans_B.gear = 2.0;
      }
    }
    break;

   default:
    /* Unreachable state, for coverage only */
    brdemo_autotrans_DW.is_gear_state = brdemo_autot_IN_NO_ACTIVE_CHILD;
    break;
  }
}

real_T rt_powd_snf(real_T u0, real_T u1)
{
  real_T y;
  real_T tmp;
  real_T tmp_0;
  if (rtIsNaN(u0) || rtIsNaN(u1)) {
    y = (rtNaN);
  } else {
    tmp = fabs(u0);
    tmp_0 = fabs(u1);
    if (rtIsInf(u1)) {
      if (tmp == 1.0) {
        y = (rtNaN);
      } else if (tmp > 1.0) {
        if (u1 > 0.0) {
          y = (rtInf);
        } else {
          y = 0.0;
        }
      } else if (u1 > 0.0) {
        y = 0.0;
      } else {
        y = (rtInf);
      }
    } else if (tmp_0 == 0.0) {
      y = 1.0;
    } else if (tmp_0 == 1.0) {
      if (u1 > 0.0) {
        y = u0;
      } else {
        y = 1.0 / u0;
      }
    } else if (u1 == 2.0) {
      y = u0 * u0;
    } else if ((u1 == 0.5) && (u0 >= 0.0)) {
      y = sqrt(u0);
    } else if ((u0 < 0.0) && (u1 > floor(u1))) {
      y = (rtNaN);
    } else {
      y = pow(u0, u1);
    }
  }

  return y;
}

/* Model output function */
void brdemo_autotrans_output(void)
{
  int32_T b_previousEvent;
  real_T interp_down;
  real_T interp_up;
  if (rtmIsMajorTimeStep(brdemo_autotrans_M)) {
    /* set solver stop time */
    if (!(brdemo_autotrans_M->Timing.clockTick0+1)) {
      rtsiSetSolverStopTime(&brdemo_autotrans_M->solverInfo,
                            ((brdemo_autotrans_M->Timing.clockTickH0 + 1) *
        brdemo_autotrans_M->Timing.stepSize0 * 4294967296.0));
    } else {
      rtsiSetSolverStopTime(&brdemo_autotrans_M->solverInfo,
                            ((brdemo_autotrans_M->Timing.clockTick0 + 1) *
        brdemo_autotrans_M->Timing.stepSize0 +
        brdemo_autotrans_M->Timing.clockTickH0 *
        brdemo_autotrans_M->Timing.stepSize0 * 4294967296.0));
    }
  }                                    /* end MajorTimeStep */

  /* Update absolute time of base rate at minor time step */
  if (rtmIsMinorTimeStep(brdemo_autotrans_M)) {
    brdemo_autotrans_M->Timing.t[0] = rtsiGetT(&brdemo_autotrans_M->solverInfo);
  }

  /* Gain: '<S5>/mph' incorporates:
   *  Gain: '<S5>/LinearSpeed'
   *  Integrator: '<S5>/Wheel Speed'
   */
  brdemo_autotrans_B.VehicleSpeed = 6.2831853071795862 *
    brdemo_autotrans_P.Vehicle_Rw * brdemo_autotrans_X.WheelSpeed_CSTATE *
    brdemo_autotrans_P.mph_Gain;

  /* Outport: '<Root>/speed' */
  brdemo_autotrans_Y.speed = brdemo_autotrans_B.VehicleSpeed;

  /* Integrator: '<S1>/Integrator' */
  /* Limited  Integrator  */
  if (brdemo_autotrans_X.Integrator_CSTATE >=
      brdemo_autotrans_P.Integrator_UpperSat) {
    brdemo_autotrans_X.Integrator_CSTATE =
      brdemo_autotrans_P.Integrator_UpperSat;
  } else {
    if (brdemo_autotrans_X.Integrator_CSTATE <=
        brdemo_autotrans_P.Integrator_LowerSat) {
      brdemo_autotrans_X.Integrator_CSTATE =
        brdemo_autotrans_P.Integrator_LowerSat;
    }
  }

  brdemo_autotrans_B.RPM = brdemo_autotrans_X.Integrator_CSTATE;

  /* End of Integrator: '<S1>/Integrator' */

  /* Outport: '<Root>/RPM' */
  brdemo_autotrans_Y.RPM = brdemo_autotrans_B.RPM;
  if (rtmIsMajorTimeStep(brdemo_autotrans_M) &&
      brdemo_autotrans_M->Timing.TaskCounters.TID[2] == 0) {
    /* Chart: '<Root>/ShiftLogic' */
    /* Gateway: ShiftLogic */
    brdemo_autotrans_DW.sfEvent = brdemo_autotrans_CALL_EVENT;
    if (brdemo_autotrans_DW.temporalCounter_i1 < MAX_uint32_T) {
      brdemo_autotrans_DW.temporalCounter_i1++;
    }

    /* During: ShiftLogic */
    if (brdemo_autotrans_DW.is_active_c1_brdemo_autotrans == 0U) {
      /* Entry: ShiftLogic */
      brdemo_autotrans_DW.is_active_c1_brdemo_autotrans = 1U;

      /* Entry Internal: ShiftLogic */
      brdemo_autotrans_DW.is_active_gear_state = 1U;

      /* Entry Internal 'gear_state': '<S2>:2' */
      /* Transition: '<S2>:13' */
      if (brdemo_autotrans_DW.is_gear_state != brdemo_autotrans_IN_first) {
        brdemo_autotrans_DW.is_gear_state = brdemo_autotrans_IN_first;

        /* Entry 'first': '<S2>:6' */
        brdemo_autotrans_B.gear = 1.0;
      }

      brdemo_autotrans_DW.is_active_selection_state = 1U;

      /* Entry Internal 'selection_state': '<S2>:7' */
      /* Transition: '<S2>:17' */
      brdemo_autotrans_DW.is_selection_state = brdemo_autotran_IN_steady_state;
    } else {
      if (brdemo_autotrans_DW.is_active_gear_state != 0U) {
        brdemo_autotrans_gear_state();
      }

      if (brdemo_autotrans_DW.is_active_selection_state != 0U) {
        /* Outputs for Function Call SubSystem: '<Root>/ThresholdCalculation' */
        /* Lookup2D: '<S3>/interp_down' incorporates:
         *  Inport: '<Root>/throttle'
         */
        /* During 'selection_state': '<S2>:7' */
        /* Event: '<S2>:29' */
        interp_down = rt_Lookup2D_Normal(brdemo_autotrans_P.interp_down_RowIdx,
          6, brdemo_autotrans_P.interp_down_ColIdx, 4,
          brdemo_autotrans_P.interp_down_Table, brdemo_autotrans_U.throttle,
          brdemo_autotrans_B.gear);

        /* Lookup2D: '<S3>/interp_up' incorporates:
         *  Inport: '<Root>/throttle'
         */
        interp_up = rt_Lookup2D_Normal(brdemo_autotrans_P.interp_up_RowIdx, 6,
          brdemo_autotrans_P.interp_up_ColIdx, 4,
          brdemo_autotrans_P.interp_up_Table, brdemo_autotrans_U.throttle,
          brdemo_autotrans_B.gear);

        /* End of Outputs for SubSystem: '<Root>/ThresholdCalculation' */
        switch (brdemo_autotrans_DW.is_selection_state) {
         case brdemo_autotran_IN_downshifting:
          /* During 'downshifting': '<S2>:1' */
          if ((brdemo_autotrans_DW.sfEvent == brdemo_autotrans_CALL_EVENT) &&
              (brdemo_autotrans_DW.temporalCounter_i1 >= (uint32_T)
               brdemo_autotrans_P.ShiftLogic_TWAIT) &&
              (brdemo_autotrans_B.VehicleSpeed <= interp_down)) {
            /* Transition: '<S2>:22' */
            /* Event: '<S2>:30' */
            b_previousEvent = brdemo_autotrans_DW.sfEvent;
            brdemo_autotrans_DW.sfEvent = brdemo_autotrans_event_DOWN;
            if (brdemo_autotrans_DW.is_active_gear_state != 0U) {
              brdemo_autotrans_gear_state();
            }

            brdemo_autotrans_DW.sfEvent = b_previousEvent;
            brdemo_autotrans_DW.is_selection_state =
              brdemo_autotran_IN_steady_state;
          } else {
            if (brdemo_autotrans_B.VehicleSpeed > interp_down) {
              /* Transition: '<S2>:21' */
              brdemo_autotrans_DW.is_selection_state =
                brdemo_autotran_IN_steady_state;
            }
          }
          break;

         case brdemo_autotran_IN_steady_state:
          /* During 'steady_state': '<S2>:9' */
          if (brdemo_autotrans_B.VehicleSpeed > interp_up) {
            /* Transition: '<S2>:18' */
            brdemo_autotrans_DW.is_selection_state =
              brdemo_autotrans_IN_upshifting;
            brdemo_autotrans_DW.temporalCounter_i1 = 0U;
          } else {
            if (brdemo_autotrans_B.VehicleSpeed < interp_down) {
              /* Transition: '<S2>:19' */
              brdemo_autotrans_DW.is_selection_state =
                brdemo_autotran_IN_downshifting;
              brdemo_autotrans_DW.temporalCounter_i1 = 0U;
            }
          }
          break;

         case brdemo_autotrans_IN_upshifting:
          /* During 'upshifting': '<S2>:8' */
          if ((brdemo_autotrans_DW.sfEvent == brdemo_autotrans_CALL_EVENT) &&
              (brdemo_autotrans_DW.temporalCounter_i1 >= (uint32_T)
               brdemo_autotrans_P.ShiftLogic_TWAIT) &&
              (brdemo_autotrans_B.VehicleSpeed >= interp_up)) {
            /* Transition: '<S2>:23' */
            /* Event: '<S2>:31' */
            b_previousEvent = brdemo_autotrans_DW.sfEvent;
            brdemo_autotrans_DW.sfEvent = brdemo_autotrans_event_UP;
            if (brdemo_autotrans_DW.is_active_gear_state != 0U) {
              brdemo_autotrans_gear_state();
            }

            brdemo_autotrans_DW.sfEvent = b_previousEvent;
            brdemo_autotrans_DW.is_selection_state =
              brdemo_autotran_IN_steady_state;
          } else {
            if (brdemo_autotrans_B.VehicleSpeed < interp_up) {
              /* Transition: '<S2>:20' */
              brdemo_autotrans_DW.is_selection_state =
                brdemo_autotran_IN_steady_state;
            }
          }
          break;

         default:
          /* Unreachable state, for coverage only */
          brdemo_autotrans_DW.is_selection_state =
            brdemo_autot_IN_NO_ACTIVE_CHILD;
          break;
        }
      }
    }

    /* End of Chart: '<Root>/ShiftLogic' */

    /* Outport: '<Root>/gear' */
    brdemo_autotrans_Y.gear = brdemo_autotrans_B.gear;
  }

  if (rtmIsMajorTimeStep(brdemo_autotrans_M) &&
      brdemo_autotrans_M->Timing.TaskCounters.TID[1] == 0) {
  }

  if (rtmIsMajorTimeStep(brdemo_autotrans_M) &&
      brdemo_autotrans_M->Timing.TaskCounters.TID[2] == 0) {
    /* Lookup: '<S7>/Look-Up Table' */
    brdemo_autotrans_B.LookUpTable = rt_Lookup
      (brdemo_autotrans_P.LookUpTable_XData, 4, brdemo_autotrans_B.gear,
       brdemo_autotrans_P.LookUpTable_YData);
  }

  /* Gain: '<S5>/FinalDriveRatio2' incorporates:
   *  Integrator: '<S5>/Wheel Speed'
   */
  brdemo_autotrans_B.TransmissionRPM = brdemo_autotrans_P.Vehicle_Rfd *
    brdemo_autotrans_X.WheelSpeed_CSTATE;

  /* Product: '<S6>/SpeedRatio' incorporates:
   *  Product: '<S7>/Product1'
   */
  interp_down = brdemo_autotrans_B.LookUpTable *
    brdemo_autotrans_B.TransmissionRPM / brdemo_autotrans_B.RPM;

  /* Product: '<S6>/Quotient' incorporates:
   *  Lookup: '<S6>/FactorK'
   */
  interp_up = brdemo_autotrans_B.RPM / rt_Lookup
    (brdemo_autotrans_P.TorqueConverter_speedratio, 21, interp_down,
     brdemo_autotrans_P.TorqueConverter_Kfactor);

  /* Fcn: '<S6>/Impeller' */
  interp_up = rt_powd_snf(interp_up, 2.0);

  /* Gain: '<S1>/engine + impeller inertia' incorporates:
   *  Fcn: '<S6>/Impeller'
   *  Inport: '<Root>/throttle'
   *  Lookup2D: '<S1>/EngineTorque'
   *  Sum: '<S1>/Sum'
   */
  brdemo_autotrans_B.engineimpellerinertia = (rt_Lookup2D_Normal
    (brdemo_autotrans_P.EngineTorque_RowIdx, 10,
     brdemo_autotrans_P.EngineTorque_ColIdx, 11,
     brdemo_autotrans_P.EngineTorque_Table, brdemo_autotrans_U.throttle,
     brdemo_autotrans_B.RPM) - interp_up) *
    brdemo_autotrans_P.engineimpellerinertia_Gain;

  /* Product: '<S7>/Product' incorporates:
   *  Fcn: '<S6>/Impeller'
   *  Lookup: '<S6>/TorqueRatio'
   *  Product: '<S6>/Turbine'
   */
  brdemo_autotrans_B.OutputTorque = interp_up * rt_Lookup
    (brdemo_autotrans_P.TorqueConverter_speedratio, 21, interp_down,
     brdemo_autotrans_P.TorqueConverter_Torkratio) *
    brdemo_autotrans_B.LookUpTable;

  /* Signum: '<S5>/Sign' */
  if (brdemo_autotrans_B.VehicleSpeed < 0.0) {
    interp_down = -1.0;
  } else if (brdemo_autotrans_B.VehicleSpeed > 0.0) {
    interp_down = 1.0;
  } else if (brdemo_autotrans_B.VehicleSpeed == 0.0) {
    interp_down = 0.0;
  } else {
    interp_down = brdemo_autotrans_B.VehicleSpeed;
  }

  /* Gain: '<S5>/Vehicle Inertia' incorporates:
   *  Fcn: '<S5>/RoadLoad'
   *  Gain: '<S5>/Final Drive Ratio1'
   *  Inport: '<Root>/brake'
   *  Product: '<S5>/SignedLoad'
   *  Signum: '<S5>/Sign'
   *  Sum: '<S5>/Sum'
   *  Sum: '<S5>/Sum1'
   */
  brdemo_autotrans_B.VehicleInertia = (brdemo_autotrans_P.Vehicle_Rfd *
    brdemo_autotrans_B.OutputTorque - ((0.02 * rt_powd_snf
    (brdemo_autotrans_B.VehicleSpeed, 2.0) + 40.0) + brdemo_autotrans_U.brake) *
    interp_down) * (1.0 / brdemo_autotrans_P.Vehicle_Iv);
}

/* Model update function */
void brdemo_autotrans_update(void)
{
  if (rtmIsMajorTimeStep(brdemo_autotrans_M)) {
    rt_ertODEUpdateContinuousStates(&brdemo_autotrans_M->solverInfo);
  }

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++brdemo_autotrans_M->Timing.clockTick0)) {
    ++brdemo_autotrans_M->Timing.clockTickH0;
  }

  brdemo_autotrans_M->Timing.t[0] = rtsiGetSolverStopTime
    (&brdemo_autotrans_M->solverInfo);

  {
    /* Update absolute timer for sample time: [0.01s, 0.0s] */
    /* The "clockTick1" counts the number of times the code of this task has
     * been executed. The absolute time is the multiplication of "clockTick1"
     * and "Timing.stepSize1". Size of "clockTick1" ensures timer will not
     * overflow during the application lifespan selected.
     * Timer of this task consists of two 32 bit unsigned integers.
     * The two integers represent the low bits Timing.clockTick1 and the high bits
     * Timing.clockTickH1. When the low bit overflows to 0, the high bits increment.
     */
    if (!(++brdemo_autotrans_M->Timing.clockTick1)) {
      ++brdemo_autotrans_M->Timing.clockTickH1;
    }

    brdemo_autotrans_M->Timing.t[1] = brdemo_autotrans_M->Timing.clockTick1 *
      brdemo_autotrans_M->Timing.stepSize1 +
      brdemo_autotrans_M->Timing.clockTickH1 *
      brdemo_autotrans_M->Timing.stepSize1 * 4294967296.0;
  }

  if (rtmIsMajorTimeStep(brdemo_autotrans_M) &&
      brdemo_autotrans_M->Timing.TaskCounters.TID[2] == 0) {
    /* Update absolute timer for sample time: [0.04s, 0.0s] */
    /* The "clockTick2" counts the number of times the code of this task has
     * been executed. The absolute time is the multiplication of "clockTick2"
     * and "Timing.stepSize2". Size of "clockTick2" ensures timer will not
     * overflow during the application lifespan selected.
     * Timer of this task consists of two 32 bit unsigned integers.
     * The two integers represent the low bits Timing.clockTick2 and the high bits
     * Timing.clockTickH2. When the low bit overflows to 0, the high bits increment.
     */
    if (!(++brdemo_autotrans_M->Timing.clockTick2)) {
      ++brdemo_autotrans_M->Timing.clockTickH2;
    }

    brdemo_autotrans_M->Timing.t[2] = brdemo_autotrans_M->Timing.clockTick2 *
      brdemo_autotrans_M->Timing.stepSize2 +
      brdemo_autotrans_M->Timing.clockTickH2 *
      brdemo_autotrans_M->Timing.stepSize2 * 4294967296.0;
  }

  rate_scheduler();
}

/* Derivatives for root system: '<Root>' */
void brdemo_autotrans_derivatives(void)
{
  boolean_T lsat;
  boolean_T usat;
  XDot_brdemo_autotrans_T *_rtXdot;
  _rtXdot = ((XDot_brdemo_autotrans_T *) brdemo_autotrans_M->ModelData.derivs);

  /* Derivatives for Integrator: '<S5>/Wheel Speed' */
  _rtXdot->WheelSpeed_CSTATE = brdemo_autotrans_B.VehicleInertia;

  /* Derivatives for Integrator: '<S1>/Integrator' */
  lsat = (brdemo_autotrans_X.Integrator_CSTATE <=
          brdemo_autotrans_P.Integrator_LowerSat);
  usat = (brdemo_autotrans_X.Integrator_CSTATE >=
          brdemo_autotrans_P.Integrator_UpperSat);
  if (((!lsat) && (!usat)) || (lsat && (brdemo_autotrans_B.engineimpellerinertia
        > 0.0)) || (usat && (brdemo_autotrans_B.engineimpellerinertia < 0.0))) {
    _rtXdot->Integrator_CSTATE = brdemo_autotrans_B.engineimpellerinertia;
  } else {
    /* in saturation */
    _rtXdot->Integrator_CSTATE = 0.0;
  }

  /* End of Derivatives for Integrator: '<S1>/Integrator' */
}

/* Model initialize function */
void brdemo_autotrans_initialize(void)
{
  /* InitializeConditions for Integrator: '<S5>/Wheel Speed' */
  brdemo_autotrans_X.WheelSpeed_CSTATE = brdemo_autotrans_P.Vehicle_N20 /
    brdemo_autotrans_P.Vehicle_Rfd;

  /* InitializeConditions for Integrator: '<S1>/Integrator' */
  brdemo_autotrans_X.Integrator_CSTATE = brdemo_autotrans_P.Integrator_IC;

  /* InitializeConditions for Chart: '<Root>/ShiftLogic' */
  brdemo_autotrans_DW.sfEvent = brdemo_autotrans_CALL_EVENT;
  brdemo_autotrans_DW.is_active_gear_state = 0U;
  brdemo_autotrans_DW.is_gear_state = brdemo_autot_IN_NO_ACTIVE_CHILD;
  brdemo_autotrans_DW.is_active_selection_state = 0U;
  brdemo_autotrans_DW.is_selection_state = brdemo_autot_IN_NO_ACTIVE_CHILD;
  brdemo_autotrans_DW.temporalCounter_i1 = 0U;
  brdemo_autotrans_DW.is_active_c1_brdemo_autotrans = 0U;
  brdemo_autotrans_B.gear = 0.0;
}

/* Model terminate function */
void brdemo_autotrans_terminate(void)
{
  /* (no terminate code required) */
}

/*========================================================================*
 * Start of Classic call interface                                        *
 *========================================================================*/

/* Solver interface called by GRT_Main */
#ifndef USE_GENERATED_SOLVER

void rt_ODECreateIntegrationData(RTWSolverInfo *si)
{
  UNUSED_PARAMETER(si);
  return;
}                                      /* do nothing */

void rt_ODEDestroyIntegrationData(RTWSolverInfo *si)
{
  UNUSED_PARAMETER(si);
  return;
}                                      /* do nothing */

void rt_ODEUpdateContinuousStates(RTWSolverInfo *si)
{
  UNUSED_PARAMETER(si);
  return;
}                                      /* do nothing */

#endif

void MdlOutputs(int_T tid)
{
  brdemo_autotrans_output();
  UNUSED_PARAMETER(tid);
}

void MdlUpdate(int_T tid)
{
  brdemo_autotrans_update();
  UNUSED_PARAMETER(tid);
}

void MdlInitializeSizes(void)
{
}

void MdlInitializeSampleTimes(void)
{
}

void MdlInitialize(void)
{
}

void MdlStart(void)
{
  brdemo_autotrans_initialize();
}

void MdlTerminate(void)
{
  brdemo_autotrans_terminate();
}

/* Registration function */
RT_MODEL_brdemo_autotrans_T *brdemo_autotrans(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  /* initialize real-time model */
  (void) memset((void *)brdemo_autotrans_M, 0,
                sizeof(RT_MODEL_brdemo_autotrans_T));

  {
    /* Setup solver object */
    rtsiSetSimTimeStepPtr(&brdemo_autotrans_M->solverInfo,
                          &brdemo_autotrans_M->Timing.simTimeStep);
    rtsiSetTPtr(&brdemo_autotrans_M->solverInfo, &rtmGetTPtr(brdemo_autotrans_M));
    rtsiSetStepSizePtr(&brdemo_autotrans_M->solverInfo,
                       &brdemo_autotrans_M->Timing.stepSize0);
    rtsiSetdXPtr(&brdemo_autotrans_M->solverInfo,
                 &brdemo_autotrans_M->ModelData.derivs);
    rtsiSetContStatesPtr(&brdemo_autotrans_M->solverInfo, (real_T **)
                         &brdemo_autotrans_M->ModelData.contStates);
    rtsiSetNumContStatesPtr(&brdemo_autotrans_M->solverInfo,
      &brdemo_autotrans_M->Sizes.numContStates);
    rtsiSetNumPeriodicContStatesPtr(&brdemo_autotrans_M->solverInfo,
      &brdemo_autotrans_M->Sizes.numPeriodicContStates);
    rtsiSetPeriodicContStateIndicesPtr(&brdemo_autotrans_M->solverInfo,
      &brdemo_autotrans_M->ModelData.periodicContStateIndices);
    rtsiSetPeriodicContStateRangesPtr(&brdemo_autotrans_M->solverInfo,
      &brdemo_autotrans_M->ModelData.periodicContStateRanges);
    rtsiSetErrorStatusPtr(&brdemo_autotrans_M->solverInfo, (&rtmGetErrorStatus
      (brdemo_autotrans_M)));
    rtsiSetRTModelPtr(&brdemo_autotrans_M->solverInfo, brdemo_autotrans_M);
  }

  rtsiSetSimTimeStep(&brdemo_autotrans_M->solverInfo, MAJOR_TIME_STEP);
  brdemo_autotrans_M->ModelData.intgData.y = brdemo_autotrans_M->ModelData.odeY;
  brdemo_autotrans_M->ModelData.intgData.f[0] =
    brdemo_autotrans_M->ModelData.odeF[0];
  brdemo_autotrans_M->ModelData.intgData.f[1] =
    brdemo_autotrans_M->ModelData.odeF[1];
  brdemo_autotrans_M->ModelData.intgData.f[2] =
    brdemo_autotrans_M->ModelData.odeF[2];
  brdemo_autotrans_M->ModelData.intgData.f[3] =
    brdemo_autotrans_M->ModelData.odeF[3];
  brdemo_autotrans_M->ModelData.intgData.f[4] =
    brdemo_autotrans_M->ModelData.odeF[4];
  brdemo_autotrans_M->ModelData.intgData.f[5] =
    brdemo_autotrans_M->ModelData.odeF[5];
  brdemo_autotrans_M->ModelData.contStates = ((real_T *) &brdemo_autotrans_X);
  rtsiSetSolverData(&brdemo_autotrans_M->solverInfo, (void *)
                    &brdemo_autotrans_M->ModelData.intgData);
  rtsiSetSolverName(&brdemo_autotrans_M->solverInfo,"ode5");

  /* Initialize timing info */
  {
    int_T *mdlTsMap = brdemo_autotrans_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    mdlTsMap[1] = 1;
    mdlTsMap[2] = 2;
    brdemo_autotrans_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    brdemo_autotrans_M->Timing.sampleTimes =
      (&brdemo_autotrans_M->Timing.sampleTimesArray[0]);
    brdemo_autotrans_M->Timing.offsetTimes =
      (&brdemo_autotrans_M->Timing.offsetTimesArray[0]);

    /* task periods */
    brdemo_autotrans_M->Timing.sampleTimes[0] = (0.0);
    brdemo_autotrans_M->Timing.sampleTimes[1] = (0.01);
    brdemo_autotrans_M->Timing.sampleTimes[2] = (0.04);

    /* task offsets */
    brdemo_autotrans_M->Timing.offsetTimes[0] = (0.0);
    brdemo_autotrans_M->Timing.offsetTimes[1] = (0.0);
    brdemo_autotrans_M->Timing.offsetTimes[2] = (0.0);
  }

  rtmSetTPtr(brdemo_autotrans_M, &brdemo_autotrans_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = brdemo_autotrans_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    mdlSampleHits[1] = 1;
    mdlSampleHits[2] = 1;
    brdemo_autotrans_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(brdemo_autotrans_M, 30.0);
  brdemo_autotrans_M->Timing.stepSize0 = 0.01;
  brdemo_autotrans_M->Timing.stepSize1 = 0.01;
  brdemo_autotrans_M->Timing.stepSize2 = 0.04;

  /* Setup for data logging */
  {
    static RTWLogInfo rt_DataLoggingInfo;
    rt_DataLoggingInfo.loggingInterval = NULL;
    brdemo_autotrans_M->rtwLogInfo = &rt_DataLoggingInfo;
  }

  /* Setup for data logging */
  {
    rtliSetLogXSignalInfo(brdemo_autotrans_M->rtwLogInfo, (NULL));
    rtliSetLogXSignalPtrs(brdemo_autotrans_M->rtwLogInfo, (NULL));
    rtliSetLogT(brdemo_autotrans_M->rtwLogInfo, "tout");
    rtliSetLogX(brdemo_autotrans_M->rtwLogInfo, "");
    rtliSetLogXFinal(brdemo_autotrans_M->rtwLogInfo, "");
    rtliSetLogVarNameModifier(brdemo_autotrans_M->rtwLogInfo, "rt_");
    rtliSetLogFormat(brdemo_autotrans_M->rtwLogInfo, 2);
    rtliSetLogMaxRows(brdemo_autotrans_M->rtwLogInfo, 0);
    rtliSetLogDecimation(brdemo_autotrans_M->rtwLogInfo, 1);

    /*
     * Set pointers to the data and signal info for each output
     */
    {
      static void * rt_LoggedOutputSignalPtrs[] = {
        &brdemo_autotrans_Y.speed,
        &brdemo_autotrans_Y.RPM,
        &brdemo_autotrans_Y.gear
      };

      rtliSetLogYSignalPtrs(brdemo_autotrans_M->rtwLogInfo, ((LogSignalPtrsType)
        rt_LoggedOutputSignalPtrs));
    }

    {
      static int_T rt_LoggedOutputWidths[] = {
        1,
        1,
        1
      };

      static int_T rt_LoggedOutputNumDimensions[] = {
        1,
        1,
        1
      };

      static int_T rt_LoggedOutputDimensions[] = {
        1,
        1,
        1
      };

      static boolean_T rt_LoggedOutputIsVarDims[] = {
        0,
        0,
        0
      };

      static void* rt_LoggedCurrentSignalDimensions[] = {
        (NULL),
        (NULL),
        (NULL)
      };

      static int_T rt_LoggedCurrentSignalDimensionsSize[] = {
        4,
        4,
        4
      };

      static BuiltInDTypeId rt_LoggedOutputDataTypeIds[] = {
        SS_DOUBLE,
        SS_DOUBLE,
        SS_DOUBLE
      };

      static int_T rt_LoggedOutputComplexSignals[] = {
        0,
        0,
        0
      };

      static const char_T *rt_LoggedOutputLabels[] = {
        "VehicleSpeed",
        "EngineRPM",
        "" };

      static const char_T *rt_LoggedOutputBlockNames[] = {
        "brdemo_autotrans/speed",
        "brdemo_autotrans/RPM",
        "brdemo_autotrans/gear" };

      static RTWLogDataTypeConvert rt_RTWLogDataTypeConvert[] = {
        { 0, SS_DOUBLE, SS_DOUBLE, 0, 0, 0, 1.0, 0, 0.0 },

        { 0, SS_DOUBLE, SS_DOUBLE, 0, 0, 0, 1.0, 0, 0.0 },

        { 0, SS_DOUBLE, SS_DOUBLE, 0, 0, 0, 1.0, 0, 0.0 }
      };

      static RTWLogSignalInfo rt_LoggedOutputSignalInfo[] = {
        {
          3,
          rt_LoggedOutputWidths,
          rt_LoggedOutputNumDimensions,
          rt_LoggedOutputDimensions,
          rt_LoggedOutputIsVarDims,
          rt_LoggedCurrentSignalDimensions,
          rt_LoggedCurrentSignalDimensionsSize,
          rt_LoggedOutputDataTypeIds,
          rt_LoggedOutputComplexSignals,
          (NULL),

          { rt_LoggedOutputLabels },
          (NULL),
          (NULL),
          (NULL),

          { rt_LoggedOutputBlockNames },

          { (NULL) },
          (NULL),
          rt_RTWLogDataTypeConvert
        }
      };

      rtliSetLogYSignalInfo(brdemo_autotrans_M->rtwLogInfo,
                            rt_LoggedOutputSignalInfo);

      /* set currSigDims field */
      rt_LoggedCurrentSignalDimensions[0] = &rt_LoggedOutputWidths[0];
      rt_LoggedCurrentSignalDimensions[1] = &rt_LoggedOutputWidths[1];
      rt_LoggedCurrentSignalDimensions[2] = &rt_LoggedOutputWidths[2];
    }

    rtliSetLogY(brdemo_autotrans_M->rtwLogInfo, "yout");
  }

  brdemo_autotrans_M->solverInfoPtr = (&brdemo_autotrans_M->solverInfo);
  brdemo_autotrans_M->Timing.stepSize = (0.01);
  rtsiSetFixedStepSize(&brdemo_autotrans_M->solverInfo, 0.01);
  rtsiSetSolverMode(&brdemo_autotrans_M->solverInfo, SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  brdemo_autotrans_M->ModelData.blockIO = ((void *) &brdemo_autotrans_B);

  {
    brdemo_autotrans_B.VehicleSpeed = 0.0;
    brdemo_autotrans_B.RPM = 0.0;
    brdemo_autotrans_B.LookUpTable = 0.0;
    brdemo_autotrans_B.TransmissionRPM = 0.0;
    brdemo_autotrans_B.engineimpellerinertia = 0.0;
    brdemo_autotrans_B.OutputTorque = 0.0;
    brdemo_autotrans_B.VehicleInertia = 0.0;
    brdemo_autotrans_B.gear = 0.0;
  }

  /* parameters */
  brdemo_autotrans_M->ModelData.defaultParam = ((real_T *)&brdemo_autotrans_P);

  /* states (continuous) */
  {
    real_T *x = (real_T *) &brdemo_autotrans_X;
    brdemo_autotrans_M->ModelData.contStates = (x);
    (void) memset((void *)&brdemo_autotrans_X, 0,
                  sizeof(X_brdemo_autotrans_T));
  }

  /* states (dwork) */
  brdemo_autotrans_M->ModelData.dwork = ((void *) &brdemo_autotrans_DW);
  (void) memset((void *)&brdemo_autotrans_DW, 0,
                sizeof(DW_brdemo_autotrans_T));

  /* external inputs */
  brdemo_autotrans_M->ModelData.inputs = (((void*)&brdemo_autotrans_U));
  brdemo_autotrans_U.throttle = 0.0;
  brdemo_autotrans_U.brake = 0.0;

  /* external outputs */
  brdemo_autotrans_M->ModelData.outputs = (&brdemo_autotrans_Y);
  brdemo_autotrans_Y.speed = 0.0;
  brdemo_autotrans_Y.RPM = 0.0;
  brdemo_autotrans_Y.gear = 0.0;

  /* Initialize Sizes */
  brdemo_autotrans_M->Sizes.numContStates = (2);/* Number of continuous states */
  brdemo_autotrans_M->Sizes.numPeriodicContStates = (0);/* Number of periodic continuous states */
  brdemo_autotrans_M->Sizes.numY = (3);/* Number of model outputs */
  brdemo_autotrans_M->Sizes.numU = (2);/* Number of model inputs */
  brdemo_autotrans_M->Sizes.sysDirFeedThru = (1);/* The model is direct feedthrough */
  brdemo_autotrans_M->Sizes.numSampTimes = (3);/* Number of sample times */
  brdemo_autotrans_M->Sizes.numBlocks = (35);/* Number of blocks */
  brdemo_autotrans_M->Sizes.numBlockIO = (10);/* Number of block outputs */
  brdemo_autotrans_M->Sizes.numBlockPrms = (280);/* Sum of parameter "widths" */
  return brdemo_autotrans_M;
}

/*========================================================================*
 * End of Classic call interface                                          *
 *========================================================================*/
