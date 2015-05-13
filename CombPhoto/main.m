//
//  main.m
//  CombPhoto
//
//  Created by Edward Chow on 5/13/15.
//  Copyright (c) 2015 Edward's. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSFileManager * manager = [NSFileManager defaultManager];
        NSError * error;
        NSArray *templist = [manager contentsOfDirectoryAtPath:[NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding] error:&error];
        if(error)
        {
            NSLog(@"%@",error);
            return 0;
        }
        NSMutableArray * fileList = [[NSMutableArray alloc] init];
        for(NSString * s in templist)
        {
            NSString * path = [NSString stringWithFormat:@"%@%@",[NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding],s];
            BOOL isDir = NO;
            [manager fileExistsAtPath:path isDirectory:&isDir];
            if(!isDir)
            {
                
                NSString *p = [path substringFromIndex:path.length - 4];
                if([[p uppercaseString] compare:@".JPG"] == NSOrderedSame)
                    [fileList addObject:path];
            }
        }

        
        
        
        CGImageRef image;
        CGContextRef finalContext,tempContext;
        
        CGDataProviderRef  provider;
        provider = CGDataProviderCreateWithFilename([(NSString *)fileList[0] cStringUsingEncoding:NSUTF8StringEncoding]);
        
        
        
        image =  CGImageCreateWithJPEGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);
        NSLog(@"%zu,%zu",CGImageGetWidth(image),CGImageGetHeight(image));
        finalContext =  CGBitmapContextCreate(nil, CGImageGetWidth(image), CGImageGetHeight(image), CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), CGImageGetColorSpace(image), CGImageGetBitmapInfo(image));
        
        size_t w = CGImageGetWidth(image);
        size_t h = CGImageGetHeight(image);
        
        unsigned char * data = CGBitmapContextGetData(finalContext);
        
        
        for(int i = 0; i < fileList.count;++i )
        {

            NSString * path = fileList[i];
              NSLog(@"%@",path);
            provider = CGDataProviderCreateWithFilename([path cStringUsingEncoding:NSUTF8StringEncoding]);
            
            image = CGImageCreateWithJPEGDataProvider(provider, nil, NO, kCGRenderingIntentDefault);
            tempContext = CGBitmapContextCreate(nil, w, h, CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), CGImageGetColorSpace(image), CGImageGetBitmapInfo(image));
            CGRect rect = CGRectMake(0, 0, w, h);
            CGContextDrawImage(tempContext , rect , image);
            unsigned char * prodata = CGBitmapContextGetData(tempContext);
          
            ///////
            int wOff = 0;
            int pixOff = 0;
            for(size_t y = 0;y<h;y++)
            {
                for(size_t x = 0; x < w;++x)
                {
                    int red = (unsigned char)prodata[pixOff];
                    int green = (unsigned char)prodata[pixOff+1];
                    int blue = (unsigned char)prodata[pixOff+2];
                    
                    data[pixOff] += red / (double)fileList.count;
                    data[pixOff+1] += green / (double)fileList.count;
                    data[pixOff+2] += blue / (double)fileList.count;
                    
                    //NSLog(@"%d,%d,%d \t",(int)(red / 9.0f),green,blue);
                    
                    pixOff += 4;
                }
                wOff += w * 4;
            }
            //////
            NSLog(@"%2.1lf%%\n",(double)i/fileList.count*100.0f);
            CFRelease(provider);
            CFRelease(image);
            CFRelease(tempContext);
            
        }
        
        CGImageRef finalimage = CGBitmapContextCreateImage(finalContext);
        
        CFMutableDataRef da = CFDataCreateMutable(CFAllocatorGetDefault(), 0);
        
        CGImageDestinationRef ref = CGImageDestinationCreateWithData(da, kUTTypeJPEG, 1, nil);
        
        CGImageDestinationAddImage(ref, finalimage, nil);
        
        CGImageDestinationFinalize(ref);
        
        
        NSData * dddd = (__bridge_transfer NSData *)da;
        
        [dddd writeToFile:[NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding] atomically:YES];
    
    }
    return 0;
}
