/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_body.h"
#include "msp_world.h"
#include "msp_joint.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::Body::MIN_MASS(1.0e-6);
const treal MSP::Body::MAX_MASS(1.0e14);
const treal MSP::Body::MIN_VOLUME(1.0e-6);
const treal MSP::Body::MAX_VOLUME(1.0e14);
const treal MSP::Body::MIN_DENSITY(1.0e-6);
const treal MSP::Body::MAX_DENSITY(1.0e14);
const treal MSP::Body::DEFAULT_DENSITY(700.0);
const treal MSP::Body::DEFAULT_ELASTICITY(0.40);
const treal MSP::Body::DEFAULT_SOFTNESS(0.10);
const treal MSP::Body::DEFAULT_STATIC_FRICTION_COEF(0.90);
const treal MSP::Body::DEFAULT_KINETIC_FRICTION_COEF(0.50);
const treal MSP::Body::DEFAULT_MAGNET_STRENGTH(0.0);
const Geom::Vector3d MSP::Body::DEFAULT_DIPOLE_DIR(0.0, 0.0, 1.0);
const bool MSP::Body::DEFAULT_FRICTION_ENABLED(true);
const bool MSP::Body::DEFAULT_AUTO_SLEEP_ENABLED(true);
const bool MSP::Body::DEFAULT_STATIC(false);
const bool MSP::Body::DEFAULT_COLLIDABLE(true);
const bool MSP::Body::DEFAULT_MAGNETIC(false);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Body::c_class_allocate(VALUE klass) {
    Data* data = new Data;
    return Data_Wrap_Struct(klass, c_class_mark, c_class_deallocate, data);
}

void MSP::Body::c_class_mark(void* data_ptr) {
    Data* data = reinterpret_cast<Data*>(data_ptr);
    rb_gc_mark(data->v_group);
}

void MSP::Body::c_class_deallocate(void* data_ptr) {
    Data* data = reinterpret_cast<Data*>(data_ptr);
    if (data->m_body)
        NewtonDestroyBody(data->m_body);
    delete data;
}

MSP::Body::Data* MSP::Body::c_to_data(VALUE self) {
    Data* data;
    //Data_Get_Struct(self, Data, data);
    data = reinterpret_cast<Data*>(DATA_PTR(self));
    if (data->m_body == nullptr) {
        VALUE cname = rb_class_name(CLASS_OF(self));
        rb_raise(rb_eTypeError, "Reference to deleted %s", RSTRING_PTR(cname));
    }
    return data;
}

