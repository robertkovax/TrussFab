/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef MSP_H
#define MSP_H

#include "Newton.h"
#include "../utils/ruby_util.h"

#include <map>
#include <set>
#include <vector>

#define MSP_NON_COL_CONTACTS_CAPACITY 16
#define MSP_MAX_RAY_HITS              32

namespace MSP {
    // Classes
    class Entity;
    class Hit;
    class Contact;
    class World;
    class Body;

    class Joint;

    class Fixed;
    class Hinge;
    class AngularSpring;
    class Plane;
    class PointToPoint;
    class PointToPointActuator;
    class PointToPointGasSpring;
    class GenericPointToPoint;

    // Structures
    struct DelayedForceAndTorque {
        const NewtonBody* m_body;
        Geom::Vector3d m_force;
        Geom::Vector3d m_torque;

        DelayedForceAndTorque() :
            m_force(0.0),
            m_torque(0.0)
        {
            m_body = nullptr;
        }
    };

    struct CollisionData {
        Geom::Vector3d m_offset;
        Geom::Vector3d m_scale;

        CollisionData() :
            m_offset(0.0),
            m_scale(1.0, 1.0, 1.0)
        {}

        CollisionData(const Geom::Vector3d& offset) :
            m_offset(offset),
            m_scale(1.0, 1.0, 1.0)
        {}

        CollisionData(const Geom::Vector3d& offset, const Geom::Vector3d& scale) :
            m_offset(offset),
            m_scale(scale)
        {}

        CollisionData(const CollisionData& other) :
            m_offset(other.m_offset),
            m_scale(other.m_scale)
        {}
    };


    // Variables
    extern VALUE rba_cEntity;
    extern VALUE rba_cHit;
    extern VALUE rba_cContact;
    extern VALUE rba_cWorld;
    extern VALUE rba_cBody;
    extern VALUE rba_cJoint;

    // Ruby Functions
    VALUE rbf_newton_version(VALUE self);
    VALUE rbf_newton_float_size(VALUE self);
    VALUE rbf_newton_memory_used(VALUE self);

    // Main
    void init_ruby(VALUE mMSP);
}

#endif  /* MSP_H */
