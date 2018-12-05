/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_world.h"
#include "msp_hit.h"
#include "msp_contact.h"
#include "msp_body.h"
#include "msp_joint.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constants
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

const treal MSP::World::DEFAULT_GRAVITY_X(0.0);
const treal MSP::World::DEFAULT_GRAVITY_Y(0.0);
const treal MSP::World::DEFAULT_GRAVITY_Z(-9.8);
const treal MSP::World::DEFAULT_WIND_X(0.0);
const treal MSP::World::DEFAULT_WIND_Y(0.0);
const treal MSP::World::DEFAULT_WIND_Z(0.0);
const treal MSP::World::MIN_TOUCH_DISTANCE(0.005);
const treal MSP::World::MIN_TIMESTEP(1.0 / 1200.0);
const treal MSP::World::MAX_TIMESTEP(1.0 / 30.0);
const treal MSP::World::DEFAULT_TIMESTEP(1.0 / 60.0);
const treal MSP::World::CONTACT_MERGE_TOLERANCE(0.005);
const treal MSP::World::MATERIAL_THICKNESS(0.005);
const treal MSP::World::MATERIAL_STATIC_FRICTION_COEF(0.90);
const treal MSP::World::MATERIAL_KINETIC_FRICTION_COEF(0.50);
const treal MSP::World::MATERIAL_ELASTICITY(0.40);
const treal MSP::World::MATERIAL_SOFTNESS(0.10);
const treal MSP::World::DEFAULT_DRAG_COEFFICIENT(0.00);
const treal MSP::World::DEFAULT_DAMP_COEFFICIENT(0.01);
const treal MSP::World::MIN_COL_SIZE(1.0e-4);
const treal MSP::World::MAX_COL_SIZE(1.0e5);
const int MSP::World::DEFAULT_SOLVER_MODEL(4);


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::World::c_class_allocate(VALUE klass) {
    Data* data = new Data;

    return Data_Wrap_Struct(klass, c_class_mark, c_class_deallocate, data);
}

void MSP::World::c_class_mark(void* data_ptr) {
    Data* data = reinterpret_cast<Data*>(data_ptr);
    // Mark all Body, Joint, and Gear instances so they are not GCd
    //  until the world is destroyed
    for (std::map<const NewtonBody*, VALUE>::iterator it = data->m_bodies.begin(); it != data->m_bodies.end(); ++it)
        rb_gc_mark(it->second);
    for (std::map<const NewtonJoint*, VALUE>::iterator it = data->m_joints.begin(); it != data->m_joints.end(); ++it) {
        rb_gc_mark(it->second);
    }
    for (std::set<VALUE>::iterator it = data->m_gears.begin(); it != data->m_gears.end(); ++it)
        rb_gc_mark(*it);
}

void MSP::World::c_class_deallocate(void* data_ptr) {
    Data* data = reinterpret_cast<Data*>(data_ptr);
    if (data->m_world)
        NewtonDestroy(data->m_world);
    delete data;
}

MSP::World::Data* MSP::World::c_to_data(VALUE v_world) {
    Data* data;
    //Data_Get_Struct(self, Data, data);
    data = reinterpret_cast<Data*>(DATA_PTR(v_world));
    if (data->m_world == nullptr) {
        VALUE cname = rb_class_name(CLASS_OF(v_world));
        rb_raise(rb_eTypeError, "Reference to deleted %s", RSTRING_PTR(cname));
    }
    return data;
}

MSP::World::Data* MSP::World::c_to_data(const NewtonWorld* world) {
    return reinterpret_cast<World::Data*>(NewtonWorldGetUserData(world));
}

MSP::World::Data* MSP::World::c_to_data_simple_cast(VALUE v_world) {
    return reinterpret_cast<Data*>(DATA_PTR(v_world));
}

MSP::World::Data* MSP::World::c_to_data_type_check(VALUE v_world) {
    if (rb_obj_is_instance_of(v_world, rba_cWorld) == Qtrue) {
        return c_to_data(v_world);
    }
    else {
        VALUE cname = rb_class_name(rba_cWorld);
        rb_raise(rb_eTypeError, "Expected a %s object", RSTRING_PTR(cname));
    }
}

const NewtonBody* MSP::World::c_value_to_body(Data* world_data, VALUE v_body) {
    if (rb_obj_is_instance_of(v_body, rba_cBody) == Qtrue) {
        Body::Data* body_data = Body::c_to_data(v_body);
        if (world_data->m_bodies.find(body_data->m_body) != world_data->m_bodies.end()) {
            return body_data->m_body;
        }
        else {
            VALUE cname = rb_class_name(rba_cBody);
            rb_raise(rb_eTypeError, "The specified %s object is either invalid or belongs to a different world", RSTRING_PTR(cname));
        }
    }
    else {
        VALUE cname = rb_class_name(rba_cBody);
        rb_raise(rb_eTypeError, "Expected a %s object", RSTRING_PTR(cname));
    }
}

const NewtonJoint* MSP::World::c_value_to_joint(Data* world_data, VALUE v_joint) {
    if (rb_obj_is_instance_of(v_joint, rba_cJoint) == Qtrue) {
        Joint::Data* joint_data = Joint::c_to_data(v_joint);
        if (world_data->m_joints.find(joint_data->m_joint) != world_data->m_joints.end()) {
            return joint_data->m_joint;
        }
        else {
            VALUE cname = rb_class_name(rba_cJoint);
            rb_raise(rb_eTypeError, "The specified %s object is either invalid or belongs to a different world", RSTRING_PTR(cname));
        }
    }
    else {
        VALUE cname = rb_class_name(rba_cJoint);
        rb_raise(rb_eTypeError, "Expected a %s object", RSTRING_PTR(cname));
    }
}

const NewtonCollision* MSP::World::c_value_to_collision(Data* world_data, VALUE v_collision) {
    const NewtonCollision* col = reinterpret_cast<NewtonCollision*>(RU::value_to_ull(v_collision));
    if (world_data->m_collisions.find(col) != world_data->m_collisions.end())
        return col;
    else
        rb_raise(rb_eTypeError, "The specified address does not reference a valid collision");
}

const NewtonCollision* MSP::World::c_value_to_collision2(Data* world_data, VALUE v_collision) {
    const NewtonCollision* col = reinterpret_cast<NewtonCollision*>(RU::value_to_ull(v_collision));
    if (world_data->m_collisions.find(col) != world_data->m_collisions.end())
        return col;
    else
        return nullptr;
}

VALUE MSP::World::c_collision_to_value(const NewtonCollision* collision) {
    return rb_ull2inum(reinterpret_cast<unsigned long long>(collision));
}