MSP::Body::Data* MSP::Body::c_to_data(const NewtonBody* body) {
    return reinterpret_cast<Body::Data*>(NewtonBodyGetUserData(body));
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Body::destructor_callback(const NewtonBody* const body) {
    Data* body_data = c_to_data(body);
    World::Data* world_data = World::c_to_data(NewtonBodyGetWorld(body));

    if (world_data->m_bodies.find(body) != world_data->m_bodies.end())
        world_data->m_bodies.erase(body);

    if (world_data->m_magnets.find(body) != world_data->m_magnets.end())
        world_data->m_magnets.erase(body);

    body_data->m_body = nullptr;
}

void MSP::Body::transform_callback(const NewtonBody* const body, const treal* const matrix, int thread_index) {
    Data* body_data = c_to_data(body);
    body_data->m_matrix_changed = true;
}

void MSP::Body::force_and_torque_callback(const NewtonBody* const body, treal timestep, int thread_index) {
    Data* body_data = c_to_data(body);
    World::Data* world_data = World::c_to_data(NewtonBodyGetWorld(body));

    // Gravity
    Geom::Vector3d force(world_data->m_gravity.scale(body_data->m_mass));
    NewtonBodyAddForce(body, &force[0]);

    // Apply force and torque
    NewtonBodyAddForce(body, &body_data->m_applied_force[0]);
    NewtonBodyAddTorque(body, &body_data->m_applied_torque[0]);
    body_data->m_applied_force.zero_out();
    body_data->m_applied_torque.zero_out();
}

void MSP::Body::collision_iterator1(void* const user_data, int vertex_count, const treal* const face_array, int face_Id) {
    VALUE* v_mesh_ref = reinterpret_cast<VALUE*>(user_data);
    VALUE v_point;
    VALUE v_points = rb_ary_new2(vertex_count);
    VALUE v_triplet = rb_ary_new2(3);
    VALUE argv[3];
    int i, j;
    for (i = 0; i <= vertex_count; ++i) {
        j = i * 3;
        argv[0] = rb_float_new(face_array[j]);
        argv[1] = rb_float_new(face_array[j+1]);
        argv[2] = rb_float_new(face_array[j+2]);
        v_point = rb_class_new_instance(3, argv, RU::SU_POINT3D);
        rb_ary_store(v_points, i, rb_funcall(*v_mesh_ref, RU::INTERN_ADD_POINT, 1, v_point));
    }
    rb_ary_store(v_triplet, 0, rb_ary_entry(v_points, 0));
    for (i = 1; i < vertex_count - 1; ++i) {
        rb_ary_store(v_triplet, 1, rb_ary_entry(v_points, i));
        rb_ary_store(v_triplet, 2, rb_ary_entry(v_points, i + 1));
        rb_funcall(*v_mesh_ref, RU::INTERN_ADD_POLYGON, 1, v_triplet);
    }
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Body::rbf_initialize(VALUE self, VALUE v_world, VALUE v_collision, VALUE v_matrix, VALUE v_group) {
    Data* data;
    Data_Get_Struct(self, Data, data);

    World::Data* world_data = World::c_to_data_type_check(v_world);
    const NewtonCollision* col = World::c_value_to_collision(world_data, v_collision);
    CollisionData* col_data = world_data->m_collisions[col];

    Geom::Transformation matrix;
    Geom::Vector3d angular_damp(world_data->m_damp_coef, world_data->m_damp_coef, world_data->m_damp_coef);
    Geom::Vector3d v1, v2;
    VALUE v_cname1, v_cname2;

    RU::value_to_transformation3(v_matrix, matrix);
    data->m_def_tra_scale = matrix.get_scale();

    if (matrix.is_flipped()) {
        matrix.m_xaxis.reverse_self();
        data->m_def_tra_scale.m_x = -data->m_def_tra_scale.m_x;
    }
    data->m_def_tra_scale_inv.m_x = (treal)(1.0) / data->m_def_tra_scale.m_x;
    data->m_def_tra_scale_inv.m_y = (treal)(1.0) / data->m_def_tra_scale.m_y;
    data->m_def_tra_scale_inv.m_z = (treal)(1.0) / data->m_def_tra_scale.m_z;

    data->m_act_tra_scale = data->m_def_tra_scale;
    data->m_act_tra_scale_inv = data->m_def_tra_scale_inv;

    matrix.normalize_self();

    data->m_def_col_offset = col_data->m_offset;
    data->m_def_col_scale = col_data->m_scale;

    data->m_def_col_scale_inv.m_x = (treal)(1.0) / data->m_def_col_scale.m_x;
    data->m_def_col_scale_inv.m_y = (treal)(1.0) / data->m_def_col_scale.m_y;
    data->m_def_col_scale_inv.m_z = (treal)(1.0) / data->m_def_col_scale.m_z;

    if (v_group != Qnil && rb_obj_is_kind_of(v_group, RU::SU_GROUP) == Qfalse && rb_obj_is_kind_of(v_group, RU::SU_COMPONENT_INSTANCE) == Qfalse) {
        v_cname1 = rb_class_name(RU::SU_GROUP);
        v_cname2 = rb_class_name(RU::SU_COMPONENT_INSTANCE);
        rb_raise(rb_eTypeError, "Expected %s, %s, or nil", RSTRING_PTR(v_cname1), RSTRING_PTR(v_cname2));
    }

    data->m_body = NewtonCreateDynamicBody(world_data->m_world, col, &matrix[0][0]);
    data->v_group = v_group;
    data->v_self = self;

    int collision_type = NewtonCollisionGetType(col);
    if (collision_type == SERIALIZE_ID_NULL)
        data->m_volume = 1.0;
    else if (collision_type < SERIALIZE_ID_TREE)
        data->m_volume = NewtonConvexCollisionCalculateVolume(col) * M_INCH3_TO_METER3;
    else
        data->m_volume = 0.0;

    if (data->m_volume < MIN_VOLUME) {
        data->m_static = true;
        data->m_volume = 0.0;
        data->m_density = 0.0;
        data->m_mass = 0.0;
        data->m_mass_inv = 0.0;
    }
    else {
        data->m_static = false;
        data->m_volume = Geom::clamp_treal(data->m_volume, MIN_VOLUME, MAX_VOLUME);
        data->m_mass = Geom::clamp_treal(data->m_volume * data->m_density, MIN_MASS, MAX_MASS);
        data->m_mass_inv = (treal)(1.0) / data->m_mass;
    }

    data->m_can_be_dynamic = (NewtonCollisionGetType(col) < 9);

    NewtonBodySetMassProperties(data->m_body, data->m_mass, col);

    NewtonBodySetForceAndTorqueCallback(data->m_body, force_and_torque_callback);
    NewtonBodySetDestructorCallback(data->m_body, destructor_callback);
    NewtonBodySetTransformCallback(data->m_body, transform_callback);

    if (data->m_collidable)
        NewtonBodySetMaterialGroupID(data->m_body, world_data->m_material_id);
    else
        NewtonBodySetMaterialGroupID(data->m_body, world_data->m_material_id_nc);


    NewtonBodySetLinearDamping(data->m_body, world_data->m_damp_coef);
    NewtonBodySetAngularDamping(data->m_body, &angular_damp[0]);

    NewtonBodySetUserData(data->m_body, data);

    world_data->m_bodies[data->m_body] = self;

    return self;
}

VALUE MSP::Body::rbf_initialize_copy(VALUE self, VALUE orig_self) {
    // FIXME
    Data* data;
    Data* orig_data;

#ifndef RUBY_VERSION18
    if (!OBJ_INIT_COPY(self, orig_self)) return self;
#endif

    Data_Get_Struct(self, Data, data);
    Data_Get_Struct(orig_self, Data, orig_data);


    return self;
}

VALUE MSP::Body::rbf_is_valid(VALUE self) {
    Data* data;
    Data_Get_Struct(self, Data, data);
    return data->m_body ? Qtrue : Qfalse;
}

VALUE MSP::Body::rbf_destroy(VALUE self) {
    Data* data = c_to_data(self);
    NewtonDestroyBody(data->m_body);
    return Qnil;
}

VALUE MSP::Body::rbf_get_group(VALUE self) {
    Data* data = c_to_data(self);
    return data->v_group;
}

VALUE MSP::Body::rbf_get_world(VALUE self) {
    Data* data = c_to_data(self);
    World::Data* world_data = World::c_to_data(NewtonBodyGetWorld(data->m_body));
    return world_data->v_self;
}

VALUE MSP::Body::rbf_get_mass(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_mass);
}

VALUE MSP::Body::rbf_set_mass(VALUE self, VALUE v_mass) {
    Data* data = c_to_data(self);

    if (!data->m_can_be_dynamic)
        return Qnil;

    data->m_mass = Geom::clamp_treal(RU::value_to_treal(v_mass), MIN_MASS, MAX_MASS);
    data->m_mass_inv = (treal)(1.0) / data->m_mass;
    data->m_density = Geom::clamp_treal(data->m_mass / data->m_volume, MIN_DENSITY, MAX_DENSITY);

    if (!data->m_static) {
        Geom::Vector3d com;
        NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
        NewtonBodySetMassProperties(data->m_body, data->m_mass, NewtonBodyGetCollision(data->m_body));
        NewtonBodySetCentreOfMass(data->m_body, &com[0]);
    }
    return Qnil;
}

VALUE MSP::Body::rbf_get_density(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_density);
}

