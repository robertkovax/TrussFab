/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_POINT_TO_POINT_H
#define MSP_POINT_TO_POINT_H

#include "msp.h"
#include "msp_joint.h"

class MSP::PointToPoint {
public:
    // Structures
    struct ChildData {
        Geom::Vector3d m_point1;
        Geom::Vector3d m_point2;
        Geom::Vector3d m_cur_normal;
        treal m_start_distance;
        treal m_cur_distance;

        ChildData() :
            m_start_distance(0.0),
            m_cur_distance(0.0)
        {
        }
    };

    // Helper Functions
    static ChildData* c_get_child_data(Joint::Data* joint_data);

    // Callback Functions
    static void on_update(Joint::Data* joint_data, const NewtonJoint* joint, treal dt, int thread_index);
    static void on_destroy(Joint::Data* joint_data);

    // Ruby Functions
    static VALUE rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_pt1, VALUE v_pt2, VALUE v_group);
    static VALUE rbf_get_point1(VALUE self);
    static VALUE rbf_set_point1(VALUE self, VALUE v_point);
    static VALUE rbf_get_point2(VALUE self);
    static VALUE rbf_set_point2(VALUE self, VALUE v_point);
    static VALUE rbf_get_start_distance(VALUE self);
    static VALUE rbf_set_start_distance(VALUE self, VALUE v_distance);
    static VALUE rbf_get_cur_distance(VALUE self);
    static VALUE rbf_get_cur_normal(VALUE self);

    // Main
    static void init_ruby(VALUE mMSP);
};

#endif  /* MSP_POINT_TO_POINT_H */
