/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "geom_vector4d.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Constructors
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

Geom::Vector4d::Vector4d() :
    Vector3d(),
    m_w(0.0)
{
}

Geom::Vector4d::Vector4d(treal value) :
    Vector3d(value),
    m_w(0.0)
{
}

Geom::Vector4d::Vector4d(const Vector4d& other) :
    Vector3d(other),
    m_w(other.m_w)
{
}

Geom::Vector4d::Vector4d(treal x, treal y, treal z, treal w) :
    Vector3d(x, y, z),
    m_w(w)
{
}

Geom::Vector4d::Vector4d(const treal* values) :
    Vector3d(values),
    m_w(values[3])
{
}

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Operators
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

Geom::Vector4d& Geom::Vector4d::operator=(const Vector4d& other) {
    if (this != &other) {
        m_x = other.m_x;
        m_y = other.m_y;
        m_z = other.m_z;
        m_w = other.m_w;
    }
    return *this;
}

Geom::Vector4d& Geom::Vector4d::operator=(const Vector3d& other) {
    if (this != &other) {
        m_x = other.m_x;
        m_y = other.m_y;
        m_z = other.m_z;
    }
    return *this;
}

bool operator == (const Geom::Vector4d& lhs, const Geom::Vector4d& rhs) {
    return (fabs(lhs.m_x - rhs.m_x) < M_EPSILON &&
        fabs(lhs.m_y - rhs.m_y) < M_EPSILON &&
        fabs(lhs.m_z - rhs.m_z) < M_EPSILON &&
        fabs(lhs.m_w - rhs.m_w) < M_EPSILON);
}

bool operator != (const Geom::Vector4d& lhs, const Geom::Vector4d& rhs) {
    return !(lhs == rhs);
}

Geom::Vector4d operator * (Geom::Vector4d v, treal scalar) {
    v.m_x *= scalar;
    v.m_y *= scalar;
    v.m_z *= scalar;
    v.m_w *= scalar;
    return v;
}

Geom::Vector4d operator * (treal scalar, Geom::Vector4d v) {
    v.m_x *= scalar;
    v.m_y *= scalar;
    v.m_z *= scalar;
    v.m_w *= scalar;
    return v;
}

Geom::Vector4d operator + (Geom::Vector4d lhs, const Geom::Vector4d& rhs) {
    lhs.m_x += rhs.m_x;
    lhs.m_y += rhs.m_y;
    lhs.m_z += rhs.m_z;
    lhs.m_w += rhs.m_w;
    return lhs;
}

Geom::Vector4d operator - (Geom::Vector4d lhs, const Geom::Vector4d& rhs) {
    lhs.m_x -= rhs.m_x;
    lhs.m_y -= rhs.m_y;
    lhs.m_z -= rhs.m_z;
    lhs.m_w -= rhs.m_w;
    return lhs;
}

Geom::Vector4d& Geom::Vector4d::operator *= (treal scalar) {
    m_x *= scalar;
    m_y *= scalar;
    m_z *= scalar;
    return *this;
}

Geom::Vector4d& Geom::Vector4d::operator += (const Vector4d& other) {
    m_x += other.m_x;
    m_y += other.m_y;
    m_z += other.m_z;
    m_w += other.m_w;
    return *this;
}

Geom::Vector4d& Geom::Vector4d::operator -= (const Vector4d& other) {
    m_x -= other.m_x;
    m_y -= other.m_y;
    m_z -= other.m_z;
    m_w -= other.m_w;
    return *this;
}
