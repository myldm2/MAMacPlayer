//
//  ViewController.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/3/16.
//

#import "ViewController.h"
#import <libavcodec/codec.h>
#import <SDL2/SDL.h>

#define REFRESH_EVENT  (SDL_USEREVENT + 1)
#define QUIT_EVENT  (SDL_USEREVENT + 2)
int thread_exit=0;

int refresh_video_timer(void *udata){
    thread_exit=0;
    while (!thread_exit) {
        SDL_Event event;
        event.type = REFRESH_EVENT;
        SDL_PushEvent(&event);
        SDL_Delay(40);
    }

    thread_exit=0;

    //push quit event
    SDL_Event event;
    event.type = QUIT_EVENT;
    SDL_PushEvent(&event);
    return 0;
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self playVideo];
    

    
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)playVideo
{
    // Do any additional setup after loading the view.
    int ret = SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *window = SDL_CreateWindow("window", 0, 0, 1280, 720, SDL_WINDOW_SHOWN);
    
    SDL_Renderer *render = SDL_CreateRenderer(window, -1, 0);
    SDL_SetRenderDrawColor(render, 0, 255, 0, 1);
    SDL_RenderClear(render);
    SDL_RenderPresent(render);
    
    int videoWidth = 1280;
    int videoHeight = 720;
    
    uint32_t frame_data_len = videoWidth * videoHeight * 12 / 8;
    if ((frame_data_len | 0xfffffff0) & 0x0000000f) {
        frame_data_len = (frame_data_len & 0xfffffff0) + 0x10;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video1" ofType:@"yuv"];
    
    FILE *video_fd = NULL;
    video_fd = fopen(path.UTF8String, "r");
    
    
    SDL_Thread *timer_thread = NULL;
    SDL_Event event;
    
    timer_thread = SDL_CreateThread(refresh_video_timer,
                                        NULL,
                                        NULL);
    
    SDL_Texture *texture = NULL;
    texture = SDL_CreateTexture(render,
                                SDL_PIXELFORMAT_IYUV,
                                SDL_TEXTUREACCESS_STREAMING,
                                videoWidth,
                                videoHeight);
    
    void *frameData = malloc(frame_data_len);

    do {
        //Wait
        SDL_WaitEvent(&event);
        if(event.type==REFRESH_EVENT){
            
            if(fread(frameData, 1, frame_data_len, video_fd) <= 0){
                fprintf(stderr, "eof, exit thread!");
                thread_exit = 1;
                continue;// to wait event for exiting
            }
            
            SDL_UpdateTexture(texture, NULL, frameData, videoWidth);
//
//            //FIX: If window is resize
            SDL_Rect rect;
            rect.x = 0;
            rect.y = 0;
            rect.w = videoWidth;
            rect.h = videoHeight;

            SDL_RenderClear( render );
            SDL_RenderCopy( render, texture, NULL, &rect);
            SDL_RenderPresent( render );

        }else if(event.type==SDL_WINDOWEVENT){
            //If Resize
//            SDL_GetWindowSize(win, &w_width, &w_height);
        }else if(event.type==SDL_QUIT){
            thread_exit=1;
            SDL_DestroyWindow(window);
        }else if(event.type==QUIT_EVENT){
            break;
        }
    }while ( 1 );
}


@end
