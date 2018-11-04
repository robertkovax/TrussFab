/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef ANGULAR_INTEGRATION_H
#define ANGULAR_INTEGRATION_H

#include "../utils/geom.h"

class AngularIntegration {
public:
    treal m_angle;
    treal m_sin_angle;
    treal m_cos_angle;

    AngularIntegration();
    AngularIntegration(treal angle);

    treal get_angle() const;
    void set_angle(treal angle);
    treal update(treal new_angle_cos, treal new_angle_sin);
    treal update(treal angle);

    AngularIntegration operator+ (const AngularIntegration& angle) const;
    AngularIntegration operator- (const AngularIntegration& angle) const;
};

#endif  /* ANGULAR_INTEGRATION_H */