void MSP::World::c_process_magnets(Data* world_data) {
    /*Geom::Vector3d com, dipole_dir, point, normal, r, rn;
    Geom::Transformation tra1, tra2;
    const NewtonBody* body1;
    const NewtonBody* body2;
    Body::Data* body1_data;
    Body::Data* body2_data;
    const NewtonCollision* col;
    treal mag_sq, mag;
    int res;
    for (std::set<const NewtonBody*>::iterator it1 = world_data->m_magnets.begin(); it1 != world_data->m_magnets.end(); ++it1) {
        body1= *it1;
        body1_data = Body::c_to_data(body1);
        NewtonBodyGetCentreOfMass(body1, &com[0]);
        NewtonBodyGetMatrix(body1, &tra1[0][0]);
        com = tra1.transform_vector2(com);
        dipole_dir = tra1.rotate_vector(body1_data->m_dipole_dir);
        for (std::map<const NewtonBody*, VALUE>::iterator it2 = world_data->m_bodies.begin(); it2 != world_data->m_bodies.end(); ++it2) {
            body2 = it2->first;
            body2_data = Body::c_to_data(body2);
            if (body1 != body2 && body2_data->m_magnetic) {
                col = NewtonBodyGetCollision(body2);
                NewtonBodyGetMatrix(body2, &tra2[0][0]);
                // Compute closest distance to the magnetic object
                res = NewtonCollisionPointDistance(world_data->m_world, &com[0], col, &tra2[0][0], &point[0], &normal[0], 0);
                //if (res == 1) {
                    r = (point - com);
                    mag_sq = r.get_length_squared();
                    if (mag_sq > M_EPSILON_SQ) {
                        mag = sqrt(mag_sq);
                        r.
                    }
                //}
            }
        }
    }*/
}

void MSP::World::c_advance(Data* world_data) {
    // Process coninuous forces and torques
    for (std::set<DelayedForceAndTorque*>::iterator it = world_data->m_dfts.begin(); it != world_data->m_dfts.end(); ++it) {
        DelayedForceAndTorque* dft = *it;
        Body::Data* body_data = Body::c_to_data(dft->m_body);
        body_data->m_applied_force += dft->m_force;
        body_data->m_applied_torque += dft->m_torque;
    }
    // Process magnets
    c_process_magnets(world_data);

    NewtonUpdate(world_data->m_world, world_data->m_timestep);

    for (std::vector<const NewtonJoint*>::iterator it = world_data->m_joints_to_destroy.begin(); it != world_data->m_joints_to_destroy.end(); ++it)
        NewtonDestroyJoint(world_data->m_world, *it);
    world_data->m_joints_to_destroy.clear();

    world_data->m_elapsed_time += world_data->m_timestep;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Callback Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::World::destructor_callback(const NewtonWorld* const world) {
    Data* world_data = c_to_data(world);

    // Destroy all gears

    // Destroy all joints
    for (std::map<const NewtonJoint*, VALUE>::iterator it = world_data->m_joints.begin(); it != world_data->m_joints.end();) {
        const NewtonJoint* joint = it->first;
        ++it;
        NewtonDestroyJoint(world, joint);
    }

    // Destroy all bodies (body destructor callback will be called automatically)
    NewtonDestroyAllBodies(world);

    // Destroy all collisions
    for (std::map<const NewtonCollision*, CollisionData*>::iterator it = world_data->m_collisions.begin(); it != world_data->m_collisions.end();) {
        const NewtonCollision* col = it->first;
        ++it;
        // Collision destructor callback will be called automatically, deleting the associated collision data
        NewtonDestroyCollision(col);
    }

    // Clear reference
    world_data->m_collisions.clear();
    world_data->m_bodies.clear();
    world_data->m_joints.clear();
    world_data->m_gears.clear();
    world_data->m_magnets.clear();

    world_data->m_world = nullptr;
}

void MSP::World::collision_copy_constructor_callback(const NewtonWorld* const world, NewtonCollision* const collision, const NewtonCollision* const source_collision) {
}

void MSP::World::collision_destructor_callback(const NewtonWorld* const world, const NewtonCollision* const collision) {
    Data* data = c_to_data(world);
    std::map<const NewtonCollision*, CollisionData*>::iterator it = data->m_collisions.find(collision);
    if (it != data->m_collisions.end()) {
        delete it->second;
        data->m_collisions.erase(it);
    }
}

int MSP::World::aabb_overlap_callback(const NewtonJoint* const contact, dFloat timestep, int thread_index) {
    return 1;
}

int MSP::World::compound_aabb_overlap_callback(const NewtonJoint* const contact, dFloat timestep, const NewtonBody* const body0, const void* const collision_node0, const NewtonBody* const body1, const void* const collision_node1, int thread_index) {
    return 1;
}

void MSP::World::contact_callback(const NewtonJoint* const contact_joint, treal timestep, int thread_index) {
    const NewtonBody* body0 = NewtonJointGetBody0(contact_joint);
    const NewtonBody* body1 = NewtonJointGetBody1(contact_joint);
    Body::Data* data0 = Body::c_to_data(body0);
    Body::Data* data1 = Body::c_to_data(body1);
    treal sfc = (data0->m_static_friction + data1->m_static_friction) * (treal)(0.5);
    treal kfc = (data0->m_kinetic_friction + data1->m_kinetic_friction) * (treal)(0.5);
    treal cor = (data0->m_elasticity + data1->m_elasticity) * (treal)(0.5);
    treal sft = (data0->m_softness + data1->m_softness) * (treal)(0.5);
    if (data0->m_friction_enabled && data1->m_friction_enabled) {
        for (void* contact = NewtonContactJointGetFirstContact(contact_joint); contact; contact = NewtonContactJointGetNextContact(contact_joint, contact)) {
            NewtonMaterial* material = NewtonContactGetMaterial(contact);
            NewtonMaterialSetContactFrictionCoef(material, sfc, kfc, 0);
            NewtonMaterialSetContactFrictionCoef(material, sfc, kfc, 1);
            NewtonMaterialSetContactElasticity(material, cor);
            NewtonMaterialSetContactSoftness(material, sft);
        }
    }
    else {
        for (void* contact = NewtonContactJointGetFirstContact(contact_joint); contact; contact = NewtonContactJointGetNextContact(contact_joint, contact)) {
            NewtonMaterial* material = NewtonContactGetMaterial(contact);
            NewtonMaterialSetContactFrictionState(material, 0, 0);
            NewtonMaterialSetContactFrictionState(material, 0, 1);
            NewtonMaterialSetContactElasticity(material, cor);
            NewtonMaterialSetContactSoftness(material, sft);
        }
    }
}

unsigned MSP::World::ray_prefilter_callback(const NewtonBody* const body, const NewtonCollision* const collision, void* const user_data) {
    return 0;
}

unsigned MSP::World::ray_prefilter_callback_continuous(const NewtonBody* const body, const NewtonCollision* const collision, void* const user_data) {
    return 1;
}

treal MSP::World::ray_filter_callback(const NewtonBody* const body, const NewtonCollision* const shape_hit, const treal* const hit_contact, const treal* const hit_normal, dLong collision_id, void* const user_data, treal intersect_param) {
    Body::Data* body_data = Body::c_to_data(body);
    VALUE* v_user_data_ref = reinterpret_cast<VALUE*>(user_data);

    VALUE v_hit = rb_class_new_instance(0, nullptr, rba_cHit);
    Hit::Data* hit_data = Hit::c_to_data(v_hit);

    hit_data->v_body = body_data->v_self;
    hit_data->m_point = Geom::Vector3d(hit_contact);
    hit_data->m_normal = Geom::Vector3d(hit_normal);

    *v_user_data_ref = v_hit;

    return intersect_param;
}

treal MSP::World::continuous_ray_filter_callback(const NewtonBody* const body, const NewtonCollision* const shape_hit, const treal* const hit_contact, const treal* const hit_normal, dLong collision_id, void* const user_data, treal intersect_param) {
    Body::Data* body_data = Body::c_to_data(body);
    VALUE* v_user_data_ref = reinterpret_cast<VALUE*>(user_data);

    VALUE v_hit = rb_class_new_instance(0, nullptr, rba_cHit);
    Hit::Data* hit_data = Hit::c_to_data(v_hit);

    hit_data->v_body = body_data->v_self;
    hit_data->m_point = Geom::Vector3d(hit_contact);
    hit_data->m_normal = Geom::Vector3d(hit_normal);

    rb_ary_push(*v_user_data_ref, v_hit);

    return 1.0f;
}

void MSP::World::draw_collision_iterator(void* const user_data, int vertex_count, const treal* const face_array, int face_id) {
    VALUE* v_view_ref = reinterpret_cast<VALUE*>(user_data);
    VALUE v_face = rb_ary_new2(vertex_count);
    for (int i = 0; i < vertex_count * 3; i += 3) {
        Geom::Vector3d vertex(face_array[i], face_array[i + 1], face_array[i + 2]);
        rb_ary_store(v_face, i, RU::point_to_value(vertex));
    };
    rb_funcall(*v_view_ref, RU::INTERN_DRAW, 2, RU::SU_GL_LINE_LOOP, v_face);
}

int MSP::World::body_iterator(const NewtonBody* const body, void* const user_data) {
    VALUE* v_bodies_ref = reinterpret_cast<VALUE*>(user_data);
    Body::Data* body_data = Body::c_to_data(body);
    rb_ary_push(*v_bodies_ref, body_data->v_self);
    return 1;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::World::rbf_initialize(VALUE self) {
    Data* data;
    Data_Get_Struct(self, Data, data);

    data->v_self = self;
    data->m_world = NewtonCreate();
    data->m_material_id = NewtonMaterialCreateGroupID(data->m_world);
    data->m_material_id_nc = NewtonMaterialCreateGroupID(data->m_world);
    data->m_max_threads = NewtonGetMaxThreadsCount(data->m_world);
    NewtonSetThreadsCount(data->m_world, data->m_max_threads);

    //NewtonInvalidateCache(data->m_world);

    NewtonSetContactMergeTolerance(data->m_world, CONTACT_MERGE_TOLERANCE);
    NewtonSetSolverIterations(data->m_world, DEFAULT_SOLVER_MODEL);

    // Configure default material
    NewtonMaterialSetSurfaceThickness(data->m_world, data->m_material_id, data->m_material_id, MATERIAL_THICKNESS);
    NewtonMaterialSetDefaultFriction(data->m_world, data->m_material_id, data->m_material_id, MATERIAL_STATIC_FRICTION_COEF, MATERIAL_KINETIC_FRICTION_COEF);
    NewtonMaterialSetDefaultElasticity(data->m_world, data->m_material_id, data->m_material_id, MATERIAL_ELASTICITY);
    NewtonMaterialSetDefaultSoftness(data->m_world, data->m_material_id, data->m_material_id, MATERIAL_SOFTNESS);
    NewtonMaterialSetCollisionCallback(data->m_world, data->m_material_id, data->m_material_id, aabb_overlap_callback, contact_callback);
    NewtonMaterialSetCompoundCollisionCallback(data->m_world, data->m_material_id, data->m_material_id, compound_aabb_overlap_callback);

    // Configure default and non-collidable material
    NewtonMaterialSetDefaultCollidable(data->m_world, data->m_material_id, data->m_material_id_nc, 0);
    NewtonMaterialSetDefaultCollidable(data->m_world, data->m_material_id_nc, data->m_material_id_nc, 0);

    NewtonWorldSetCollisionConstructorDestructorCallback(data->m_world, collision_copy_constructor_callback, collision_destructor_callback);
    NewtonWorldSetDestructorCallback(data->m_world, destructor_callback);

    NewtonWorldSetUserData(data->m_world, data);

    return self;
}

VALUE MSP::World::rbf_is_valid(VALUE self) {
    Data* data;
    Data_Get_Struct(self, Data, data);
    return data->m_world ? Qtrue : Qfalse;
}

VALUE MSP::World::rbf_destroy(VALUE self) {
    Data* data = c_to_data(self);
    NewtonDestroy(data->m_world);
    return Qnil;
}

VALUE MSP::World::rbf_get_max_possible_threads_count(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(NewtonGetMaxThreadsCount(data->m_world));
}

VALUE MSP::World::rbf_get_max_threads_count(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_max_threads);
}

VALUE MSP::World::rbf_set_max_threads_count(VALUE self, VALUE v_count) {
    Data* data = c_to_data(self);
    data->m_max_threads = Geom::clamp_int(RU::value_to_int(v_count), 1, NewtonGetMaxThreadsCount(data->m_world));
    NewtonSetThreadsCount(data->m_world, data->m_max_threads);
    return Qnil;
}

VALUE MSP::World::rbf_get_cur_threads_count(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(NewtonGetThreadsCount(data->m_world));
}

VALUE MSP::World::rbf_get_elapsed_time(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_elapsed_time);
}

