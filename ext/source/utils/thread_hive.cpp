/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#include "thread_hive.h"
#include <string.h>


unsigned int ThreadHive::get_num_processors() {
#ifdef _WIN32
    _SYSTEM_INFO sinfo;
    GetNativeSystemInfo(&sinfo);
    return sinfo.dwNumberOfProcessors;
#else
    return static_cast<unsigned int>(sysconf(_SC_NPROCESSORS_ONLN));
#endif
}

ThreadHive::ThreadHive(unsigned int num_bees) :
    m_num_bees(num_bees),
    m_num_working(0),
    m_sem_val(0)
{
#ifdef _WIN32
    m_bees = (HANDLE*)malloc(sizeof(HANDLE) * m_num_bees);
    memset(m_bees, 0, sizeof(HANDLE) * m_num_bees);

    InitializeCriticalSectionAndSpinCount(&m_queue_mutex, 0x00000400);
    InitializeCriticalSectionAndSpinCount(&m_user_mutex, 0x00000400);
    InitializeCriticalSection(&m_sem_mutex);
    InitializeConditionVariable(&m_all_idle_cond);
    InitializeConditionVariable(&m_sem_cond);

    for (unsigned int i = 0; i < m_num_bees; ++i) {
        m_bees[i] = CreateThread(NULL, 0, thread_task, this, 0, NULL);
    }
#else
    m_bees = (pthread_t*)malloc(sizeof(pthread_t) * m_num_bees);
    memset(m_bees, 0, sizeof(pthread_t) * m_num_bees);

    pthread_mutex_init(&m_queue_mutex, NULL);
    pthread_mutex_init(&m_user_mutex, NULL);
    pthread_mutex_init(&m_sem_mutex, NULL);
    pthread_cond_init(&m_all_idle_cond, NULL);
    pthread_cond_init(&m_sem_cond, NULL);

    for (unsigned int i = 0; i < m_num_bees; ++i) {
        pthread_create(m_bees + i, NULL, &thread_task, this);
    }
#endif
}

ThreadHive::~ThreadHive() {
    unsigned int i;

    wait_until_finished();
#ifdef _WIN32

    EnterCriticalSection(&m_sem_mutex);
    m_sem_val = 2; // terminate
    WakeAllConditionVariable(&m_sem_cond);
    LeaveCriticalSection(&m_sem_mutex);

    WaitForMultipleObjects(m_num_bees, m_bees, TRUE, INFINITE);

    for (i = 0; i < m_num_bees; ++i) {
        if (m_bees[i] != NULL)
            CloseHandle(m_bees[i]);
    }

    DeleteCriticalSection(&m_queue_mutex);
    DeleteCriticalSection(&m_user_mutex);
    DeleteCriticalSection(&m_sem_mutex);
    // Condition variables cannot be deleted on Windows

#else

    pthread_mutex_lock(&m_sem_mutex);
    m_sem_val = 2; // terminate
    pthread_cond_broadcast(&m_sem_cond);
    pthread_mutex_unlock(&m_sem_mutex);

    for (i = 0; i < m_num_bees; ++i) {
        if (m_bees[i] != NULL)
            pthread_join(m_bees[i], NULL);
    }

    pthread_mutex_destroy(&m_queue_mutex);
    pthread_mutex_destroy(&m_user_mutex);
    pthread_mutex_destroy(&m_sem_mutex);
    pthread_cond_destroy(&m_all_idle_cond);
    pthread_cond_destroy(&m_sem_cond);

#endif
}

#ifdef _WIN32

DWORD WINAPI ThreadHive::thread_task(LPVOID arg) {
    ThreadHive* hive = reinterpret_cast<ThreadHive*>(arg);

    while (true) {
        EnterCriticalSection(&(hive->m_queue_mutex));

        if (hive->m_tasks.empty()) {
            LeaveCriticalSection(&(hive->m_queue_mutex));

            // Sleep thread while nothing to process
            EnterCriticalSection(&(hive->m_sem_mutex));
            while (hive->m_sem_val == 0)
                SleepConditionVariableCS(&(hive->m_sem_cond), &(hive->m_sem_mutex), INFINITE);
            if (hive->m_sem_val == 2) {
                LeaveCriticalSection(&(hive->m_sem_mutex));
                break;
            }
            else {
                hive->m_sem_val = 0;
                LeaveCriticalSection(&(hive->m_sem_mutex));
            }
        }
        else {
            // Get task
            Task task;
            hive->m_tasks.dequeue(task);

            // Increment working counter
            ++(hive->m_num_working);

            LeaveCriticalSection(&(hive->m_queue_mutex));

            // Process task
            task.m_task_callback(task.m_user_data, hive);

            // Decrement working counter
            EnterCriticalSection(&(hive->m_queue_mutex));

            --(hive->m_num_working);

            // Signal completion
            if (hive->m_num_working == 0 && hive->m_tasks.empty())
                WakeConditionVariable(&(hive->m_all_idle_cond));

            LeaveCriticalSection(&(hive->m_queue_mutex));
        }
    }

    return 0;
}

