/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "msp_hit.h"

/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Helper Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Hit::c_class_allocate(VALUE klass) {
    Data* data = new Data;
    return Data_Wrap_Struct(klass, c_class_mark, c_class_deallocate, data);
}

void MSP::Hit::c_class_mark(void* data_ptr) {
    Data* data = reinterpret_cast<Data*>(data_ptr);
    rb_gc_mark(data->v_body);
}

void MSP::Hit::c_class_deallocate(void* data_ptr) {
    Data* data = reinterpret_cast<Data*>(data_ptr);
    delete data;
}

MSP::Hit::Data* MSP::Hit::c_to_data(VALUE self) {
    Data* data;
    Data_Get_Struct(self, Data, data);
    return data;
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Ruby Functions
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

VALUE MSP::Hit::rbf_initialize(VALUE self) {
    return self;
}

VALUE MSP::Hit::rbf_initialize_copy(VALUE self, VALUE orig_self) {
    Data* data;
    Data* orig_data;

#ifndef RUBY_VERSION18
    if (!OBJ_INIT_COPY(self, orig_self)) return self;
#endif

    Data_Get_Struct(self, Data, data);
    Data_Get_Struct(orig_self, Data, orig_data);

    data->v_body = orig_data->v_body;
    data->m_point = orig_data->m_point;
    data->m_normal = orig_data->m_normal;

    return self;
}

VALUE MSP::Hit::rbf_get_body(VALUE self) {
    Data* data = c_to_data(self);
    return data->v_body;
}

VALUE MSP::Hit::rbf_get_point(VALUE self) {
    Data* data = c_to_data(self);
    return RU::point_to_value(data->m_point);
}

VALUE MSP::Hit::rbf_get_normal(VALUE self) {
    Data* data = c_to_data(self);
    return RU::vector_to_value(data->m_normal);
}


/*
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Main
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

void MSP::Hit::init_ruby(VALUE mMSP) {
    rba_cHit = rb_define_class_under(mMSP, "Hit", rba_cEntity);

    rb_define_alloc_func(rba_cHit, c_class_allocate);

    rb_define_method(rba_cHit, "initialize", VALUEFUNC(rbf_initialize), 0);
    rb_define_method(rba_cHit, "initialize_copy", VALUEFUNC(rbf_initialize_copy), 1);

    rb_define_method(rba_cHit, "body", VALUEFUNC(rbf_get_body), 0);
    rb_define_method(rba_cHit, "point", VALUEFUNC(rbf_get_point), 0);
    rb_define_method(rba_cHit, "normal", VALUEFUNC(rbf_get_normal), 0);
}
