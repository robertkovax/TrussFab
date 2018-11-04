/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_HINGE_H
#define MSP_HINGE_H

#include "msp.h"
#include "msp_joint.h"
#include "angular_integration.h"

class MSP::Hinge {
public:
    // Constants
    static const treal DEFAULT_MIN;
    static const treal DEFAULT_MAX;
    static const treal DEFAULT_FRICTION;
    static const bool DEFAULT_LIMITS_ENABLED;

    // Structures
    struct ChildData {
        AngularIntegration m_ai;
        treal m_min;
        treal m_max;
        treal m_friction;
        treal m_cur_omega;
        bool m_limits_enabled;

        ChildData() :
            m_ai(0.0),
            m_min(DEFAULT_MIN),
            m_max(DEFAULT_MAX),
            m_friction(DEFAULT_FRICTION),
            m_limits_enabled(DEFAULT_LIMITS_ENABLED),
            m_cur_omega(0.0)
        {
        }
    };

    // Helper Functions
    static ChildData* c_get_child_data(Joint::Data* joint_data);

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index);
    static void on_destroy(Joint::Data* joint_data);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group, VALUE v_initial_angle);
    static VALUE rbf_get_min(VALUE self);
    static VALUE rbf_set_min(VALUE self, VALUE v_min);
    static VALUE rbf_get_max(VALUE self);
    static VALUE rbf_set_max(VALUE self, VALUE v_max);
    static VALUE rbf_get_friction(VALUE self);
    static VALUE rbf_set_friction(VALUE self, VALUE v_friction);
    static VALUE rbf_get_cur_angle(VALUE self);
    static VALUE rbf_get_cur_omega(VALUE self);
    static VALUE rbf_limits_enabled(VALUE self);
    static VALUE rbf_enable_limits(VALUE self, VALUE v_state);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_HINGE_H */
