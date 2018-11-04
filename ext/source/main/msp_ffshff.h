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

// linear x-axis - fixed
// linear y-axis - fixed
// linear z-axis - spring
// angular x-axis - motor
// angular y-axis - fixed
// angular z-axis - servo
class MSP::FFSMFS {
public:

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_FFSMFS_H */