VALUE MSP::Body::rbf_set_density(VALUE self, VALUE v_density) {
    Data* data = c_to_data(self);

    if (!data->m_can_be_dynamic)
        return Qnil;

    data->m_density = Geom::clamp_treal(RU::value_to_treal(v_density), MIN_DENSITY, MAX_DENSITY);
    data->m_mass = Geom::clamp_treal(data->m_density * data->m_volume, MIN_MASS, MAX_MASS);
    data->m_mass_inv = (treal)(1.0) / data->m_mass;

    if (!data->m_static) {
        Geom::Vector3d com;
        NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
        NewtonBodySetMassProperties(data->m_body, data->m_mass, NewtonBodyGetCollision(data->m_body));
        NewtonBodySetCentreOfMass(data->m_body, &com[0]);
    }
    return Qnil;
}

VALUE MSP::Body::rbf_get_volume(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_volume);
}

VALUE MSP::Body::rbf_set_volume(VALUE self, VALUE v_volume) {
    Data* data = c_to_data(self);

    if (!data->m_can_be_dynamic)
        return Qnil;

    data->m_volume = Geom::clamp_treal(RU::value_to_treal(v_volume), MIN_VOLUME, MAX_VOLUME);
    data->m_mass = Geom::clamp_treal(data->m_density * data->m_volume, MIN_MASS, MAX_MASS);
    data->m_mass_inv = (treal)(1.0) / data->m_mass;

    if (!data->m_static) {
        Geom::Vector3d com;
        NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
        NewtonBodySetMassProperties(data->m_body, data->m_mass, NewtonBodyGetCollision(data->m_body));
        NewtonBodySetCentreOfMass(data->m_body, &com[0]);
    }
    return Qnil;
}

VALUE MSP::Body::rbf_get_centre_of_mass(VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d com;
    NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
    com.product_self(data->m_act_tra_scale_inv);
    return RU::point_to_value(com);
}

VALUE MSP::Body::rbf_set_centre_of_mass(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d com;
    if (argc == 3)
        RU::varry_to_vector(argv, com);
    else if (argc == 1)
        RU::value_to_vector(argv[0], com);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    com.product_self(data->m_act_tra_scale);
    NewtonBodySetCentreOfMass(data->m_body, &com[0]);
    return Qnil;
}

VALUE MSP::Body::rbf_get_mass_matrix(VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector4d inertia;
    NewtonBodyGetMass(data->m_body, &inertia.m_w, &inertia.m_x, &inertia.m_y, &inertia.m_z);
    return rb_ary_new3(
        4,
        RU::to_value(inertia.m_x * M_INCH2_TO_METER2),
        RU::to_value(inertia.m_y * M_INCH2_TO_METER2),
        RU::to_value(inertia.m_z * M_INCH2_TO_METER2),
        RU::to_value(inertia.m_w));
}

VALUE MSP::Body::rbf_set_mass_matrix(VALUE self, VALUE v_ixx, VALUE v_iyy, VALUE v_izz, VALUE v_mass) {
    Data* data = c_to_data(self);
    treal ixx, iyy, izz, mass;
    ixx = RU::value_to_treal(v_ixx) * M_METER2_TO_INCH2;
    iyy = RU::value_to_treal(v_iyy) * M_METER2_TO_INCH2;
    izz = RU::value_to_treal(v_izz) * M_METER2_TO_INCH2;
    mass = RU::value_to_treal(v_mass);
    NewtonBodySetMassMatrix(data->m_body, mass, ixx, iyy, izz);
    return Qnil;
}

VALUE MSP::Body::rbf_get_velocity(VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d veloc;
    NewtonBodyGetVelocity(data->m_body, &veloc[0]);
    return RU::vector_to_value2(veloc, M_INCH_TO_METER);
}

VALUE MSP::Body::rbf_set_velocity(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d veloc;
    if (argc == 3)
        RU::varry_to_vector2(argv, veloc, M_METER_TO_INCH);
    else if (argc == 1)
        RU::value_to_vector2(argv[0], veloc, M_METER_TO_INCH);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    NewtonBodySetVelocity(data->m_body, &veloc[0]);
    return Qnil;
}

VALUE MSP::Body::rbf_get_omega(VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d omega;
    NewtonBodyGetOmega(data->m_body, &omega[0]);
    return RU::vector_to_value(omega);
}

VALUE MSP::Body::rbf_set_omega(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d omega;
    if (argc == 3)
        RU::varry_to_vector(argv, omega);
    else if (argc == 1)
        RU::value_to_vector(argv[0], omega);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    NewtonBodySetOmega(data->m_body, &omega[0]);
    return Qnil;
}

VALUE MSP::Body::rbf_get_point_velocity(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d point, veloc;
    if (argc == 3)
        RU::varry_to_vector(argv, point);
    else if (argc == 1)
        RU::value_to_vector(argv[0], point);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    NewtonBodyGetPointVelocity(data->m_body, &point[0], &veloc[0]);
    return RU::vector_to_value2(veloc, M_INCH_TO_METER);
}

VALUE MSP::Body::rbf_get_transformation(VALUE self) {
    Data* data = c_to_data(self);
    Geom::Transformation matrix;
    NewtonBodyGetMatrix(data->m_body, &matrix[0][0]);
    matrix.scale_axes_self(data->m_act_tra_scale);
    return RU::transformation_to_value(matrix);
}

VALUE MSP::Body::rbf_set_transformation(VALUE self, VALUE v_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation matrix;
    RU::value_to_transformation3(v_matrix, matrix);
    if (matrix.is_flipped())
        matrix.m_xaxis.reverse_self();
    matrix.normalize_self();
    NewtonBodySetMatrix(data->m_body, &matrix[0][0]);
    data->m_matrix_changed = true;
    return Qnil;
}

