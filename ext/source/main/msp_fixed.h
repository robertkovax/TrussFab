/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_FIXED_H
#define MSP_FIXED_H

#include "msp.h"
#include "msp_joint.h"

class MSP::Fixed {
public:

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, treal dt, int thread_index);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_FIXED_H */
