/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_point_to_point_gas_spring.h"
#include "msp_joint.h"
#include "msp_world.h"
#include "msp_body.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::PointToPointGasSpring::DEFAULT_EXTENDED_LENGTH(0.8);
const treal MSP::PointToPointGasSpring::DEFAULT_STROKE_LENGTH(0.3);
const treal MSP::PointToPointGasSpring::DEFAULT_EXTENDED_FORCE(60.0);
const treal MSP::PointToPointGasSpring::DEFAULT_DAMP(0.1);
const treal MSP::PointToPointGasSpring::DEFAULT_THRESHOLD(0.02);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

MSP::PointToPointGasSpring::ChildData* MSP::PointToPointGasSpring::c_get_child_data(Joint::Data* joint_data) {
    return reinterpret_cast<ChildData*>(joint_data->m_cdata);
}

void MSP::PointToPointGasSpring::c_update_info(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    Body::Data* body_data1;
    Body::Data* body_data2;
    if (joint_data->m_parent)
        body_data1 = Body::c_to_data(joint_data->m_parent);
    else
        body_data1 = nullptr;
    body_data2 = Body::c_to_data(joint_data->m_child);

    cj_data->m_contracted_length = cj_data->m_extended_length - cj_data->m_stroke_length;
    cj_data->m_factor = (cj_data->m_stroke_length + cj_data->m_threshold) * cj_data->m_extended_force;

    if (body_data1 && !body_data1->m_static && !body_data2->m_static)
        cj_data->m_ratio = (treal)(0.5);
    else
        cj_data->m_ratio = (treal)(1.0);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::PointToPointGasSpring::on_update(Joint::Data* joint_data, const NewtonJoint* joint, int thread_index) {
    ChildData* cj_data = c_get_child_data(joint_data);
    World::Data* world_data = World::c_to_data(joint_data->m_world);

    Geom::Transformation matrix;
    Geom::Vector3d pt1, pt2, ptx, centre1, centre2, force;
    Geom::Vector3d v1(0.0);
    Geom::Vector3d v2(0.0);
    treal lf, dx, dv, sa;

    if (joint_data->m_parent) {
        NewtonBodyGetMatrix(joint_data->m_parent, &matrix[0][0]);
        NewtonBodyGetCentreOfMass(joint_data->m_parent, &centre1[0]);
        pt1 = matrix.transform_vector2(cj_data->m_point1);
        centre1 = matrix.transform_vector2(centre1);
        NewtonBodyGetPointVelocity(joint_data->m_parent, &pt1[0], &v1[0]);
    }
    else {
        pt1 = cj_data->m_point1;
    }

    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    NewtonBodyGetCentreOfMass(joint_data->m_child, &centre2[0]);
    pt2 = matrix.transform_vector2(cj_data->m_point2);
    centre2 = matrix.transform_vector2(centre2);
    NewtonBodyGetPointVelocity(joint_data->m_child, &pt2[0], &v2[0]);

    cj_data->m_cur_normal = pt2 - pt1;
    cj_data->m_cur_length = cj_data->m_cur_normal.get_length();

    if (cj_data->m_cur_length > M_EPSILON) {
        cj_data->m_cur_normal.scale_self((treal)(1.0) / cj_data->m_cur_length);
    }
    else
        cj_data->m_cur_normal = Geom::Vector3d::Z_AXIS;

    cj_data->m_cur_velocity = (v2 - v1).dot(cj_data->m_cur_normal);

    if (cj_data->m_cur_length < cj_data->m_contracted_length) {
        dx = cj_data->m_contracted_length - cj_data->m_cur_length;
        ptx = pt2 + cj_data->m_cur_normal.scale(dx);
        NewtonUserJointAddLinearRow(joint, &pt2[0], &ptx[0], &cj_data->m_cur_normal[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
        //joint_data->m_limit_min_row_proc(joint_data);
        dv = (treal)(0.5) * dx * world_data->m_timestep_inv;
        sa = NewtonUserJointCalculateRowZeroAccelaration(joint) + dv * world_data->m_timestep_inv;
        NewtonUserJointSetRowAcceleration(joint, sa);
        joint_data->m_tension1 = cj_data->m_cur_normal.scale(NewtonUserJointGetRowForce(joint, 0));
    }
    else if (cj_data->m_cur_length > cj_data->m_extended_length) {
        dx = cj_data->m_extended_length - cj_data->m_cur_length;
        ptx = pt2 + cj_data->m_cur_normal.scale(dx);
        NewtonUserJointAddLinearRow(joint, &pt2[0], &ptx[0], &cj_data->m_cur_normal[0]);
        NewtonUserJointSetRowStiffness(joint, joint_data->m_sf);
        //joint_data->m_limit_max_row_proc(joint_data);
        dv = (treal)(0.5) * dx * world_data->m_timestep_inv;
        sa = NewtonUserJointCalculateRowZeroAccelaration(joint) + dv * world_data->m_timestep_inv;
        NewtonUserJointSetRowAcceleration(joint, sa);
        joint_data->m_tension1 = cj_data->m_cur_normal.scale(NewtonUserJointGetRowForce(joint, 0));
    }
    else {
        lf = cj_data->m_factor / (cj_data->m_cur_length - cj_data->m_contracted_length + cj_data->m_threshold) - cj_data->m_cur_velocity * cj_data->m_damp;
        force = cj_data->m_cur_normal.scale(lf * cj_data->m_ratio);
        cj_data->m_dftp.m_force = force.reverse();
        cj_data->m_dftp.m_torque = force.cross((pt1 - centre1));
        cj_data->m_dftc.m_force = force;
        cj_data->m_dftc.m_torque = force.cross((centre2 - pt2));
        joint_data->m_tension1 = cj_data->m_cur_normal.scale(lf);
    }
}

void MSP::PointToPointGasSpring::on_destroy(Joint::Data* joint_data) {
    ChildData* cj_data = c_get_child_data(joint_data);
    World::Data* world_data = World::c_to_data(joint_data->m_world);
    if (world_data->m_dfts.find(&cj_data->m_dftp) != world_data->m_dfts.end())
        world_data->m_dfts.erase(&cj_data->m_dftp);
    if (world_data->m_dfts.find(&cj_data->m_dftc) != world_data->m_dfts.end())
        world_data->m_dfts.erase(&cj_data->m_dftc);
    delete cj_data;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::PointToPointGasSpring::rbf_initialize(VALUE self, VALUE v_world, VALUE v_parent, VALUE v_child, VALUE v_pt1, VALUE v_pt2, VALUE v_group) {
    Geom::Vector3d pt1, pt2;
    Geom::Transformation matrix, matrix_inv;

    Joint::Data* joint_data = Joint::c_create_begin(self, v_world, v_parent, v_child, Qnil, v_group, 1, on_update, on_destroy, nullptr, nullptr);

    RU::value_to_vector(v_pt1, pt1);
    RU::value_to_vector(v_pt2, pt2);

    ChildData* cj_data = new ChildData;
    World::Data* world_data = World::c_to_data(joint_data->m_world);

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
    cj_data->m_cur_length = cj_data->m_cur_normal.get_length();

    if (cj_data->m_cur_length > M_EPSILON) {
        cj_data->m_cur_normal.scale_self((treal)(1.0) / cj_data->m_cur_length);
    }
    else
        cj_data->m_cur_normal = Geom::Vector3d::Z_AXIS;

    if (joint_data->m_parent) {
        cj_data->m_dftp.m_body = joint_data->m_parent;
        world_data->m_dfts.insert(&cj_data->m_dftp);
    }
    cj_data->m_dftc.m_body = joint_data->m_child;
    world_data->m_dfts.insert(&cj_data->m_dftc);

    joint_data->m_cdata = cj_data;

    Joint::c_create_end(self, joint_data);

    c_update_info(joint_data);

    return self;
}

VALUE MSP::PointToPointGasSpring::rbf_get_point1(VALUE self) {
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

VALUE MSP::PointToPointGasSpring::rbf_set_point1(VALUE self, VALUE v_point) {
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

VALUE MSP::PointToPointGasSpring::rbf_get_point2(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    Geom::Transformation matrix;
    NewtonBodyGetMatrix(joint_data->m_child, &matrix[0][0]);
    return RU::point_to_value(matrix.transform_vector2(cj_data->m_point2));
}

VALUE MSP::PointToPointGasSpring::rbf_set_point2(VALUE self, VALUE v_point) {
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

VALUE MSP::PointToPointGasSpring::rbf_get_extended_length(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_extended_length * M_INCH_TO_METER);
}

VALUE MSP::PointToPointGasSpring::rbf_set_extended_length(VALUE self, VALUE v_length) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_extended_length = Geom::max_treal(RU::value_to_treal(v_length), 0.0) * M_METER_TO_INCH;
    c_update_info(joint_data);
    return Qnil;
}

VALUE MSP::PointToPointGasSpring::rbf_get_stroke_length(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_stroke_length * M_INCH_TO_METER);
}

VALUE MSP::PointToPointGasSpring::rbf_set_stroke_length(VALUE self, VALUE v_length) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_stroke_length = Geom::max_treal(RU::value_to_treal(v_length), 0.0) * M_METER_TO_INCH;
    c_update_info(joint_data);
    return Qnil;
}

VALUE MSP::PointToPointGasSpring::rbf_get_extended_force(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_extended_force * M_INCH_TO_METER);
}

VALUE MSP::PointToPointGasSpring::rbf_set_extended_force(VALUE self, VALUE v_force) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_extended_force = Geom::max_treal(RU::value_to_treal(v_force), 0.0) * M_METER_TO_INCH;
    c_update_info(joint_data);
    return Qnil;
}

VALUE MSP::PointToPointGasSpring::rbf_get_threshold(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_threshold * M_INCH_TO_METER);
}