VALUE MSP::Body::rbf_get_position(VALUE self, VALUE v_mode) {
    Data* data = c_to_data(self);
    Geom::Transformation matrix;
    NewtonBodyGetMatrix(data->m_body, &matrix[0][0]);
    if (RU::value_to_int(v_mode) == 1) {
        Geom::Vector3d com;
        NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
        return RU::point_to_value(matrix.transform_vector2(com));
    }
    else
        return RU::point_to_value(matrix.m_origin);
}

VALUE MSP::Body::rbf_set_position(VALUE self, VALUE v_mode, VALUE v_position) {
    Data* data = c_to_data(self);
    Geom::Vector3d pos;
    Geom::Transformation matrix;
    RU::value_to_vector(v_position, pos);
    NewtonBodyGetMatrix(data->m_body, &matrix[0][0]);
    if (RU::value_to_int(v_mode) == 1) {
        Geom::Vector3d com;
        NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
        com = matrix.transform_vector2(com);
        pos += com - matrix.m_origin;
    }
    matrix.m_origin = pos;
    NewtonBodySetMatrix(data->m_body, &matrix[0][0]);
    data->m_matrix_changed = true;
    return Qnil;
}

VALUE MSP::Body::rbf_get_rotation(VALUE self) {
    Data* data = c_to_data(self);
    treal rot[4];
    NewtonBodyGetRotation(data->m_body, rot);
    return rb_ary_new3(4,
        RU::to_value(rot[0]),
        RU::to_value(rot[1]),
        RU::to_value(rot[2]),
        RU::to_value(rot[3]));
}

VALUE MSP::Body::rbf_get_euler_angles(VALUE self) {
    Data* data = c_to_data(self);
    Geom::Transformation matrix;
    Geom::Vector3d angles0, angles1;
    NewtonBodyGetMatrix(data->m_body, &matrix[0][0]);
    NewtonGetEulerAngle(&matrix[0][0], &angles0[0], &angles1[0]);
    return RU::vector_to_value(angles0);
}

VALUE MSP::Body::rbf_set_euler_angles(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d angles;
    Geom::Transformation matrix;
    if (argc == 3)
        RU::varry_to_vector(argv, angles);
    else if (argc == 1)
        RU::value_to_vector(argv[0], angles);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    NewtonBodyGetMatrix(data->m_body, &matrix[0][0]);
    NewtonSetEulerAngle(&angles[0], &matrix[0][0]);
    NewtonBodySetMatrix(data->m_body, &matrix[0][0]);
    data->m_matrix_changed = true;
    return Qnil;
}

VALUE MSP::Body::rbf_get_scale(VALUE self) {
    Data* data = c_to_data(self);
    return RU::vector_to_value(data->m_act_tra_scale.product(data->m_def_tra_scale_inv));
}

VALUE MSP::Body::rbf_set_scale(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d scale, com;
    Geom::Transformation col_matrix;
    if (argc == 3)
        RU::varry_to_vector(argv, scale);
    else if (argc == 1)
        RU::value_to_vector(argv[0], scale);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    const NewtonCollision* col = NewtonBodyGetCollision(data->m_body);
    if (NewtonCollisionGetType(col) > 6)
        rb_raise(rb_eTypeError, "Only convex collisions can be scaled!");
    scale.m_x = Geom::clamp_treal(scale.m_x, (treal)(0.01), (treal)(100.0));
    scale.m_y = Geom::clamp_treal(scale.m_y, (treal)(0.01), (treal)(100.0));
    scale.m_z = Geom::clamp_treal(scale.m_z, (treal)(0.01), (treal)(100.0));

    NewtonCollisionGetMatrix(col, &col_matrix[0][0]);
    col_matrix.m_origin = data->m_def_col_offset.product(scale).product(data->m_def_col_scale_inv);
    NewtonCollisionSetMatrix(col, &col_matrix[0][0]);

    NewtonBodySetCollisionScale(
        data->m_body,
        data->m_def_col_scale.m_x * scale.m_x,
        data->m_def_col_scale.m_y * scale.m_y,
        data->m_def_col_scale.m_z * scale.m_z);

    data->m_volume = Geom::clamp_treal(NewtonConvexCollisionCalculateVolume(col) * M_INCH3_TO_METER3, MIN_VOLUME, MAX_VOLUME);
    data->m_mass = Geom::clamp_treal(data->m_density * data->m_volume, MIN_MASS, MAX_MASS);
    data->m_mass_inv = (treal)(1.0) / data->m_mass;

    if (!data->m_static) {
        NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
        NewtonBodySetMassProperties(data->m_body, data->m_mass, col);
        NewtonBodySetCentreOfMass(data->m_body, &com[0]);
    }
    NewtonBodySetSleepState(data->m_body, 0);
    data->m_matrix_changed = true;

    data->m_act_tra_scale = data->m_def_tra_scale.product(scale);
    data->m_act_tra_scale_inv.m_x = (treal)(1.0) / data->m_act_tra_scale.m_x;
    data->m_act_tra_scale_inv.m_y = (treal)(1.0) / data->m_act_tra_scale.m_y;
    data->m_act_tra_scale_inv.m_z = (treal)(1.0) / data->m_act_tra_scale.m_z;

    return Qnil;
}

VALUE MSP::Body::rbf_get_aabb(VALUE self) {
    Data* data = c_to_data(self);
    Geom::BoundingBox bb;
    NewtonBodyGetAABB(data->m_body, &bb.m_min[0], &bb.m_max[0]);
    return RU::bb_to_value(bb);
}

VALUE MSP::Body::rbf_is_static(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_static);
}

