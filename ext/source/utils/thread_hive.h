/*
 * ---------------------------------------------------------------------------------------------------------------------
 *
 * Copyright (C) 2018, Anton Synytsia
 *
 * ---------------------------------------------------------------------------------------------------------------------
 */

#ifndef THREAD_HIVE_H
#define THREAD_HIVE_H

#include "fast_queue.h"

#ifdef _WIN32
    #include "windows.h"
#else
    #include <pthread.h>
    #include <unistd.h>
#endif

class ThreadHive {
public:
    // Type-defines
    typedef void(*TaskCallback)(void* user_data, ThreadHive* hive);

private:
    // Disable copy constructor and assignment operator
    ThreadHive(const ThreadHive& other);
    ThreadHive& operator=(const ThreadHive& other);

    // Structures
    struct Task {
        TaskCallback m_task_callback;
        void* m_user_data;
    };

    // Variables
    FastQueue<Task> m_tasks;

#ifdef _WIN32
    HANDLE* m_bees;
    CRITICAL_SECTION m_queue_mutex;
    CRITICAL_SECTION m_user_mutex;
    CRITICAL_SECTION m_sem_mutex;
    CONDITION_VARIABLE m_all_idle_cond;
    CONDITION_VARIABLE m_sem_cond;
#else
    pthread_t* m_bees;
    pthread_mutex_t m_queue_mutex;
    pthread_mutex_t m_user_mutex;
    pthread_mutex_t m_sem_mutex;
    pthread_cond_t m_all_idle_cond;
    pthread_cond_t m_sem_cond;
#endif
    volatile unsigned int m_sem_val;
    unsigned int m_num_bees;
    unsigned int m_num_working;

    // Helper Functions
#ifdef _WIN32
    static DWORD WINAPI thread_task(LPVOID arg);
#else
    static void* thread_task(void* arg);
#endif

public:
    static unsigned int get_num_processors();

    ThreadHive(unsigned int num_bees);
    virtual ~ThreadHive();

    unsigned int get_num_bees() const;
    unsigned int get_num_tasks();
    void enqueue(TaskCallback task_callback, void* user_data);
    void wait_until_finished();
    void enter_critical_section();
    void leave_critical_section();
};

#endif  /* THREAD_HIVE_H */