VALUE MSP::World::rbf_advance(VALUE self) {
    Data* data = c_to_data(self);
    c_advance(data);
    return Qnil;
}

VALUE MSP::World::rbf_advance_by(VALUE self, VALUE v_time) {
    Data* data = c_to_data(self);
    treal dt = Geom::max_treal(RU::value_to_treal(v_time), MIN_TIMESTEP);
    unsigned int n = static_cast<unsigned int>(dt / data->m_timestep + (treal)(1.0));
    unsigned int i;
    for (i = 0; i < n; ++i)
        c_advance(data);
    return Qnil;
}

VALUE MSP::World::rbf_update_group_transformations(VALUE self) {
    Data* data = c_to_data(self);

    for (std::map<const NewtonBody*, VALUE>::iterator it = data->m_bodies.begin(); it != data->m_bodies.end(); ++it) {
        Body::Data* body_data = Body::c_to_data(it->second);
        if (body_data->m_matrix_changed && body_data->v_group != Qnil && rb_funcall(body_data->v_group, RU::INTERN_TVALID, 0) == Qtrue) {
            Geom::Transformation matrix;
            NewtonBodyGetMatrix(it->first, &matrix[0][0]);
            matrix.scale_axes_self(body_data->m_act_tra_scale);
            rb_funcall(body_data->v_group, RU::INTERN_EMOVE, 1, RU::transformation_to_value(matrix));
            body_data->m_matrix_changed = false;
        }
    }

    return Qnil;
}

VALUE MSP::World::rbf_get_bodies(VALUE self) {
    Data* data = c_to_data(self);
    VALUE v_items = rb_ary_new2(static_cast<unsigned int>(data->m_bodies.size()));
    unsigned int i = 0;

    for (std::map<const NewtonBody*, VALUE>::iterator it = data->m_bodies.begin(); it != data->m_bodies.end(); ++it) {
        rb_ary_store(v_items, i, it->second);
        ++i;
    }

    return v_items;
}

VALUE MSP::World::rbf_get_joints(VALUE self) {
    Data* data = c_to_data(self);
    VALUE v_items = rb_ary_new2(static_cast<unsigned int>(data->m_joints.size()));
    unsigned int i = 0;

    for (std::map<const NewtonJoint*, VALUE>::iterator it = data->m_joints.begin(); it != data->m_joints.end(); ++it) {
        rb_ary_store(v_items, i, it->second);
        ++i;
    }

    return v_items;
}