VALUE MSP::Body::rbf_set_static(VALUE self, VALUE v_state) {
    Data* data = c_to_data(self);
    bool state = RU::value_to_bool(v_state);
    if (data->m_can_be_dynamic && state != data->m_static) {
        Geom::Vector3d com;
        const NewtonCollision* col = NewtonBodyGetCollision(data->m_body);
        NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
        if (state)
            NewtonBodySetMassProperties(data->m_body, 0.0, col);
        else
            NewtonBodySetMassProperties(data->m_body, data->m_mass, col);
        NewtonBodySetCentreOfMass(data->m_body, &com[0]);
        NewtonBodySetVelocity(data->m_body, &Geom::Vector3d::ORIGIN[0]);
        NewtonBodySetOmega(data->m_body, &Geom::Vector3d::ORIGIN[0]);
        NewtonBodySetSleepState(data->m_body, 0);
        NewtonBodySetAutoSleep(data->m_body, data->m_auto_sleep_enabled ? 1 : 0);
        data->m_static = state;
        data->m_applied_force.zero_out();
        data->m_applied_torque.zero_out();
    }
    return Qnil;
}

VALUE MSP::Body::rbf_is_collidable(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_collidable);
}

VALUE MSP::Body::rbf_set_collidable(VALUE self, VALUE v_state) {
    Data* data = c_to_data(self);
    bool state = RU::value_to_bool(v_state);
    if (state != data->m_collidable) {
        World::Data* world_data = World::c_to_data(NewtonBodyGetWorld(data->m_body));
        if (state)
            NewtonBodySetMaterialGroupID(data->m_body, world_data->m_material_id);
        else
            NewtonBodySetMaterialGroupID(data->m_body, world_data->m_material_id_nc);
        data->m_collidable = state;
    }
    return Qnil;
}

VALUE MSP::Body::rbf_is_frozen(VALUE self) {
    Data* data = c_to_data(self);
    return (NewtonBodyGetFreezeState(data->m_body) == 1) ? Qtrue : Qfalse;
}

VALUE MSP::Body::rbf_set_frozen(VALUE self, VALUE v_state) {
    Data* data = c_to_data(self);
    bool state = RU::value_to_bool(v_state);
    if (state) {
        NewtonBodySetFreezeState(data->m_body, 1);
        NewtonBodySetSleepState(data->m_body, 1);
    }
    else {
        NewtonBodySetFreezeState(data->m_body, 0);
        NewtonBodySetSleepState(data->m_body, 0);
    }
    return Qnil;
}

VALUE MSP::Body::rbf_is_asleep(VALUE self) {
    Data* data = c_to_data(self);
    return (NewtonBodyGetSleepState(data->m_body) == 1) ? Qtrue : Qfalse;
}

VALUE MSP::Body::rbf_activate(VALUE self) {
    Data* data = c_to_data(self);
    NewtonBodySetSleepState(data->m_body, 0);
    return Qnil;
}

VALUE MSP::Body::rbf_is_magnetic(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_magnetic);
}

VALUE MSP::Body::rbf_set_magnetic(VALUE self, VALUE v_state) {
    Data* data = c_to_data(self);
    data->m_magnetic = RU::value_to_bool(v_state);
    return Qnil;
}

VALUE MSP::Body::rbf_get_auto_sleep_state(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_auto_sleep_enabled);
}

VALUE MSP::Body::rbf_set_auto_sleep_state(VALUE self, VALUE v_state) {
    Data* data = c_to_data(self);
    data->m_auto_sleep_enabled = RU::value_to_bool(v_state);
    NewtonBodySetAutoSleep(data->m_body, data->m_auto_sleep_enabled ? 1 : 0);
    return Qnil;
}

VALUE MSP::Body::rbf_get_continuous_collision_state(VALUE self) {
    Data* data = c_to_data(self);
    return (NewtonBodyGetContinuousCollisionMode(data->m_body) == 1) ? Qtrue : Qfalse;
}

VALUE MSP::Body::rbf_set_continuous_collision_state(VALUE self, VALUE v_state) {
    Data* data = c_to_data(self);
    NewtonBodySetContinuousCollisionMode(data->m_body, RU::value_to_bool(v_state) ? 1 : 0);
    return Qnil;
}

VALUE MSP::Body::rbf_get_friction_state(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_friction_enabled);
}

VALUE MSP::Body::rbf_set_friction_state(VALUE self, VALUE v_state) {
    Data* data = c_to_data(self);
    data->m_friction_enabled = RU::value_to_bool(v_state);
    return Qnil;
}

VALUE MSP::Body::rbf_get_elasticity(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_elasticity);
}

VALUE MSP::Body::rbf_set_elasticity(VALUE self, VALUE v_coef) {
    Data* data = c_to_data(self);
    data->m_elasticity = Geom::clamp_treal(RU::value_to_treal(v_coef), 0.01, 2.00);
    return Qnil;
}

VALUE MSP::Body::rbf_get_softness(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_softness);
}

VALUE MSP::Body::rbf_set_softness(VALUE self, VALUE v_coef) {
    Data* data = c_to_data(self);
    data->m_softness = Geom::clamp_treal(RU::value_to_treal(v_coef), 0.01, 1.00);
    return Qnil;
}

VALUE MSP::Body::rbf_get_static_friction(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_static_friction);
}

VALUE MSP::Body::rbf_set_static_friction(VALUE self, VALUE v_coef) {
    Data* data = c_to_data(self);
    data->m_static_friction = Geom::clamp_treal(RU::value_to_treal(v_coef), 0.01, 2.00);
    return Qnil;
}

VALUE MSP::Body::rbf_get_kinetic_friction(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_kinetic_friction);
}

VALUE MSP::Body::rbf_set_kinetic_friction(VALUE self, VALUE v_coef) {
    Data* data = c_to_data(self);
    data->m_kinetic_friction = Geom::clamp_treal(RU::value_to_treal(v_coef), 0.01, 2.00);
    return Qnil;
}

VALUE MSP::Body::rbf_get_dipole_dir(VALUE self) {
    Data* data = c_to_data(self);
    return RU::vector_to_value(data->m_dipole_dir);
}

VALUE MSP::Body::rbf_set_dipole_dir(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d dir;
    if (argc == 3)
        RU::varry_to_vector(argv, dir);
    else if (argc == 1)
        RU::value_to_vector(argv[0], dir);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    treal mag_sq = dir.get_length_squared();
    if (mag_sq > M_EPSILON_SQ)
        data->m_dipole_dir = dir.scale((treal)(1.0) / sqrt(mag_sq));
    return Qnil;
}