#else

void* ThreadHive::thread_task(void* arg) {
    ThreadHive* hive = reinterpret_cast<ThreadHive*>(arg);

    while (true) {
        pthread_mutex_lock(&(hive->m_queue_mutex));

        if (hive->m_tasks.empty()) {
            pthread_mutex_unlock(&(hive->m_queue_mutex));

            // Sleep thread while nothing to process
            pthread_mutex_lock(&(hive->m_sem_mutex));
            while (hive->m_sem_val == 0)
                pthread_cond_wait(&(hive->m_sem_cond), &(hive->m_sem_mutex));
            if (hive->m_sem_val == 2) {
                pthread_mutex_unlock(&(hive->m_sem_mutex));
                break;
            }
            else {
                hive->m_sem_val = 0;
                pthread_mutex_unlock(&(hive->m_sem_mutex));
            }
        }
        else {
            // Get task
            Task task;
            hive->m_tasks.dequeue(task);

            // Increment working counter
            ++(hive->m_num_working);

            pthread_mutex_unlock(&(hive->m_queue_mutex));

            // Process task
            task.m_task_callback(task.m_user_data, hive);

            // Decrement working counter
            pthread_mutex_lock(&(hive->m_queue_mutex));

            --(hive->m_num_working);

            // Signal completion
            if (hive->m_num_working == 0 && hive->m_tasks.empty())
                pthread_cond_signal(&(hive->m_all_idle_cond));

            pthread_mutex_unlock(&(hive->m_queue_mutex));
        }
    }

    return 0;
}

#endif

unsigned int ThreadHive::get_num_bees() const {
    return m_num_bees;
}

unsigned int ThreadHive::get_num_tasks() {
    unsigned int num_tasks;
#ifdef _WIN32
    EnterCriticalSection(&m_queue_mutex);
    num_tasks = m_tasks.size();
    LeaveCriticalSection(&m_queue_mutex);
#else
    pthread_mutex_lock(&m_queue_mutex);
    num_tasks = m_tasks.size();
    pthread_mutex_unlock(&m_queue_mutex);
#endif
    return num_tasks;
}

void ThreadHive::enqueue(TaskCallback task_callback, void* user_data) {
    Task task;
    task.m_task_callback = task_callback;
    task.m_user_data = user_data;

#ifdef _WIN32
    EnterCriticalSection(&m_queue_mutex);
    m_tasks.enqueue(task);
    LeaveCriticalSection(&m_queue_mutex);

    EnterCriticalSection(&m_sem_mutex);
    m_sem_val = 1;
    WakeConditionVariable(&m_sem_cond);
    LeaveCriticalSection(&m_sem_mutex);
#else
    pthread_mutex_lock(&m_queue_mutex);
    m_tasks.enqueue(task);
    pthread_mutex_unlock(&m_queue_mutex);

    pthread_mutex_lock(&m_sem_mutex);
    m_sem_val = 1;
    pthread_cond_signal(&m_sem_cond);
    pthread_mutex_unlock(&m_sem_mutex);
#endif
}

void ThreadHive::wait_until_finished() {
#ifdef _WIN32
    EnterCriticalSection(&m_queue_mutex);
    while (!m_tasks.empty() || m_num_working != 0)
        SleepConditionVariableCS(&m_all_idle_cond, &m_queue_mutex, INFINITE);
    LeaveCriticalSection(&m_queue_mutex);
#else
    pthread_mutex_lock(&m_queue_mutex);
    while (!m_tasks.empty() || m_num_working != 0)
        pthread_cond_wait(&m_all_idle_cond, &m_queue_mutex);
    pthread_mutex_unlock(&m_queue_mutex);
#endif
}

void ThreadHive::enter_critical_section() {
#ifdef _WIN32
    EnterCriticalSection(&m_user_mutex);
#else
    pthread_mutex_lock(&m_user_mutex);
#endif
}

void ThreadHive::leave_critical_section() {
#ifdef _WIN32
    LeaveCriticalSection(&m_user_mutex);
#else
    pthread_mutex_unlock(&m_user_mutex);
#endif
}