VALUE MSP::World::rbf_get_gears(VALUE self) {
    Data* data = c_to_data(self);
    VALUE v_items = rb_ary_new2(static_cast<unsigned int>(data->m_gears.size()));
    unsigned int i = 0;

    for (std::set<VALUE>::iterator it = data->m_gears.begin(); it != data->m_gears.end(); ++it) {
        rb_ary_store(v_items, i, *it);
        ++i;
    }

    return v_items;
}

VALUE MSP::World::rbf_count_bodies(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_bodies.size());
}

VALUE MSP::World::rbf_count_joints(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_joints.size());
}

VALUE MSP::World::rbf_count_gears(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_gears.size());
}

VALUE MSP::World::rbf_find_body_by_group(VALUE self, VALUE v_group) {
    Data* data = c_to_data(self);
    Body::Data* body_data;
    for (std::map<const NewtonBody*, VALUE>::iterator it = data->m_bodies.begin(); it != data->m_bodies.end(); ++it) {
        body_data = Body::c_to_data(it->first);
        if (body_data->v_group == v_group)
            return it->second;
    }
    return Qnil;
}

VALUE MSP::World::rbf_find_joint_by_group(VALUE self, VALUE v_group) {
    Data* data = c_to_data(self);
    Joint::Data* joint_data;
    for (std::map<const NewtonJoint*, VALUE>::iterator it = data->m_joints.begin(); it != data->m_joints.end(); ++it) {
        joint_data = Joint::c_to_data(it->first);
        if (joint_data->v_group == v_group)
            return it->second;
    }
    return Qnil;
}

VALUE MSP::World::rbf_find_joints_by_group(VALUE self, VALUE v_group) {
    Data* data = c_to_data(self);
    Joint::Data* joint_data;
    VALUE v_joints = rb_ary_new();
    for (std::map<const NewtonJoint*, VALUE>::iterator it = data->m_joints.begin(); it != data->m_joints.end(); ++it) {
        joint_data = Joint::c_to_data(it->first);
        if (joint_data->v_group == v_group)
            rb_ary_push(v_joints, it->second);
    }
    return v_joints;
}

VALUE MSP::World::rbf_get_gravity(VALUE self) {
    Data* data = c_to_data(self);
    return RU::vector_to_value2(data->m_gravity, M_INCH_TO_METER);
}

VALUE MSP::World::rbf_set_gravity(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    if (argc == 3)
        RU::varry_to_vector2(argv, data->m_gravity, M_METER_TO_INCH);
    else if (argc == 1)
        RU::value_to_vector2(argv[0], data->m_gravity, M_METER_TO_INCH);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    return Qnil;
}

VALUE MSP::World::rbf_get_wind_velocity(VALUE self) {
    Data* data = c_to_data(self);
    return RU::vector_to_value2(data->m_wind_velocity, M_INCH_TO_METER);
}

VALUE MSP::World::rbf_set_wind_velocity(int argc, VALUE* argv, VALUE self) {
    Data* data = c_to_data(self);
    if (argc == 3)
        RU::varry_to_vector2(argv, data->m_wind_velocity, M_METER_TO_INCH);
    else if (argc == 1)
        RU::value_to_vector2(argv[0], data->m_wind_velocity, M_METER_TO_INCH);
    else
        rb_raise(rb_eArgError, "Wrong number of arguments! Expected 1 or 3 arguments.");
    return Qnil;
}

VALUE MSP::World::rbf_get_update_timestep(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_timestep);
}

VALUE MSP::World::rbf_set_update_timestep(VALUE self, VALUE v_timestep) {
    Data* data = c_to_data(self);
    data->m_timestep = Geom::clamp_treal(RU::value_to_treal(v_timestep), MIN_TIMESTEP, MAX_TIMESTEP);
    return Qnil;
}

VALUE MSP::World::rbf_get_solver_model(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_solver_model);
}

VALUE MSP::World::rbf_set_solver_model(VALUE self, VALUE v_model) {
    Data* data = c_to_data(self);
    data->m_solver_model = Geom::clamp_int(RU::value_to_int(v_model), 1, 256);
    return Qnil;
}

VALUE MSP::World::rbf_get_material_thickness(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_material_thickness);
}

VALUE MSP::World::rbf_set_material_thickness(VALUE self, VALUE v_thickness) {
    Data* data = c_to_data(self);
    data->m_material_thickness = Geom::clamp_treal(RU::value_to_treal(v_thickness), (treal)(0.0), (treal)(1.0 / 32.0));
    NewtonMaterialSetSurfaceThickness(data->m_world, data->m_material_id, data->m_material_id, data->m_material_thickness);
    return Qnil;
}


VALUE MSP::World::rbf_get_drag_coefficient(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_drag_coef);
}

VALUE MSP::World::rbf_set_drag_coefficient(VALUE self, VALUE v_coef) {
    Data* data = c_to_data(self);
    data->m_drag_coef = Geom::max_treal(RU::value_to_treal(v_coef), (treal)(0.0));
    return Qnil;
}

VALUE MSP::World::rbf_get_damp_coefficient(VALUE self) {
    Data* data = c_to_data(self);
    return RU::to_value(data->m_damp_coef);
}

VALUE MSP::World::rbf_set_damp_coefficient(VALUE self, VALUE v_coef) {
    Data* data = c_to_data(self);
    const NewtonBody* body;
    data->m_damp_coef = Geom::clamp_treal(RU::value_to_treal(v_coef), (treal)(0.0), (treal)(1.0));
    Geom::Vector3d angular_damp(data->m_damp_coef, data->m_damp_coef, data->m_damp_coef);
    for (body = NewtonWorldGetFirstBody(data->m_world); body; body = NewtonWorldGetNextBody(data->m_world, body)) {
        NewtonBodySetLinearDamping(body, data->m_damp_coef);
        NewtonBodySetAngularDamping(body, &angular_damp[0]);
    }
    return Qnil;
}

VALUE MSP::World::rbf_ray_cast(VALUE self, VALUE v_point1, VALUE v_point2) {
    Data* data = c_to_data(self);
    Geom::Vector3d point1, point2;
    RU::value_to_vector(v_point1, point1);
    RU::value_to_vector(v_point2, point2);
    VALUE v_hit = Qnil;
    NewtonWorldRayCast(data->m_world, &point1[0], &point2[0], ray_filter_callback, reinterpret_cast<void*>(&v_hit), NULL, 0);
    return v_hit;
}

VALUE MSP::World::rbf_continuous_ray_cast(VALUE self, VALUE v_point1, VALUE v_point2) {
    Data* data = c_to_data(self);
    Geom::Vector3d point1, point2;
    RU::value_to_vector(v_point1, point1);
    RU::value_to_vector(v_point2, point2);
    VALUE v_hits = rb_ary_new();
    NewtonWorldRayCast(data->m_world, &point1[0], &point2[0], continuous_ray_filter_callback, reinterpret_cast<void*>(&v_hits), NULL, 0);
    return v_hits;
}