VALUE MSP::Body::rbf_get_magnet_strength(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_magnet_strength);
}

VALUE MSP::Body::rbf_set_magnet_strength(VALUE self, VALUE v_strength) {
    Data* data = c_to_data(self);
    World::Data* world_data = World::c_to_data(NewtonBodyGetWorld(data->m_body));
    data->m_magnet_strength = RU::value_to_treal(v_strength);
    if (fabs(data->m_magnet_strength) > M_EPSILON)
        world_data->m_magnets.insert(data->m_body);
    else if (world_data->m_magnets.find(data->m_body) != world_data->m_magnets.end())
        world_data->m_magnets.erase(data->m_body);
    return Qnil;
}

VALUE MSP::Body::rbf_apply_impulse(VALUE self, VALUE v_center, VALUE v_delta_vel) {
    Data* data = c_to_data(self);
    World::Data* world_data = World::c_to_data(NewtonBodyGetWorld(data->m_body));
    Geom::Vector3d center, delta_vel;
    RU::value_to_vector(v_center, center);
    RU::value_to_vector2(v_center, center, M_METER_TO_INCH);
    NewtonBodyAddImpulse(data->m_body, &center[0], &delta_vel[0], world_data->m_timestep);
    return Qnil;
}

VALUE MSP::Body::rbf_apply_force_at_point(VALUE self, VALUE v_point, VALUE v_force) {
    Data* data = c_to_data(self);
    Geom::Vector3d point, force, torque, centre;
    Geom::Transformation matrix;
    RU::value_to_vector(v_point, point);
    RU::value_to_vector2(v_force, force, M_METER_TO_INCH);
    NewtonBodyGetCentreOfMass(data->m_body, &centre[0]);
    NewtonBodyGetMatrix(data->m_body, &matrix[0][0]);
    centre = matrix.transform_vector2(centre);
    torque = (point - centre).cross(force);
    data->m_applied_force += force;
    data->m_applied_torque += torque;
    return Qnil;
}

VALUE MSP::Body::rbf_apply_force(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d force;
    if (argc == 3)
        RU::varry_to_vector2(argv, force, M_METER_TO_INCH);
    else if (argc == 1)
        RU::value_to_vector2(argv[0], force, M_METER_TO_INCH);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    data->m_applied_force += force;
    return Qnil;
}

VALUE MSP::Body::rbf_apply_torque(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d torque;
    if (argc == 3)
        RU::varry_to_vector2(argv, torque, M_METER2_TO_INCH2);
    else if (argc == 1)
        RU::value_to_vector2(argv[0], torque, M_METER2_TO_INCH2);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    data->m_applied_torque += torque;
    return Qnil;
}

VALUE MSP::Body::rbf_get_acceleration(VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d acceleration;
    NewtonBodyGetAcceleration(data->m_body, &acceleration[0]);
    return RU::vector_to_value2(acceleration, M_INCH_TO_METER);
}

VALUE MSP::Body::rbf_get_alpha(VALUE self) {
    Data* data = c_to_data(self);
    Geom::Vector3d alpha;
    NewtonBodyGetAlpha(data->m_body, &alpha[0]);
    return RU::vector_to_value2(alpha, M_INCH2_TO_METER2);
}

VALUE MSP::Body::rbf_get_tension(VALUE self) {
    Data* data = c_to_data(self);
    // Linear tension is obtained by obtaining the net force of all contacts and joints.
    Geom::Vector3d tension(0.0);
    Geom::Vector3d force;
    NewtonJoint* joint;
    void* contact;
    NewtonMaterial* material;
    Joint::Data* joint_data;
    for (joint = NewtonBodyGetFirstContactJoint(data->m_body); joint; joint = NewtonBodyGetNextContactJoint(data->m_body, joint)) {
        for (contact = NewtonContactJointGetFirstContact(joint); contact; contact = NewtonContactJointGetNextContact(joint, contact)) {
            material = NewtonContactGetMaterial(contact);
            NewtonMaterialGetContactForce(material, data->m_body, &force[0]);
            tension += force;
        }
    }
    for (joint = NewtonBodyGetFirstJoint(data->m_body); joint; joint = NewtonBodyGetNextJoint(data->m_body, joint)) {
        joint_data = Joint::c_to_data(joint);
        tension += joint_data->m_tension1;
    }
    return RU::vector_to_value2(tension, M_INCH_TO_METER);
}

VALUE MSP::Body::rbf_get_contained_joints(VALUE self) {
    Data* data = c_to_data(self);
    Joint::Data* joint_data;
    NewtonJoint* joint;
    VALUE v_joints = rb_ary_new();
    for (joint = NewtonBodyGetFirstJoint(data->m_body); joint; joint = NewtonBodyGetNextJoint(data->m_body, joint)) {
        joint_data = Joint::c_to_data(joint);
        if (joint_data->m_parent == data->m_body)
            rb_ary_push(v_joints, joint_data->v_self);
    }
    return v_joints;
}

VALUE MSP::Body::rbf_get_connected_joints(VALUE self) {
    Data* data = c_to_data(self);
    Joint::Data* joint_data;
    NewtonJoint* joint;
    VALUE v_joints = rb_ary_new();
    for (joint = NewtonBodyGetFirstJoint(data->m_body); joint; joint = NewtonBodyGetNextJoint(data->m_body, joint)) {
        joint_data = Joint::c_to_data(joint);
        if (joint_data->m_child == data->m_body)
            rb_ary_push(v_joints, joint_data->v_self);
    }
    return v_joints;
}

