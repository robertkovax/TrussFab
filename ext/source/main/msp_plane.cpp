/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_plane.h"
#include "msp_joint.h"
#include "msp_world.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::Plane::DEFAULT_LINEAR_FRICTION(0.0f);
const treal MSP::Plane::DEFAULT_ANGULAR_FRICTION(0.0f);
const bool MSP::Plane::DEFAULT_ALLOW_ROTATION(true);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

MSP::Plane::ChildData* MSP::Plane::c_get_child_data(Joint::Data* joint_data) {
    return reinterpret_cast<ChildData*>(joint_data->m_cdata);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Plane::on_update(Joint::Data* joint_data, const NewtonJoint* joint, treal dt, int thread_index) {
    ChildData* cj_data = c_get_child_data(joint_data);

    treal dt_inv = (treal)(1.0) / dt;

    Geom::Transformation matrix0, matrix1;
    MSP::Joint::c_calculate_global_matrix(joint_data, matrix0, matrix1);

    Geom::Transformation matrix1_inv(matrix1.inverse());

    Geom::Vector3d veloc0(0.0f);
    Geom::Vector3d veloc1(0.0f);
    NewtonBodyGetVelocity(joint_data->m_child, &veloc0[0]);
    if (joint_data->m_parent != nullptr)
        NewtonBodyGetVelocity(joint_data->m_parent, &veloc1[0]);

    Geom::Vector3d loc_veloc(matrix1_inv.rotate_vector(veloc0 - veloc1));
    Geom::Vector3d loc_desired_lin_accel(loc_veloc.scale(-dt_inv));

    const Geom::Vector3d& p0 = matrix0.m_origin;
    Geom::Vector3d p1(matrix1_inv.transform_vector(matrix0.m_origin));
    p1.m_z = 0.0f;
    p1 = matrix1.transform_vector(p1);

    // Add friction on axes perpendicular to the pin direction.
    NewtonUserJointAddLinearRow(joint, &p0[0], &p1[0], &matrix1.m_xaxis[0]);
    NewtonUserJointSetRowAcceleration(joint, loc_desired_lin_accel.m_x);
    NewtonUserJointSetRowMinimumFriction(joint, -cj_data->m_lf);
    NewtonUserJointSetRowMaximumFriction(joint, cj_data->m_lf);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    NewtonUserJointAddLinearRow(joint, &p0[0], &p1[0], &matrix1.m_yaxis[0]);
    NewtonUserJointSetRowAcceleration(joint, loc_desired_lin_accel.m_y);
    NewtonUserJointSetRowMinimumFriction(joint, -cj_data->m_lf);
    NewtonUserJointSetRowMaximumFriction(joint, cj_data->m_lf);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    // Restrict movement along the pin direction.
    NewtonUserJointAddLinearRow(joint, &p0[0], &p1[0], &matrix1.m_zaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    // Restriction rotation along the two axis perpendicular to pin.
    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix0.m_zaxis, matrix1.m_zaxis, matrix1.m_xaxis), &matrix1.m_xaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix0.m_zaxis, matrix1.m_zaxis, matrix1.m_yaxis), &matrix1.m_yaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    if (cj_data->m_allow_rotation) {
        Geom::Vector3d omega0(0.0f);
        Geom::Vector3d omega1(0.0f);
        NewtonBodyGetOmega(joint_data->m_child, &omega0[0]);
        if (joint_data->m_parent != nullptr)
            NewtonBodyGetOmega(joint_data->m_parent, &omega1[0]);

        Geom::Vector3d loc_omega(matrix1_inv.rotate_vector(omega0 - omega1));
        dFloat loc_desired_ang_accel = -loc_omega.m_z * dt_inv;

        NewtonUserJointAddAngularRow(joint, 0.0f, &matrix1.m_zaxis[0]);
        NewtonUserJointSetRowAcceleration(joint, loc_desired_ang_accel);
        NewtonUserJointSetRowMinimumFriction(joint, -cj_data->m_af);
        NewtonUserJointSetRowMaximumFriction(joint, cj_data->m_af);
    }
    else
        NewtonUserJointAddAngularRow(joint, Joint::c_calculate_angle2(matrix0.m_xaxis, matrix1.m_xaxis, matrix1.m_zaxis), &matrix1.m_zaxis[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_stiffness);

    joint_data->m_tension1 =
        matrix0.m_xaxis.scale(NewtonUserJointGetRowForce(joint, 0)) +
        matrix0.m_yaxis.scale(NewtonUserJointGetRowForce(joint, 1)) +
        matrix0.m_zaxis.scale(NewtonUserJointGetRowForce(joint, 2));

    joint_data->m_tension2 =
        matrix0.m_xaxis.scale(NewtonUserJointGetRowForce(joint, 3)) +
        matrix0.m_yaxis.scale(NewtonUserJointGetRowForce(joint, 4)) +
        matrix0.m_zaxis.scale(NewtonUserJointGetRowForce(joint, 5));
}

void MSP::Plane::on_destroy(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    delete cj_data;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Plane::rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_matrix, VALUE v_group) {
    Joint::Data* joint_data = Joint::c_create_begin(self, v_world, v_parent, v_child, v_matrix, v_group, 6, on_update, nullptr, nullptr, nullptr);

    ChildData* cj_data = new ChildData;
    joint_data->m_cdata = cj_data;

    Joint::c_create_end(self, joint_data);
    return self;
}

VALUE MSP::Plane::rbf_get_linear_friction(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_lf);
}

VALUE MSP::Plane::rbf_set_linear_friction(VALUE self, VALUE v_lf) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_lf = RU::value_to_treal(v_lf);
    return Qnil;
}

VALUE MSP::Plane::rbf_get_angular_friction(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_af);
}

VALUE MSP::Plane::rbf_set_angular_friction(VALUE self, VALUE v_af) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_af = RU::value_to_treal(v_af);
    return Qnil;
}

VALUE MSP::Plane::rbf_rotation_allowed(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_allow_rotation);
}

VALUE MSP::Plane::rbf_allow_rotation(VALUE self, VALUE v_state) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_allow_rotation = RU::value_to_bool(v_state);
    return Qnil;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Plane::init_ruby(VALUE mMSP) {
    VALUE cPlane = rb_define_class_under(mMSP, "Plane", rba_cJoint);

    rb_define_alloc_func(cPlane, Joint::c_class_allocate);

    rb_define_const(cPlane, "DEFAULT_LINEAR_FRICTION", RU::to_value(DEFAULT_LINEAR_FRICTION));
    rb_define_const(cPlane, "DEFAULT_ANGULAR_FRICTION", RU::to_value(DEFAULT_ANGULAR_FRICTION));
    rb_define_const(cPlane, "DEFAULT_ALLOW_ROTATION", RU::to_value(DEFAULT_ALLOW_ROTATION));

    rb_define_method(cPlane, "initialize", VALUEFUNC(rbf_initialize), 5);
    rb_define_method(cPlane, "linear_friction", VALUEFUNC(rbf_get_linear_friction), 0);
    rb_define_method(cPlane, "linear_friction=", VALUEFUNC(rbf_set_linear_friction), 1);
    rb_define_method(cPlane, "angular_friction", VALUEFUNC(rbf_get_angular_friction), 0);
    rb_define_method(cPlane, "angular_friction=", VALUEFUNC(rbf_set_angular_friction), 1);
    rb_define_method(cPlane, "rotation_allowed?", VALUEFUNC(rbf_rotation_allowed), 0);
    rb_define_method(cPlane, "rotation_allowed=", VALUEFUNC(rbf_allow_rotation), 1);
}
