/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_point_to_point.h"
#include "msp_joint.h"
#include "msp_world.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

MSP::PointToPoint::ChildData* MSP::PointToPoint::c_get_child_data(Joint::Data* joint_data) {
    return reinterpret_cast<ChildData*>(joint_data->m_cdata);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::PointToPoint::on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index) {
    ChildData* cj_data = c_get_child_data(joint_data);

    Geom::Transformation matrix;
    Geom::Vector3d pt1, pt2, pt3;

    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        pt1 = matrix.transform_vector2(cj_data->m_point1);
    }
    else
        pt1 = cj_data->m_point1;
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    pt2 = matrix.transform_vector2(cj_data->m_point2);

    cj_data->m_cur_normal = pt2 - pt1;
    cj_data->m_cur_distance = cj_data->m_cur_normal.get_length();

    if (cj_data->m_cur_distance > M_EPSILON) {
        cj_data->m_cur_normal.scale_self((treal)(1.0) / cj_data->m_cur_distance);
    }
    else
        cj_data->m_cur_normal = Geom::Vector3d::Z_AXIS;

    pt3 = pt1 + cj_data->m_cur_normal.scale(cj_data->m_start_distance);

    NewtonUserJointAddLinearRow(joint, &pt2[0], &pt3[0], &cj_data->m_cur_normal[0]);
    NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
    //joint_data->m_limit_min_row_proc(joint_data);
    //joint_data->m_limit_max_row_proc(joint_data);

    // Update tensions
    joint_data->m_tension1 = cj_data->m_cur_normal.scale(NewtonUserJointGetRowForce(joint, 0));
}

void MSP::PointToPoint::on_destroy(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    delete cj_data;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::PointToPoint::rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_pt1, VALUE v_pt2, VALUE v_group) {
    Geom::Vector3d pt1, pt2;
    Geom::Transformation matrix, matrix_inv;

    Joint::Data* joint_data = Joint::c_create_begin(self, v_world, v_parent, v_child, Qnil, v_group, 1, on_update, on_destroy, nullptr, nullptr);

    RU::value_to_vector(v_pt1, pt1);
    RU::value_to_vector(v_pt2, pt2);

    ChildData* cj_data = new ChildData;

    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        matrix_inv = matrix.inverse();
        cj_data->m_point1 = matrix_inv.transform_vector2(pt1);
    }
    else
        cj_data->m_point1 = pt1;

    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    matrix_inv = matrix.inverse();
    cj_data->m_point2 = matrix_inv.transform_vector2(pt2);

    cj_data->m_cur_normal = pt2 - pt1;
    cj_data->m_start_distance = cj_data->m_cur_normal.get_length();
    cj_data->m_cur_distance = cj_data->m_start_distance;

    if (cj_data->m_cur_distance > M_EPSILON) {
        cj_data->m_cur_normal.scale_self((treal)(1.0) / cj_data->m_cur_distance);
    }
    else
        cj_data->m_cur_normal = Geom::Vector3d::Z_AXIS;

    joint_data->m_cdata = cj_data;

    Joint::c_create_end(self, joint_data);

    return self;
}

VALUE MSP::PointToPoint::rbf_get_point1(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Transformation matrix;
    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        return RU::point_to_value(matrix.transform_vector2(cj_data->m_point1));
    }
    else {
        return RU::point_to_value(cj_data->m_point1);
    }
}

VALUE MSP::PointToPoint::rbf_set_point1(VALUE self, VALUE v_point) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Vector3d point;
    Geom::Transformation matrix, matrix_inv;
    RU::value_to_vector(v_point, point);
    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        matrix_inv = matrix.inverse();
        cj_data->m_point1 = matrix_inv.transform_vector2(point);
    }
    else {
        cj_data->m_point1 = point;
    }
    return Qnil;
}

VALUE MSP::PointToPoint::rbf_get_point2(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Transformation matrix;
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    return RU::point_to_value(matrix.transform_vector2(cj_data->m_point2));
}

VALUE MSP::PointToPoint::rbf_set_point2(VALUE self, VALUE v_point) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Vector3d point;
    Geom::Transformation matrix, matrix_inv;
    RU::value_to_vector(v_point, point);
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    matrix_inv = matrix.inverse();
    cj_data->m_point2 = matrix_inv.transform_vector2(point);
    return Qnil;
}

VALUE MSP::PointToPoint::rbf_get_start_distance(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_start_distance * M_INCH_TO_METER);
}

VALUE MSP::PointToPoint::rbf_set_start_distance(VALUE self, VALUE v_distance) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_start_distance = Geom::max_treal(RU::value_to_treal(v_distance), 0.0) * M_METER_TO_INCH;
    return Qnil;
}

VALUE MSP::PointToPoint::rbf_get_cur_distance(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_distance * M_INCH_TO_METER);
}

VALUE MSP::PointToPoint::rbf_get_cur_normal(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::vector_to_value(cj_data->m_cur_normal);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::PointToPoint::init_ruby(VALUE mMSP) {
    VALUE cPointToPoint = rb_define_class_under(mMSP, "PointToPoint", rba_cJoint);

    rb_define_alloc_func(cPointToPoint, Joint::c_class_allocate);

    rb_define_method(cPointToPoint, "initialize", VALUEFUNC(rbf_initialize), 6);
    rb_define_method(cPointToPoint, "get_point1", VALUEFUNC(rbf_get_point1), 0);
    rb_define_method(cPointToPoint, "set_point1", VALUEFUNC(rbf_set_point1), 1);
    rb_define_method(cPointToPoint, "get_point2", VALUEFUNC(rbf_get_point2), 0);
    rb_define_method(cPointToPoint, "set_point2", VALUEFUNC(rbf_set_point2), 1);
    rb_define_method(cPointToPoint, "start_distance", VALUEFUNC(rbf_get_start_distance), 0);
    rb_define_method(cPointToPoint, "start_distance=", VALUEFUNC(rbf_set_start_distance), 1);
    rb_define_method(cPointToPoint, "cur_distance", VALUEFUNC(rbf_get_cur_distance), 0);
    rb_define_method(cPointToPoint, "cur_normal", VALUEFUNC(rbf_get_cur_normal), 0);
}
