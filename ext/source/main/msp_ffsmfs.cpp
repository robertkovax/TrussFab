/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_ffsmfs.h"
#include "msp_joint.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::FFSMFS::on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index) {
    Geom::Transformation matrix0, matrix1;
    MSP::Joint::c_calculate_global_matrix(joint_data, matrix0, matrix1);

    NewtonUserJointAddLinearRow(joint, &matrix0.m_origin[0], &matrix1.m_origin[0], &matrix0.m_xaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
    /*joint_data->m_limit_min_row_proc(joint_data);
    joint_data->m_limit_max_row_proc(joint_data);*/

    NewtonUserJointAddLinearRow(joint, &matrix0.m_origin[0], &matrix1.m_origin[0], &matrix0.m_yaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
    /*joint_data->m_limit_min_row_proc(joint_data);
    joint_data->m_limit_max_row_proc(joint_data);*/

    NewtonUserJointAddLinearRow(joint, &matrix0.m_origin[0], &matrix1.m_origin[0], &matrix0.m_zaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
    /*joint_data->m_limit_min_row_proc(joint_data);
    joint_data->m_limit_max_row_proc(joint_data);*/

    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix1.m_zaxis, matrix0.m_zaxis, matrix0.m_xaxis), &matrix0.m_xaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
    /*joint_data->m_limit_min_row_proc(joint_data);
    joint_data->m_limit_max_row_proc(joint_data)*/;

    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix1.m_zaxis, matrix0.m_zaxis, matrix0.m_yaxis), &matrix0.m_yaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
    /*joint_data->m_limit_min_row_proc(joint_data);
    joint_data->m_limit_max_row_proc(joint_data);*/

    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix1.m_xaxis, matrix0.m_xaxis, matrix0.m_zaxis), &matrix0.m_zaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
    /*joint_data->m_limit_min_row_proc(joint_data);
    joint_data->m_limit_max_row_proc(joint_data);*/

    joint_data->m_tension1 =
        matrix0.m_xaxis.scale(NewtonUserJointGetRowForce(joint, 0)) +
        matrix0.m_yaxis.scale(NewtonUserJointGetRowForce(joint, 1)) +
        matrix0.m_zaxis.scale(NewtonUserJointGetRowForce(joint, 2));

    joint_data->m_tension2 =
        matrix0.m_xaxis.scale(NewtonUserJointGetRowForce(joint, 3)) +
        matrix0.m_yaxis.scale(NewtonUserJointGetRowForce(joint, 4)) +
        matrix0.m_zaxis.scale(NewtonUserJointGetRowForce(joint, 5));
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::FFSMFS::rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group) {
    Joint::Data* joint_data = Joint::c_create_begin(self, v_world, v_parent, v_child, v_matrix, v_group, 6, on_update, nullptr, nullptr, nullptr);
    Joint::c_create_end(self, joint_data);
    return self;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::FFSMFS::init_ruby(VALUE mMSP) {
    VALUE cFixed = rb_define_class_under(mMSP, "FFSMFS", rba_cJoint);

    rb_define_alloc_func(cFixed, Joint::c_class_allocate);

    rb_define_method(cFixed, "initialize", VALUEFUNC(rbf_initialize), 5);

}
