/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_POINT_TO_POINT_GAS_SPRING_H
#define MSP_POINT_TO_POINT_GAS_SPRING_H

#include "msp.h"
#include "msp_joint.h"

class MSP::PointToPointGasSpring {
public:
    // Constants
    static const treal DEFAULT_EXTENDED_LENGTH;
    static const treal DEFAULT_STROKE_LENGTH;
    static const treal DEFAULT_EXTENDED_FORCE;
    static const treal DEFAULT_DAMP;
    static const treal DEFAULT_THRESHOLD;

    // Structures
    struct ChildData {
        DelayedForceAndTorque m_dftp;
        DelayedForceAndTorque m_dftc;
        Geom::Vector3d m_point1;
        Geom::Vector3d m_point2;
        Geom::Vector3d m_cur_normal;
        treal m_extended_length;
        treal m_contracted_length;
        treal m_stroke_length;
        treal m_extended_force;
        treal m_threshold;
        treal m_damp;
        treal m_cur_length;
        treal m_cur_velocity;
        treal m_factor;
        treal m_ratio;

        ChildData() :
            m_extended_length(DEFAULT_EXTENDED_LENGTH * M_METER_TO_INCH),
            m_stroke_length(DEFAULT_STROKE_LENGTH * M_METER_TO_INCH),
            m_extended_force(DEFAULT_EXTENDED_FORCE * M_METER_TO_INCH),
            m_threshold(DEFAULT_THRESHOLD * M_METER_TO_INCH),
            m_damp(DEFAULT_DAMP),
            m_cur_length(0.0),
            m_cur_velocity(0.0)
        {
        }
    };

    // Helper Functions
    static ChildData* c_get_child_data(Joint::Data* joint_data);
    static void c_update_info(Joint::Data* joint_data);

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index);
    static void on_destroy(Joint::Data* joint_data);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_pt1, VALUE v_pt2, VALUE v_group);
    static VALUE rbf_get_point1(VALUE self);
    static VALUE rbf_set_point1(VALUE self, VALUE v_point);
    static VALUE rbf_get_point2(VALUE self);
    static VALUE rbf_set_point2(VALUE self, VALUE v_point);
    static VALUE rbf_get_extended_length(VALUE self);
    static VALUE rbf_set_extended_length(VALUE self, VALUE v_length);
    static VALUE rbf_get_stroke_length(VALUE self);
    static VALUE rbf_set_stroke_length(VALUE self, VALUE v_length);
    static VALUE rbf_get_extended_force(VALUE self);
    static VALUE rbf_set_extended_force(VALUE self, VALUE v_force);
    static VALUE rbf_get_threshold(VALUE self);
    static VALUE rbf_set_threshold(VALUE self, VALUE v_threshold);
    static VALUE rbf_get_damp(VALUE self);
    static VALUE rbf_set_damp(VALUE self, VALUE v_damp);
    static VALUE rbf_get_cur_length(VALUE self);
    static VALUE rbf_get_cur_velocity(VALUE self);
    static VALUE rbf_get_cur_normal(VALUE self);
    static VALUE rbf_update_info(VALUE self);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_POINT_TO_POINT_GAS_SPRING_H */