VALUE MSP::PointToPointGasSpring::rbf_set_threshold(VALUE self, VALUE v_force) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_threshold = Geom::max_treal(RU::value_to_treal(v_force), M_EPSILON) * M_METER_TO_INCH;
    c_update_info(joint_data);
    return Qnil;
}

VALUE MSP::PointToPointGasSpring::rbf_get_damp(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_damp);
}

VALUE MSP::PointToPointGasSpring::rbf_set_damp(VALUE self, VALUE v_damp) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    cj_data->m_damp = Geom::max_treal(RU::value_to_treal(v_damp), 0.0);
    c_update_info(joint_data);
    return Qnil;
}

VALUE MSP::PointToPointGasSpring::rbf_get_cur_length(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_length * M_INCH_TO_METER);
}

VALUE MSP::PointToPointGasSpring::rbf_get_cur_velocity(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::to_value(cj_data->m_cur_velocity * M_INCH_TO_METER);
}

VALUE MSP::PointToPointGasSpring::rbf_get_cur_normal(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    ChildData* cj_data = c_get_child_data(joint_data);
    return RU::vector_to_value(cj_data->m_cur_normal);
}

VALUE MSP::PointToPointGasSpring::rbf_update_info(VALUE self) {
    Joint::Data* joint_data = Joint::c_to_data(self);
    c_update_info(joint_data);
    return Qnil;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::PointToPointGasSpring::init_ruby(VALUE mMSP) {
    VALUE cPointToPointGasSpring = rb_define_class_under(mMSP, "PointToPointGasSpring", rba_cJoint);

    rb_define_alloc_func(cPointToPointGasSpring, Joint::c_class_allocate);

    rb_define_const(cPointToPointGasSpring, "DEFAULT_EXTENDED_LENGTH", RU::to_value(DEFAULT_EXTENDED_LENGTH));
    rb_define_const(cPointToPointGasSpring, "DEFAULT_STROKE_LENGTH", RU::to_value(DEFAULT_STROKE_LENGTH));
    rb_define_const(cPointToPointGasSpring, "DEFAULT_EXTENDED_FORCE", RU::to_value(DEFAULT_EXTENDED_FORCE));
    rb_define_const(cPointToPointGasSpring, "DEFAULT_DAMP", RU::to_value(DEFAULT_DAMP));
    rb_define_const(cPointToPointGasSpring, "DEFAULT_THRESHOLD", RU::to_value(DEFAULT_THRESHOLD));

    rb_define_method(cPointToPointGasSpring, "initialize", VALUEFUNC(rbf_initialize), 6);
    rb_define_method(cPointToPointGasSpring, "get_point1", VALUEFUNC(rbf_get_point1), 0);
    rb_define_method(cPointToPointGasSpring, "set_point1", VALUEFUNC(rbf_set_point1), 1);
    rb_define_method(cPointToPointGasSpring, "get_point2", VALUEFUNC(rbf_get_point2), 0);
    rb_define_method(cPointToPointGasSpring, "set_point2", VALUEFUNC(rbf_set_point2), 1);
    rb_define_method(cPointToPointGasSpring, "extended_length", VALUEFUNC(rbf_get_extended_length), 0);
    rb_define_method(cPointToPointGasSpring, "extended_length=", VALUEFUNC(rbf_set_extended_length), 1);
    rb_define_method(cPointToPointGasSpring, "stroke_length", VALUEFUNC(rbf_get_stroke_length), 0);
    rb_define_method(cPointToPointGasSpring, "stroke_length=", VALUEFUNC(rbf_set_stroke_length), 1);
    rb_define_method(cPointToPointGasSpring, "extended_force", VALUEFUNC(rbf_get_extended_force), 0);
    rb_define_method(cPointToPointGasSpring, "extended_force=", VALUEFUNC(rbf_set_extended_force), 1);
    rb_define_method(cPointToPointGasSpring, "threshold", VALUEFUNC(rbf_get_threshold), 0);
    rb_define_method(cPointToPointGasSpring, "threshold=", VALUEFUNC(rbf_set_threshold), 1);
    rb_define_method(cPointToPointGasSpring, "damp", VALUEFUNC(rbf_get_damp), 0);
    rb_define_method(cPointToPointGasSpring, "damp=", VALUEFUNC(rbf_set_damp), 1);
    rb_define_method(cPointToPointGasSpring, "cur_length", VALUEFUNC(rbf_get_cur_length), 0);
    rb_define_method(cPointToPointGasSpring, "cur_velocity", VALUEFUNC(rbf_get_cur_velocity), 0);
    rb_define_method(cPointToPointGasSpring, "cur_normal", VALUEFUNC(rbf_get_cur_normal), 0);
    rb_define_method(cPointToPointGasSpring, "update_info", VALUEFUNC(rbf_update_info), 0);
}
