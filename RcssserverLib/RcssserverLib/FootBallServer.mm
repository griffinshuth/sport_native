//
//  FootBallServer.m
//  RcssserverLib
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#import "FootBallServer.h"
#include "main.hpp"

@implementation FootBallServer
{
    main* server;
}
-(id)init{
    self = [super init];
    if(self){
        server = new main();
        server->init();
    }
    return self;
}

-(void)dealloc{
    server->destroy();
    delete server;
}

-(void)run{
    server->run();
}
@end
