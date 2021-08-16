//
//  masdl_thread.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/6/11.
//

#ifndef masdl_thread_h
#define masdl_thread_h

#include <stdio.h>
#include <stdint.h>
#include <pthread.h>

typedef enum {
    SDL_THREAD_PRIORITY_LOW,
    SDL_THREAD_PRIORITY_NORMAL,
    SDL_THREAD_PRIORITY_HIGH
} SDL_ThreadPriority;

typedef struct SDL_Thread
{
    pthread_t id;
    int (*func)(void *);
    void *data;
    char name[32];
    int retval;
} SDL_Thread;

SDL_Thread *SDL_CreateThreadEx(SDL_Thread *thread, int (*fn)(void *), void *data, const char *name);
int         SDL_SetThreadPriority(SDL_ThreadPriority priority);
void        SDL_WaitThread(SDL_Thread *thread, int *status);
void        SDL_DetachThread(SDL_Thread *thread);

#endif /* masdl_thread_h */
