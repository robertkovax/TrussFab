/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_FFSMFS_H
#define MSP_FFSMFS_H

#include "msp.h"
#include "msp_joint.h"

//  linear x-axis - fixed
//  linear y-axis - fixed
//  linear z-axis - spring
// angular x-axis - motor
// angular y-axis - fixed
// angular z-axis - servo
class MSP::FFSMFS {
public:
    // Constants
    static const treal DEFAULT_LZ_K;
    static const treal DEFAULT_LZ_D;
    static const treal DEFAULT_LZ_MIN;
    static const treal DEFAULT_LZ_MAX;
    static const treal DEFAULT_LZ_LIMITS_ENABLED;

    static const treal DEFAULT_AX_ACCEL;
    static const treal DEFAULT_AX_DAMP;
    static const treal DEFAULT_AX_CONTROLLER;

    static const treal DEFAULT_AZ_RATE;
    static const treal DEFAULT_AZ_REDUCTION;
    static const treal DEFAULT_AZ_CONTROLLER;

    // Structures
    struct ChildData {
        treal lz_k;
        treal lz_d;
        treal lz_min;
        treal lz_max;
        bool lz_limits;

        treal ax_accel;
        treal ax_damp;
        treal ax_controller;

        treal az_rate;
        treal az_reduction;
        treal az_controller;

        ChildData() :
            lz_k(DEFAULT_LZ_K),
            lz_d(DEFAULT_LZ_D),
            lz_min(DEFAULT_LZ_MIN),
            lz_max(DEFAULT_LZ_MAX),
            lz_limits(DEFAULT_LZ_LIMITS_ENABLED),
            ax_accel(DEFAULT_AX_ACCEL),
            ax_damp(DEFAULT_AX_DAMP),
            ax_controller(DEFAULT_AX_CONTROLLER),
            az_rate(DEFAULT_AZ_RATE),
            az_reduction(DEFAULT_AZ_REDUCTION),
            az_controller(DEFAULT_AZ_CONTROLLER)
        {
        }
    };

    // Helper Functions
    static ChildData* c_get_child_data(Joint::Data* joint_data);

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index);
    static void on_destroy(Joint::Data* joint_data);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group);

    static VALUE rbf_get_lz_k(VALUE self);
    static VALUE rbf_set_lz_k(VALUE self, VALUE v_val);
    static VALUE rbf_get_lz_d(VALUE self);
    static VALUE rbf_set_lz_d(VALUE self, VALUE v_val);
    static VALUE rbf_get_lz_min(VALUE self);
    static VALUE rbf_set_lz_min(VALUE self, VALUE v_val);
    static VALUE rbf_get_lz_max(VALUE self);
    static VALUE rbf_set_lz_max(VALUE self, VALUE v_val);
    static VALUE rbf_lz_limits_enabled(VALUE self);
    static VALUE rbf_lz_enable_limits(VALUE self, VALUE v_state);

    static VALUE rbf_get_ax_accel(VALUE self);
    static VALUE rbf_set_ax_accel(VALUE self, VALUE v_val);
    static VALUE rbf_get_ax_damp(VALUE self);
    static VALUE rbf_set_ax_damp(VALUE self, VALUE v_val);
    static VALUE rbf_get_ax_controller(VALUE self);
    static VALUE rbf_set_ax_controller(VALUE self, VALUE v_val);

    static VALUE rbf_get_az_rate(VALUE self);
    static VALUE rbf_set_az_rate(VALUE self, VALUE v_val);
    static VALUE rbf_get_az_reduction(VALUE self);
    static VALUE rbf_set_az_reduction(VALUE self, VALUE v_val);
    static VALUE rbf_get_az_controller(VALUE self);
    static VALUE rbf_set_az_controller(VALUE self, VALUE v_val);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_FFSMFS_H */
