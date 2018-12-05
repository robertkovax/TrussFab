/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_PLANE_H
#define MSP_PLANE_H

#include "msp.h"
#include "msp_joint.h"

class MSP::Plane {
public:
    // Constants
    static const treal DEFAULT_LINEAR_FRICTION;
    static const treal DEFAULT_ANGULAR_FRICTION;
    static const bool DEFAULT_ALLOW_ROTATION;

    // Structures
    struct ChildData {
        treal m_lf;
        treal m_af;
        bool m_allow_rotation;

        ChildData() :
            m_lf(DEFAULT_LINEAR_FRICTION),
            m_af(DEFAULT_ANGULAR_FRICTION),
            m_allow_rotation(DEFAULT_ALLOW_ROTATION)
        {
        }
    };
    
    // Helper Functions
    static ChildData* c_get_child_data(Joint::Data* joint_data);

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, treal dt, int thread_index);
    static void on_destroy(Joint::Data* joint_data);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group);
    static VALUE rbf_get_linear_friction(VALUE self);
    static VALUE rbf_set_linear_friction(VALUE self, VALUE v_lf);
    static VALUE rbf_get_angular_friction(VALUE self);
    static VALUE rbf_set_angular_friction(VALUE self, VALUE v_af);
    static VALUE rbf_rotation_allowed(VALUE self);
    static VALUE rbf_allow_rotation(VALUE self, VALUE v_state);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_PLANE_H */