VALUE MSP::Body::rbf_get_connected_bodies(VALUE self) {
    Data* data = c_to_data(self);
    Joint::Data* joint_data;
    NewtonJoint* joint;
    VALUE v_bodies = rb_ary_new();
    for (joint = NewtonBodyGetFirstJoint(data->m_body); joint; joint = NewtonBodyGetNextJoint(data->m_body, joint)) {
        joint_data = Joint::c_to_data(joint);
        if (joint_data->m_parent == data->m_body)
            rb_ary_push(v_bodies, Body::c_to_data(joint_data->m_child)->v_self);
        else if (joint_data->m_child == data->m_body && joint_data->m_parent != nullptr)
            rb_ary_push(v_bodies, Body::c_to_data(joint_data->m_parent)->v_self);
    }
    return v_bodies;
}

VALUE MSP::Body::rbf_apply_pick_and_drag(VALUE self, VALUE v_pick_pt, VALUE v_dest_pt, VALUE v_stiffness, VALUE v_damp) {
    Data* data = c_to_data(self);
    World::Data* world_data = World::c_to_data(NewtonBodyGetWorld(data->m_body));
    Geom::Transformation matrix;
    Geom::Vector3d pick_pt, dest_pt, com, velocity, omega, des_vel, force, torque;
    treal stiff, damp;

    RU::value_to_vector(v_pick_pt, pick_pt);
    RU::value_to_vector(v_dest_pt, dest_pt);
    stiff = Geom::clamp_treal(RU::value_to_treal(v_stiffness), 0.0, 1.0);
    damp = Geom::clamp_treal(RU::value_to_treal(v_damp), 0.0, 1.0);

    NewtonBodyGetMatrix(data->m_body, &matrix[0][0]);
    NewtonBodyGetCentreOfMass(data->m_body, &com[0]);
    NewtonBodyGetVelocity(data->m_body, &velocity[0]);
    NewtonBodyGetOmega(data->m_body, &omega[0]);
    com = matrix.transform_vector2(com);

    des_vel = (dest_pt - pick_pt).scale(((treal)(1.0) - damp) / world_data->m_timestep);
    force = (des_vel - velocity).scale(data->m_mass * stiff / world_data->m_timestep);
    torque = (pick_pt - com).cross(force);

    data->m_applied_force += force;
    data->m_applied_torque += torque;

    NewtonBodySetFreezeState(data->m_body, 0);
    NewtonBodySetSleepState(data->m_body, 0);

    return Qnil;
}

VALUE MSP::Body::rbf_apply_buoyancy(VALUE self, VALUE v_plane_origin, VALUE v_plane_normal, VALUE v_density, VALUE v_linear_viscosity, VALUE v_angular_viscosity, VALUE v_linear_current, VALUE v_angular_current) {
    Data* data = c_to_data(self);
    // FIXME
    return Qnil;
}

VALUE MSP::Body::rbf_get_contacts(VALUE self, VALUE v_inc_non_collidable) {
    Data* data = c_to_data(self);
    // FIXME
    return Qnil;
}

VALUE MSP::Body::rbf_get_touching_bodies(VALUE self, VALUE v_inc_non_collidable) {
    Data* data = c_to_data(self);
    // FIXME
    return Qnil;
}