VALUE MSP::World::rbf_convex_ray_cast(VALUE self, VALUE v_body, VALUE v_matrix, VALUE v_target) {
    Data* data = c_to_data(self);
    const NewtonBody* body = c_value_to_body(data, v_body);
    const NewtonCollision* collision = NewtonBodyGetCollision(body);

    Geom::Transformation matrix;
    Geom::Vector3d target;
    RU::value_to_transformation3(v_matrix, matrix);
    RU::value_to_vector(v_target, target);

    treal hit_param;
    NewtonWorldConvexCastReturnInfo info[1];
    int hit_count = NewtonWorldConvexCast(data->m_world, &matrix[0][0], &target[0], collision, &hit_param, nullptr, ray_prefilter_callback, &info[0], 1, 0);

    if (hit_count != 0) {
        VALUE v_hit = rb_class_new_instance(0, nullptr, rba_cHit);
        Hit::Data* hit_data = Hit::c_to_data(v_hit);
        Body::Data* body_data = MSP::Body::c_to_data(info[0].m_hitBody);
        hit_data->v_body = body_data->v_self;
        hit_data->m_point = Geom::Vector3d(info[0].m_point);
        hit_data->m_normal = Geom::Vector3d(info[0].m_normal);
        return v_hit;
    }
    else
        return Qnil;
}

VALUE MSP::World::rbf_continuous_convex_ray_cast(VALUE self, VALUE v_body, VALUE v_matrix, VALUE v_target, VALUE v_max_hits) {
    Data* data = c_to_data(self);
    const NewtonBody* body = c_value_to_body(data, v_body);
    const NewtonCollision* collision = NewtonBodyGetCollision(body);

    Geom::Transformation matrix;
    Geom::Vector3d target;
    RU::value_to_transformation3(v_matrix, matrix);
    RU::value_to_vector(v_target, target);

    int max_hits = Geom::clamp_int(RU::value_to_int(v_max_hits), 1, MSP_MAX_RAY_HITS);

    treal hit_param;
    NewtonWorldConvexCastReturnInfo info[MSP_MAX_RAY_HITS];
    int num_hits = NewtonWorldConvexCast(data->m_world, &matrix[0][0], &target[0], collision, &hit_param, nullptr, ray_prefilter_callback_continuous, &info[0], max_hits, 0);

    VALUE v_hits = rb_ary_new2(num_hits);
    for (int i = 0; i < num_hits; ++i) {
        NewtonWorldConvexCastReturnInfo& hit = info[i];
        VALUE v_hit = rb_class_new_instance(0, nullptr, rba_cHit);
        Hit::Data* hit_data = Hit::c_to_data(v_hit);
        Body::Data* body_data = MSP::Body::c_to_data(hit.m_hitBody);
        hit_data->v_body = body_data->v_self;
        hit_data->m_point = Geom::Vector3d(hit.m_point);
        hit_data->m_normal = Geom::Vector3d(hit.m_normal);
        rb_ary_store(v_hits, i, v_hit);
    }
    return v_hits;
}

VALUE MSP::World::rbf_draw_collision_wireframe(VALUE self, VALUE v_view, VALUE v_view_bb, VALUE v_sleep_color, VALUE v_active_color, VALUE v_line_width, VALUE v_line_stipple) {
    Data* data = c_to_data(self);
    rb_funcall(v_view, RU::INTERN_SLINE_WIDTH, 1, v_line_width);
    rb_funcall(v_view, RU::INTERN_SLINE_STIPPLE, 1, v_line_stipple);
    Geom::Transformation matrix;
    for (const NewtonBody* body = NewtonWorldGetFirstBody(data->m_world); body; body = NewtonWorldGetNextBody(data->m_world, body)) {
        const NewtonCollision* collision = NewtonBodyGetCollision(body);
        NewtonBodyGetMatrix(body, &matrix[0][0]);
        if (NewtonBodyGetSleepState(body) == 1)
            rb_funcall(v_view, RU::INTERN_SDRAWING_COLOR, 1, v_sleep_color);
        else
            rb_funcall(v_view, RU::INTERN_SDRAWING_COLOR, 1, v_active_color);
        NewtonCollisionForEachPolygonDo(collision, &matrix[0][0], draw_collision_iterator, reinterpret_cast<void*>(&v_view));
    }
    return Qnil;
}

VALUE MSP::World::rbf_draw_centre_of_mass(VALUE self, VALUE v_view, VALUE v_view_bb, VALUE v_scale, VALUE v_xaxis_color, VALUE v_yaxis_color, VALUE v_zaxis_color, VALUE v_line_width, VALUE v_line_stipple) {
    Data* data = c_to_data(self);
    Geom::Transformation matrix;
    Geom::Vector3d center, point;
    VALUE v_points = rb_ary_new2(2);
    treal scale = RU::value_to_treal(v_scale);
    rb_funcall(v_view, RU::INTERN_SLINE_WIDTH, 1, v_line_width);
    rb_funcall(v_view, RU::INTERN_SLINE_STIPPLE, 1, v_line_stipple);
    for (const NewtonBody* body = NewtonWorldGetFirstBody(data->m_world); body; body = NewtonWorldGetNextBody(data->m_world, body)) {
        NewtonBodyGetMatrix(body, &matrix[0][0]);
        NewtonBodyGetCentreOfMass(body, &center[0]);
        center = matrix.transform_vector2(center);
        rb_ary_store(v_points, 0, RU::point_to_value(center));

        rb_funcall(v_view, RU::INTERN_SDRAWING_COLOR, 1, v_xaxis_color);
        rb_ary_store(v_points, 1, RU::point_to_value(center + matrix.m_xaxis.scale(scale)));
        rb_funcall(v_view, RU::INTERN_DRAW, 2, RU::SU_GL_LINES, v_points);

        rb_funcall(v_view, RU::INTERN_SDRAWING_COLOR, 1, v_yaxis_color);
        rb_ary_store(v_points, 1, RU::point_to_value(center + matrix.m_yaxis.scale(scale)));
        rb_funcall(v_view, RU::INTERN_DRAW, 2, RU::SU_GL_LINES, v_points);

        rb_funcall(v_view, RU::INTERN_SDRAWING_COLOR, 1, v_zaxis_color);
        rb_ary_store(v_points, 1, RU::point_to_value(center + matrix.m_zaxis.scale(scale)));
        rb_funcall(v_view, RU::INTERN_DRAW, 2, RU::SU_GL_LINES, v_points);
    }
    return Qnil;
}

VALUE MSP::World::rbf_get_aabb(VALUE self) {
    Data* data = c_to_data(self);
    Geom::BoundingBox bb;
    Geom::Vector3d p0, p1;
    for (const NewtonBody* body = NewtonWorldGetFirstBody(data->m_world); body; body = NewtonWorldGetNextBody(data->m_world, body)) {
        NewtonBodyGetAABB(body, &p0[0], &p1[0]);
        bb.add(p0, p1);
    }
    return RU::bb_to_value(bb);
}

VALUE MSP::World::rbf_get_bodies_in_aabb(VALUE self, VALUE v_bb) {
    Data* data = c_to_data(self);
    Geom::BoundingBox bb;
    RU::value_to_bb(v_bb, bb);
    VALUE v_bodies = rb_ary_new();
    NewtonWorldForEachBodyInAABBDo(data->m_world, &bb.m_min[0], &bb.m_max[0], body_iterator, reinterpret_cast<void*>(&v_bodies));
    return v_bodies;
}

VALUE MSP::World::rbf_apply_blast_impulse(VALUE self, VALUE v_center, VALUE v_radius, VALUE v_impulse) {
    Data* data = c_to_data(self);
    // FIXME
    return Qnil;
}

