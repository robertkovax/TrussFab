/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "angular_integration.h"

AngularIntegration::AngularIntegration() {
    set_angle(0.0f);
}

AngularIntegration::AngularIntegration(treal angle) {
    set_angle(angle);
}

treal AngularIntegration::get_angle() const {
    return m_angle;
}

void AngularIntegration::set_angle(treal angle) {
    m_angle = angle;
    m_sin_angle = sin(angle);
    m_cos_angle = cos(angle);
}

treal AngularIntegration::update(treal new_angle_cos, treal new_angle_sin) {
    treal sin_da = new_angle_sin * m_cos_angle - new_angle_cos * m_sin_angle;
    treal cos_da = new_angle_cos * m_cos_angle + new_angle_sin * m_sin_angle;

    m_angle += atan2(sin_da, cos_da);
    m_cos_angle = new_angle_cos;
    m_sin_angle = new_angle_sin;

    return m_angle;
}

treal AngularIntegration::update(treal angle) {
    return update(cos(angle), sin(angle));
}

AngularIntegration AngularIntegration::operator+ (const AngularIntegration& angle) const {
    treal sin_da = angle.m_sin_angle * m_cos_angle + angle.m_cos_angle * m_sin_angle;
    treal cos_da = angle.m_cos_angle * m_cos_angle - angle.m_sin_angle * m_sin_angle;
    return AngularIntegration(m_angle + atan2(sin_da, cos_da));
}

AngularIntegration AngularIntegration::operator- (const AngularIntegration& angle) const {
    treal sin_da = angle.m_sin_angle * m_cos_angle - angle.m_cos_angle * m_sin_angle;
    treal cos_da = angle.m_cos_angle * m_cos_angle + angle.m_sin_angle * m_sin_angle;
    return AngularIntegration(atan2(sin_da, cos_da));
}