VALUE MSP::Body::rbf_is_touching_with(VALUE self, VALUE v_other_body) {
    Data* data = c_to_data(self);
    // FIXME
    return Qnil;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Body::init_ruby(VALUE mMSP) {
    rba_cBody = rb_define_class_under(mMSP, "Body", rba_cEntity);

    rb_define_alloc_func(rba_cBody, c_class_allocate);

    rb_define_method(rba_cBody, "initialize", VALUEFUNC(rbf_initialize), 4);
    rb_define_method(rba_cBody, "initialize_copy", VALUEFUNC(rbf_initialize_copy), 1);
    rb_define_method(rba_cBody, "valid?", VALUEFUNC(rbf_is_valid), 0);
    rb_define_method(rba_cBody, "destroy", VALUEFUNC(rbf_destroy), 0);
    rb_define_method(rba_cBody, "group", VALUEFUNC(rbf_get_group), 0);
    rb_define_method(rba_cBody, "world", VALUEFUNC(rbf_get_world), 0);

    rb_define_method(rba_cBody, "mass", VALUEFUNC(rbf_get_mass), 0);
    rb_define_method(rba_cBody, "mass=", VALUEFUNC(rbf_set_mass), 1);
    rb_define_method(rba_cBody, "density", VALUEFUNC(rbf_get_density), 0);
    rb_define_method(rba_cBody, "density=", VALUEFUNC(rbf_set_density), 1);
    rb_define_method(rba_cBody, "volume", VALUEFUNC(rbf_get_volume), 0);
    rb_define_method(rba_cBody, "volume=", VALUEFUNC(rbf_set_volume), 1);

    rb_define_method(rba_cBody, "get_centre_of_mass", VALUEFUNC(rbf_get_centre_of_mass), 0);
    rb_define_method(rba_cBody, "set_centre_of_mass", VALUEFUNC(rbf_set_centre_of_mass), -1);
    rb_define_method(rba_cBody, "get_mass_matrix", VALUEFUNC(rbf_get_mass_matrix), 0);
    rb_define_method(rba_cBody, "set_mass_matrix", VALUEFUNC(rbf_set_mass_matrix), 4);

    rb_define_method(rba_cBody, "get_velocity", VALUEFUNC(rbf_get_velocity), 0);
    rb_define_method(rba_cBody, "set_velocity", VALUEFUNC(rbf_set_velocity), -1);
    rb_define_method(rba_cBody, "get_point_velocity", VALUEFUNC(rbf_get_point_velocity), -1);
    rb_define_method(rba_cBody, "get_omega", VALUEFUNC(rbf_get_omega), 0);
    rb_define_method(rba_cBody, "set_omega", VALUEFUNC(rbf_set_omega), -1);
    rb_define_method(rba_cBody, "get_transformation", VALUEFUNC(rbf_get_transformation), 0);
    rb_define_method(rba_cBody, "set_transformation", VALUEFUNC(rbf_set_transformation), 1);
    rb_define_method(rba_cBody, "get_position", VALUEFUNC(rbf_get_position), 1);
    rb_define_method(rba_cBody, "set_position", VALUEFUNC(rbf_set_position), 2);
    rb_define_method(rba_cBody, "get_rotation", VALUEFUNC(rbf_get_rotation), 0);
    rb_define_method(rba_cBody, "get_euler_angles", VALUEFUNC(rbf_get_euler_angles), 0);
    rb_define_method(rba_cBody, "set_euler_angles", VALUEFUNC(rbf_set_euler_angles), -1);
    rb_define_method(rba_cBody, "get_scale", VALUEFUNC(rbf_get_scale), 0);
    rb_define_method(rba_cBody, "set_scale", VALUEFUNC(rbf_set_scale), -1);

    rb_define_method(rba_cBody, "bounds", VALUEFUNC(rbf_get_aabb), 0);

    rb_define_method(rba_cBody, "static?", VALUEFUNC(rbf_is_static), 0);
    rb_define_method(rba_cBody, "static=", VALUEFUNC(rbf_set_static), 1);
    rb_define_method(rba_cBody, "collidable?", VALUEFUNC(rbf_is_collidable), 0);
    rb_define_method(rba_cBody, "collidable=", VALUEFUNC(rbf_set_collidable), 1);
    rb_define_method(rba_cBody, "frozen?", VALUEFUNC(rbf_is_frozen), 0);
    rb_define_method(rba_cBody, "frozen=", VALUEFUNC(rbf_set_frozen), 1);
    rb_define_method(rba_cBody, "asleep?", VALUEFUNC(rbf_is_asleep), 0);
    rb_define_method(rba_cBody, "activate!", VALUEFUNC(rbf_activate), 0);
    rb_define_method(rba_cBody, "magnetic?", VALUEFUNC(rbf_is_magnetic), 0);
    rb_define_method(rba_cBody, "magnetic=", VALUEFUNC(rbf_set_magnetic), 1);

    rb_define_method(rba_cBody, "auto_sleep_enabled?", VALUEFUNC(rbf_get_auto_sleep_state), 0);
    rb_define_method(rba_cBody, "auto_sleep_enabled=", VALUEFUNC(rbf_set_auto_sleep_state), 1);
    rb_define_method(rba_cBody, "continuous_collision_check_enabled?", VALUEFUNC(rbf_get_continuous_collision_state), 0);
    rb_define_method(rba_cBody, "continuous_collision_check_enabled=", VALUEFUNC(rbf_set_continuous_collision_state), 1);
    rb_define_method(rba_cBody, "friction_enabled?", VALUEFUNC(rbf_get_friction_state), 0);
    rb_define_method(rba_cBody, "friction_enabled=", VALUEFUNC(rbf_set_friction_state), 1);

    rb_define_method(rba_cBody, "elasticity", VALUEFUNC(rbf_get_elasticity), 0);
    rb_define_method(rba_cBody, "elasticity=", VALUEFUNC(rbf_set_elasticity), 1);
    rb_define_method(rba_cBody, "softness", VALUEFUNC(rbf_get_softness), 0);
    rb_define_method(rba_cBody, "softness=", VALUEFUNC(rbf_set_softness), 1);
    rb_define_method(rba_cBody, "static_friction", VALUEFUNC(rbf_get_static_friction), 0);
    rb_define_method(rba_cBody, "static_friction=", VALUEFUNC(rbf_set_static_friction), 1);
    rb_define_method(rba_cBody, "kinetic_friction", VALUEFUNC(rbf_get_kinetic_friction), 0);
    rb_define_method(rba_cBody, "kinetic_friction=", VALUEFUNC(rbf_set_kinetic_friction), 1);

    rb_define_method(rba_cBody, "get_dipole_dir", VALUEFUNC(rbf_get_dipole_dir), 0);
    rb_define_method(rba_cBody, "set_dipole_dir", VALUEFUNC(rbf_set_dipole_dir), -1);
    rb_define_method(rba_cBody, "magnet_strength", VALUEFUNC(rbf_get_magnet_strength), 0);
    rb_define_method(rba_cBody, "magnet_strength=", VALUEFUNC(rbf_set_magnet_strength), 1);

    rb_define_method(rba_cBody, "apply_impulse", VALUEFUNC(rbf_apply_impulse), 2);
    rb_define_method(rba_cBody, "apply_point_force", VALUEFUNC(rbf_apply_force_at_point), 2);
    rb_define_method(rba_cBody, "apply_force", VALUEFUNC(rbf_apply_force), -1);
    rb_define_method(rba_cBody, "apply_torque", VALUEFUNC(rbf_apply_torque), -1);

    rb_define_method(rba_cBody, "get_acceleration", VALUEFUNC(rbf_get_acceleration), 0);
    rb_define_method(rba_cBody, "get_alpha", VALUEFUNC(rbf_get_alpha), 0);
    rb_define_method(rba_cBody, "get_tension", VALUEFUNC(rbf_get_tension), 0);

    rb_define_method(rba_cBody, "contained_joints", VALUEFUNC(rbf_get_contained_joints), 0);
    rb_define_method(rba_cBody, "connected_joints", VALUEFUNC(rbf_get_connected_joints), 0);
    rb_define_method(rba_cBody, "connected_bodies", VALUEFUNC(rbf_get_connected_bodies), 0);

    rb_define_method(rba_cBody, "apply_pick_and_drag", VALUEFUNC(rbf_apply_pick_and_drag), 4);
    rb_define_method(rba_cBody, "apply_buoyancy", VALUEFUNC(rbf_apply_buoyancy), 7);

    rb_define_method(rba_cBody, "contacts", VALUEFUNC(rbf_get_contacts), 1);
    rb_define_method(rba_cBody, "touching_bodies", VALUEFUNC(rbf_get_touching_bodies), 1);
    rb_define_method(rba_cBody, "touching_with?", VALUEFUNC(rbf_is_touching_with), 1);
}