VALUE MSP::World::rbf_apply_aero_blast_impulse(VALUE self, VALUE v_center, VALUE v_radius, VALUE v_impulse) {
    Data* data = c_to_data(self);
    // FIXME
    return Qnil;
}

VALUE MSP::World::rbf_apply_buoyancy(VALUE self, VALUE v_bb, VALUE v_plane_origin, VALUE v_plane_normal, VALUE v_density, VALUE v_linear_viscosity, VALUE v_angular_viscosity, VALUE v_linear_current, VALUE v_angular_current) {
    Data* data = c_to_data(self);
    // FIXME
    return Qnil;
}

VALUE MSP::World::rbf_create_null_collision(VALUE self) {
    Data* data = c_to_data(self);
    const NewtonCollision* col = NewtonCreateNull(data->m_world);
    data->m_collisions[col] = new CollisionData;
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_box_collision(VALUE self, VALUE v_width, VALUE v_height, VALUE v_depth, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateBox(
        data->m_world,
        Geom::clamp_treal(RU::value_to_treal(v_width), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_height), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_depth), MIN_COL_SIZE, MAX_COL_SIZE),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_sphere_collision(VALUE self, VALUE v_radius, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateSphere(
        data->m_world,
        Geom::clamp_treal(RU::value_to_treal(v_radius), MIN_COL_SIZE, MAX_COL_SIZE),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_scaled_sphere_collision(VALUE self, VALUE v_width, VALUE v_height, VALUE v_depth, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    treal w = Geom::clamp_treal(RU::value_to_treal(v_width), MIN_COL_SIZE, MAX_COL_SIZE);
    treal h = Geom::clamp_treal(RU::value_to_treal(v_height), MIN_COL_SIZE, MAX_COL_SIZE);
    treal d = Geom::clamp_treal(RU::value_to_treal(v_depth), MIN_COL_SIZE, MAX_COL_SIZE);
    treal r = Geom::min_treal(d, Geom::min_treal(h, w));
    treal ir = (treal)(1.0) / r;
    Geom::Vector3d scale(w * ir, h * ir, d * ir);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateSphere(
        data->m_world,
        r * (treal)(0.5),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    NewtonCollisionSetScale(col, scale.m_x, scale.m_y, scale.m_z);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin, scale);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_cone_collision(VALUE self, VALUE v_radius, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateCone(
        data->m_world,
        Geom::clamp_treal(RU::value_to_treal(v_radius), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_height), MIN_COL_SIZE, MAX_COL_SIZE),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_scaled_cone_collision(VALUE self, VALUE v_radiusx, VALUE v_radiusy, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    treal rx = Geom::clamp_treal(RU::value_to_treal(v_radiusx), MIN_COL_SIZE, MAX_COL_SIZE);
    treal ry = Geom::clamp_treal(RU::value_to_treal(v_radiusy), MIN_COL_SIZE, MAX_COL_SIZE);
    treal h = Geom::clamp_treal(RU::value_to_treal(v_height), MIN_COL_SIZE, MAX_COL_SIZE);
    treal r = Geom::min_treal(rx, ry);
    treal ir = (treal)(1.0) / r;
    Geom::Vector3d scale(1.0, ry * ir, rx * ir);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateCone(
        data->m_world,
        r,
        h,
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    NewtonCollisionSetScale(col, scale.m_x, scale.m_y, scale.m_z);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin, scale);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_cylinder_collision(VALUE self, VALUE v_radius, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateCylinder(
        data->m_world,
        Geom::clamp_treal(RU::value_to_treal(v_radius), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_radius), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_height), MIN_COL_SIZE, MAX_COL_SIZE),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_scaled_cylinder_collision(VALUE self, VALUE v_radiusx, VALUE v_radiusy, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    treal rx = Geom::clamp_treal(RU::value_to_treal(v_radiusx), MIN_COL_SIZE, MAX_COL_SIZE);
    treal ry = Geom::clamp_treal(RU::value_to_treal(v_radiusy), MIN_COL_SIZE, MAX_COL_SIZE);
    treal h = Geom::clamp_treal(RU::value_to_treal(v_height), MIN_COL_SIZE, MAX_COL_SIZE);
    treal r = Geom::min_treal(rx, ry);
    treal ir = (treal)(1.0) / r;
    Geom::Vector3d scale(1.0, ry * ir, rx * ir);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateCylinder(
        data->m_world,
        r,
        r,
        h,
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    NewtonCollisionSetScale(col, scale.m_x, scale.m_y, scale.m_z);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin, scale);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_capsule_collision(VALUE self, VALUE v_radius, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateCapsule(
        data->m_world,
        Geom::clamp_treal(RU::value_to_treal(v_radius), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_radius), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_height), 0.0, MAX_COL_SIZE),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_scaled_capsule_collision(VALUE self, VALUE v_radiusx, VALUE v_radiusy, VALUE v_total_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    treal rx = Geom::clamp_treal(RU::value_to_treal(v_radiusx), MIN_COL_SIZE, MAX_COL_SIZE);
    treal ry = Geom::clamp_treal(RU::value_to_treal(v_radiusy), MIN_COL_SIZE, MAX_COL_SIZE);
    treal th = Geom::clamp_treal(RU::value_to_treal(v_total_height), MIN_COL_SIZE, MAX_COL_SIZE);
    treal r = Geom::min_treal(rx, ry);
    treal ir = (treal)(1.0) / r;
    treal h = th - r * (treal)(2.0);
    Geom::Vector3d scale(1.0, ry * ir, rx * ir);
    if (h < 0.0)
        scale.m_x = th * ir * (treal)(0.5);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateCapsule(
        data->m_world,
        r,
        r,
        Geom::max_treal(h, 0.0),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    NewtonCollisionSetScale(col, scale.m_x, scale.m_y, scale.m_z);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin, scale);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_tapered_capsule_collision(VALUE self, VALUE v_radius0, VALUE v_radius1, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateCapsule(
        data->m_world,
        Geom::clamp_treal(RU::value_to_treal(v_radius0), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_radius1), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_height), 0.0, MAX_COL_SIZE),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_tapered_cylinder_collision(VALUE self, VALUE v_radius0, VALUE v_radius1, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateCylinder(
        data->m_world,
        Geom::clamp_treal(RU::value_to_treal(v_radius0), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_radius1), MIN_COL_SIZE, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_height), MIN_COL_SIZE, MAX_COL_SIZE),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_chamfer_cylinder_collision(VALUE self, VALUE v_radius, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateChamferCylinder(
        data->m_world,
        Geom::clamp_treal(RU::value_to_treal(v_radius), 0.0, MAX_COL_SIZE),
        Geom::clamp_treal(RU::value_to_treal(v_height), 0.0, MAX_COL_SIZE),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_scaled_chamfer_cylinder_collision(VALUE self, VALUE v_radiusx, VALUE v_radiusy, VALUE v_height, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    treal rx = Geom::clamp_treal(RU::value_to_treal(v_radiusx), MIN_COL_SIZE, MAX_COL_SIZE);
    treal ry = Geom::clamp_treal(RU::value_to_treal(v_radiusy), MIN_COL_SIZE, MAX_COL_SIZE);
    treal h = Geom::clamp_treal(RU::value_to_treal(v_height), MIN_COL_SIZE, MAX_COL_SIZE);
    treal r = Geom::min_treal(rx, ry);
    treal ir = (treal)(1.0) / (h * (treal)(0.5) + r);
    Geom::Vector3d scale(1.0, ry * ir, rx * ir);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    const NewtonCollision* col = NewtonCreateChamferCylinder(
        data->m_world,
        r,
        h,
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    NewtonCollisionSetScale(col, scale.m_x, scale.m_y, scale.m_z);
    data->m_collisions[col] = new CollisionData(offset_matrix.m_origin, scale);
    return c_collision_to_value(col);
}

VALUE MSP::World::rbf_create_convex_hull_collision(VALUE self, VALUE v_vertices, VALUE v_tolerance, VALUE v_offset_matrix) {
    Data* data = c_to_data(self);
    Check_Type(v_vertices, T_ARRAY);
    Geom::Transformation offset_matrix;
    if (v_offset_matrix != Qnil)
        RU::value_to_transformation3(v_offset_matrix, offset_matrix);
    unsigned int vertex_count = static_cast<unsigned int>(RARRAY_LEN(v_vertices));
    unsigned int i = 0;
    unsigned int j = 0;
    treal* vertex_cloud = new treal[vertex_count * 3];
    Geom::Vector3d point;
    for (; i < vertex_count; ++i) {
        RU::value_to_vector(rb_ary_entry(v_vertices, i), point);
        vertex_cloud[j] = point.m_x;
        vertex_cloud[j + 1] = point.m_y;
        vertex_cloud[j + 2] = point.m_z;
        j += 3;
    }
    const NewtonCollision* col = NewtonCreateConvexHull(
        data->m_world,
        vertex_count,
        vertex_cloud,
        sizeof(treal) * 3,
        RU::value_to_treal(v_tolerance),
        0,
        (v_offset_matrix != Qnil) ? &offset_matrix[0][0] : NULL);
    delete[] vertex_cloud;
    if (col != NULL) {
        data->m_collisions[col] = new CollisionData(offset_matrix.m_origin);
        return c_collision_to_value(col);
    }
    else
        return Qnil;
}

VALUE MSP::World::rbf_create_compound_collision(VALUE self, VALUE v_convex_collisions) {
    Data* data = c_to_data(self);

    NewtonCollision* compound;
    const NewtonCollision* col;
    unsigned int collisions_count, i;

    Check_Type(v_convex_collisions, T_ARRAY);

    collisions_count = static_cast<unsigned int>(RARRAY_LEN(v_convex_collisions));

    compound = NewtonCreateCompoundCollision(data->m_world, 0);
    NewtonCompoundCollisionBeginAddRemove(compound);
    for (i = 0; i < collisions_count; ++i) {
        col = c_value_to_collision2(data, rb_ary_entry(v_convex_collisions, i));
        if (col != nullptr && NewtonCollisionGetType(col) < 7)
            NewtonCompoundCollisionAddSubCollision(compound, col);
    }
    NewtonCompoundCollisionEndAddRemove(compound);
    data->m_collisions[compound] = new CollisionData;
    return c_collision_to_value(compound);
}

VALUE MSP::World::rbf_create_static_mesh_collision(VALUE self, VALUE v_polygons, VALUE v_optimize) {
    Data* data = c_to_data(self);

    // Declare variables
    unsigned int i, j, k, vertex_count, polygons_length;
    Geom::Vector3d point;
    NewtonCollision* collision;
    treal* vertex_cloud;
    VALUE v_polygon;
    bool optimize;

    // Validate
    Check_Type(v_polygons, T_ARRAY);

    optimize = RU::value_to_bool(v_optimize);
    polygons_length = static_cast<unsigned int>(RARRAY_LEN(v_polygons));

    collision = NewtonCreateTreeCollision(data->m_world, 0);

    NewtonTreeCollisionBeginBuild(collision);
    for (i = 0; i < polygons_length; ++i) {
        v_polygon = rb_ary_entry(v_polygons, i);
        if (TYPE(v_polygon) == T_ARRAY) {
            vertex_count = static_cast<unsigned int>(RARRAY_LEN(v_polygon));
            vertex_cloud = new treal[vertex_count * 3];
            k = 0;
            for (j = 0; j < vertex_count; ++j) {
                RU::value_to_vector(rb_ary_entry(v_polygon, j), point);
                vertex_cloud[k] = point.m_x;
                vertex_cloud[k + 1] = point.m_y;
                vertex_cloud[k + 2] = point.m_z;
                k += 3;
            }
            NewtonTreeCollisionAddFace(collision, 3, &vertex_cloud[0], 3 * sizeof(treal), 0);
            delete[] vertex_cloud;
        }
    }
    NewtonTreeCollisionEndBuild(collision, optimize ? 1 : 0);

    data->m_collisions[collision] = new CollisionData;
    return c_collision_to_value(collision);
}

VALUE MSP::World::rbf_create_scene_collision(VALUE self, VALUE v_collisions) {
    Data* data = c_to_data(self);
    unsigned int i, collisions_count;
    NewtonCollision* scene;
    const NewtonCollision* col;

    Check_Type(v_collisions, T_ARRAY);

    collisions_count = static_cast<unsigned int>(RARRAY_LEN(v_collisions));

    scene = NewtonCreateSceneCollision(data->m_world, 0);

    NewtonSceneCollisionBeginAddRemove(scene);
    for (i = 0; i < collisions_count; ++i) {
        col = c_value_to_collision2(data, rb_ary_entry(v_collisions, i));
        if (col != nullptr && NewtonCollisionGetType(col) < 11)
            NewtonSceneCollisionAddSubCollision(scene, col);
    }
    NewtonSceneCollisionEndAddRemove(scene);

    data->m_collisions[scene] = new CollisionData;
    return c_collision_to_value(scene);
}

VALUE MSP::World::rbf_is_collision_valid(VALUE self, VALUE v_collision) {
    Data* data = c_to_data(self);
    if (c_value_to_collision2(data, v_collision))
        return Qtrue;
    else
        return Qfalse;
}

VALUE MSP::World::rbf_destroy_collision(VALUE self, VALUE v_collision) {
    Data* data = c_to_data(self);
    const NewtonCollision* col = c_value_to_collision(data, v_collision);
    NewtonDestroyCollision(col);
    return Qnil;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::World::init_ruby(VALUE mMSP) {
    rba_cWorld = rb_define_class_under(mMSP, "World", rba_cEntity);

    rb_define_alloc_func(rba_cWorld, c_class_allocate);

    rb_define_const(rba_cWorld, "DEFAULT_TIMESTEP", RU::to_value(DEFAULT_TIMESTEP));
    rb_define_const(rba_cWorld, "DEFAULT_DRAG_COEFFICIENT", RU::to_value(DEFAULT_DRAG_COEFFICIENT));
    rb_define_const(rba_cWorld, "DEFAULT_DAMP_COEFFICIENT", RU::to_value(DEFAULT_DAMP_COEFFICIENT));

    rb_define_method(rba_cWorld, "initialize", VALUEFUNC(rbf_initialize), 0);
    rb_define_method(rba_cWorld, "valid?", VALUEFUNC(rbf_is_valid), 0);
    rb_define_method(rba_cWorld, "destroy", VALUEFUNC(rbf_destroy), 0);

    rb_define_method(rba_cWorld, "max_possible_threads_count", VALUEFUNC(rbf_get_max_possible_threads_count), 0);
    rb_define_method(rba_cWorld, "max_threads_count", VALUEFUNC(rbf_get_max_threads_count), 0);
    rb_define_method(rba_cWorld, "max_threads_count=", VALUEFUNC(rbf_set_max_threads_count), 1);
    rb_define_method(rba_cWorld, "cur_threads_count", VALUEFUNC(rbf_get_cur_threads_count), 0);

    rb_define_method(rba_cWorld, "elapsed_time", VALUEFUNC(rbf_get_elapsed_time), 0);
    rb_define_method(rba_cWorld, "advance", VALUEFUNC(rbf_advance), 0);
    rb_define_method(rba_cWorld, "advance_by", VALUEFUNC(rbf_advance_by), 1);

    rb_define_method(rba_cWorld, "update_group_transformations", VALUEFUNC(rbf_update_group_transformations), 0);

    rb_define_method(rba_cWorld, "bodies", VALUEFUNC(rbf_get_bodies), 0);
    rb_define_method(rba_cWorld, "joints", VALUEFUNC(rbf_get_joints), 0);
    rb_define_method(rba_cWorld, "gears", VALUEFUNC(rbf_get_gears), 0);

    rb_define_method(rba_cWorld, "count_bodies", VALUEFUNC(rbf_count_bodies), 0);
    rb_define_method(rba_cWorld, "count_joints", VALUEFUNC(rbf_count_joints), 0);
    rb_define_method(rba_cWorld, "count_gears", VALUEFUNC(rbf_count_gears), 0);

    rb_define_method(rba_cWorld, "find_body_by_group", VALUEFUNC(rbf_find_body_by_group), 1);
    rb_define_method(rba_cWorld, "find_joint_by_group", VALUEFUNC(rbf_find_joint_by_group), 1);
    rb_define_method(rba_cWorld, "find_joints_by_group", VALUEFUNC(rbf_find_joints_by_group), 1);

    rb_define_method(rba_cWorld, "get_gravity", VALUEFUNC(rbf_get_gravity), 0);
    rb_define_method(rba_cWorld, "set_gravity", VALUEFUNC(rbf_set_gravity), -1);
    rb_define_method(rba_cWorld, "get_wind_velocity", VALUEFUNC(rbf_get_wind_velocity), 0);
    rb_define_method(rba_cWorld, "set_wind_velocity", VALUEFUNC(rbf_set_wind_velocity), -1);

    rb_define_method(rba_cWorld, "update_timestep", VALUEFUNC(rbf_get_update_timestep), 0);
    rb_define_method(rba_cWorld, "update_timestep=", VALUEFUNC(rbf_set_update_timestep), 1);
    rb_define_method(rba_cWorld, "solver_model", VALUEFUNC(rbf_get_solver_model), 0);
    rb_define_method(rba_cWorld, "solver_model=", VALUEFUNC(rbf_set_solver_model), 1);
    rb_define_method(rba_cWorld, "material_thickness", VALUEFUNC(rbf_get_material_thickness), 0);
    rb_define_method(rba_cWorld, "material_thickness=", VALUEFUNC(rbf_set_material_thickness), 1);

    rb_define_method(rba_cWorld, "drag", VALUEFUNC(rbf_get_drag_coefficient), 0);
    rb_define_method(rba_cWorld, "drag=", VALUEFUNC(rbf_set_drag_coefficient), 1);
    rb_define_method(rba_cWorld, "damp", VALUEFUNC(rbf_get_damp_coefficient), 0);
    rb_define_method(rba_cWorld, "damp=", VALUEFUNC(rbf_set_damp_coefficient), 1);

    rb_define_method(rba_cWorld, "ray_cast", VALUEFUNC(rbf_ray_cast), 2);
    rb_define_method(rba_cWorld, "continuous_ray_cast", VALUEFUNC(rbf_continuous_ray_cast), 2);
    rb_define_method(rba_cWorld, "convex_ray_cast", VALUEFUNC(rbf_convex_ray_cast), 3);
    rb_define_method(rba_cWorld, "continuous_convex_ray_cast", VALUEFUNC(rbf_continuous_convex_ray_cast), 4);

    rb_define_method(rba_cWorld, "draw_collision_wireframe", VALUEFUNC(rbf_draw_collision_wireframe), 6);
    rb_define_method(rba_cWorld, "draw_centre_of_mass", VALUEFUNC(rbf_draw_centre_of_mass), 8);

    rb_define_method(rba_cWorld, "bounds", VALUEFUNC(rbf_get_aabb), 0);
    rb_define_method(rba_cWorld, "get_bodies_in_aabb", VALUEFUNC(rbf_get_bodies_in_aabb), 1);

    rb_define_method(rba_cWorld, "create_null_collision", VALUEFUNC(rbf_create_null_collision), 0);
    rb_define_method(rba_cWorld, "create_box_collision", VALUEFUNC(rbf_create_box_collision), 4);
    rb_define_method(rba_cWorld, "create_sphere_collision", VALUEFUNC(rbf_create_sphere_collision), 2);
    rb_define_method(rba_cWorld, "create_scaled_sphere_collision", VALUEFUNC(rbf_create_scaled_sphere_collision), 4);
    rb_define_method(rba_cWorld, "create_cone_collision", VALUEFUNC(rbf_create_cone_collision), 3);
    rb_define_method(rba_cWorld, "create_scaled_cone_collision", VALUEFUNC(rbf_create_scaled_cone_collision), 4);
    rb_define_method(rba_cWorld, "create_cylinder_collision", VALUEFUNC(rbf_create_cylinder_collision), 3);
    rb_define_method(rba_cWorld, "create_scaled_cylinder_collision", VALUEFUNC(rbf_create_scaled_cylinder_collision), 4);
    rb_define_method(rba_cWorld, "create_capsule_collision", VALUEFUNC(rbf_create_capsule_collision), 3);
    rb_define_method(rba_cWorld, "create_scaled_capsule_collision", VALUEFUNC(rbf_create_scaled_capsule_collision), 4);
    rb_define_method(rba_cWorld, "create_tapered_capsule_collision", VALUEFUNC(rbf_create_tapered_capsule_collision), 4);
    rb_define_method(rba_cWorld, "create_tapered_cylinder_collision", VALUEFUNC(rbf_create_tapered_cylinder_collision), 4);
    rb_define_method(rba_cWorld, "create_chamfer_cylinder_collision", VALUEFUNC(rbf_create_chamfer_cylinder_collision), 3);
    rb_define_method(rba_cWorld, "create_scaled_chamfer_cylinder_collision", VALUEFUNC(rbf_create_scaled_chamfer_cylinder_collision), 4);
    rb_define_method(rba_cWorld, "create_convex_hull_collision", VALUEFUNC(rbf_create_convex_hull_collision), 3);
    rb_define_method(rba_cWorld, "create_compound_collision", VALUEFUNC(rbf_create_compound_collision), 1);
    rb_define_method(rba_cWorld, "create_static_mesh_collision", VALUEFUNC(rbf_create_static_mesh_collision), 2);
    rb_define_method(rba_cWorld, "create_scene_collision", VALUEFUNC(rbf_create_scene_collision), 1);
    rb_define_method(rba_cWorld, "collision_valid?", VALUEFUNC(rbf_is_collision_valid), 1);
    rb_define_method(rba_cWorld, "destroy_collision", VALUEFUNC(rbf_destroy_collision), 1);
}
