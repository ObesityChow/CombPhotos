//
//  main.m
//  CombPhoto
//
//  Created by Edward Chow on 5/13/15.
//  Copyright (c) 2015 Edward's. All rights reserved.
//
#define ENHANCINGRANGE 50
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
typedef enum
{
    CombModeCrossing,
    CombModeEnhancing
}CombMode;
void ScanFiles(NSFileManager * manager,NSMutableArray * listFile,NSString * rootPath,NSError ** error)
{
    NSArray * array = [manager contentsOfDirectoryAtPath:rootPath error:error];
    for(NSString * s in array)
    {
        NSString * path = [NSString stringWithFormat:@"%@/%@",rootPath,s];
        BOOL isDir = NO;
        [manager fileExistsAtPath:path isDirectory:&isDir];
        if(!isDir)
        {
            NSString *p = [path substringFromIndex:path.length - 4];
            if([[p uppercaseString] compare:@".JPG"] == NSOrderedSame)
                [listFile addObject:path];
        }
        else
        {
            ScanFiles(manager,listFile,path,error);
        }
    }
}
void CombPhoto_Crossing(unsigned char * data,NSArray * files,size_t w,size_t h)
{
    CGImageRef image;
    CGContextRef tempContext;
    CGDataProviderRef  provider;
    
    double * cache = malloc(sizeof(double) * 4 * w * h);
    for(NSString * path in files)
    {
        
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
                
                /*
                 data[pixOff] += red / (double)fileList.count;
                 data[pixOff+1] += green / (double)fileList.count;
                 data[pixOff+2] += blue / (double)fileList.count;
                 */
                
                cache[pixOff] += (double)red / files.count;
                cache[pixOff+1] += (double)green / files.count;
                cache[pixOff+2] += (double)blue / files.count;
                //NSLog(@"%lf,%d,%d \t",cache[pixOff],green,blue);
                
                pixOff += 4;
            }
            wOff += w * 4;
        }
        //////
        
        NSLog(@"%2.1lf%%\n",(double)([files indexOfObject:path]+1)/files.count*100.0f);
        CFRelease(provider);
        CFRelease(image);
        CFRelease(tempContext);
        
    }
    
    int wOff = 0;
    int pixOff = 0;
    for(size_t y = 0;y<h;y++)
    {
        for(size_t x = 0; x < w;++x)
        {
            int red = (unsigned char)cache[pixOff];
            int green = (unsigned char)cache[pixOff+1];
            int blue = (unsigned char)cache[pixOff+2];
            
            
            data[pixOff] = red;
            data[pixOff+1] = green;
            data[pixOff+2] = blue;
            
            //NSLog(@"%lf,%d,%d \t",cache[pixOff],green,blue);
            
            pixOff += 4;
        }
        wOff += w * 4;
    }

}
void CombPhoto_Enhancing(unsigned char * data,NSArray * files,size_t w,size_t h)
{
    CGImageRef image;
    CGContextRef tempContext;
    CGDataProviderRef  provider;
    
    double * cache = malloc(sizeof(double) * 4 * w * h);
    for(NSString * path in files)
    {
        
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
                
                /*
                 data[pixOff] += red / (double)fileList.count;
                 data[pixOff+1] += green / (double)fileList.count;
                 data[pixOff+2] += blue / (double)fileList.count;
                 */
                
                if(ABS(cache[pixOff] - red) > ENHANCINGRANGE)
                    cache[pixOff] = MAX(cache[pixOff],red);
                
                if(ABS(cache[pixOff+1] - green) > ENHANCINGRANGE)
                    cache[pixOff+1] = MAX(cache[pixOff+1],green);
                
                if(ABS(cache[pixOff+2] - blue) > ENHANCINGRANGE)
                    cache[pixOff+2] = MAX(cache[pixOff+2],blue);

                        
                
                //cache[pixOff] += (double)red / files.count;
                //cache[pixOff+1] += (double)green / files.count;
                //cache[pixOff+2] += (double)blue / files.count;
                //NSLog(@"%lf,%d,%d \t",cache[pixOff],green,blue);
                
                pixOff += 4;
            }
            wOff += w * 4;
        }
        //////
        
        NSLog(@"%2.1lf%%\n",(double)([files indexOfObject:path]+1)/files.count*100.0f);
        CFRelease(provider);
        CFRelease(image);
        CFRelease(tempContext);
        
    }
    
    int wOff = 0;
    int pixOff = 0;
    for(size_t y = 0;y<h;y++)
    {
        for(size_t x = 0; x < w;++x)
        {
            int red = (unsigned char)cache[pixOff];
            int green = (unsigned char)cache[pixOff+1];
            int blue = (unsigned char)cache[pixOff+2];
            
            
            data[pixOff] = red;
            data[pixOff+1] = green;
            data[pixOff+2] = blue;
            
            //NSLog(@"%lf,%d,%d \t",cache[pixOff],green,blue);
            
            pixOff += 4;
        }
        wOff += w * 4;
    }

}
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        CombMode mode = CombModeCrossing;
        NSString * finalPath;
        NSFileManager * manager = [NSFileManager defaultManager];
        NSMutableArray * fileList = [[NSMutableArray alloc] init];
        NSError * error;

        switch (argc) {
            case 3:
                ScanFiles(manager,fileList,[NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding],&error);
                finalPath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
                mode = CombModeCrossing;
                NSLog(@"Crossing Mode\n");
            case 4:
                ScanFiles(manager,fileList,[NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding],&error);
                finalPath = [NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding];
                mode = CombModeEnhancing;
                NSLog(@"Enhancing Mode\n");
                break;
            default:
                printf("Paragraph error\n\n");
                printf("----CombPhoto [-C / -E] sourceDic targetPath");
                
                return 0;

                break;
        }
        
        

        if(error)
        {
            NSLog(@"%@",error);
            return 0;
        }
    
        
        
        
        
        
        CGImageRef image;
        CGContextRef finalContext;
        CGDataProviderRef  provider;
        provider = CGDataProviderCreateWithFilename([(NSString *)fileList[0] cStringUsingEncoding:NSUTF8StringEncoding]);
        
        
        
        image =  CGImageCreateWithJPEGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);
        NSLog(@"%zu,%zu",CGImageGetWidth(image),CGImageGetHeight(image));
        finalContext =  CGBitmapContextCreate(nil, CGImageGetWidth(image), CGImageGetHeight(image), CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), CGImageGetColorSpace(image), CGImageGetBitmapInfo(image));
        
        size_t w = CGImageGetWidth(image);
        size_t h = CGImageGetHeight(image);
        
        unsigned char * data = CGBitmapContextGetData(finalContext);
        
        switch (mode) {
            case CombModeCrossing:
                CombPhoto_Crossing(data, fileList, w, h);
                break;
            case CombModeEnhancing:
                CombPhoto_Enhancing(data, fileList, w, h);
                break;
            default:
                CombPhoto_Crossing(data, fileList, w, h);
                break;
        }
        /*
        double * cache = malloc(sizeof(double) * 4 * w * h);
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
                    
                    
                    //data[pixOff] += red / (double)fileList.count;
                    //data[pixOff+1] += green / (double)fileList.count;
                    //data[pixOff+2] += blue / (double)fileList.count;
                    
                    
                    cache[pixOff] += (double)red / fileList.count;
                    cache[pixOff+1] += (double)green / fileList.count;
                    cache[pixOff+2] += (double)blue / fileList.count;
                    //NSLog(@"%lf,%d,%d \t",cache[pixOff],green,blue);
                    
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
        
        int wOff = 0;
        int pixOff = 0;
        for(size_t y = 0;y<h;y++)
        {
            for(size_t x = 0; x < w;++x)
            {
                int red = (unsigned char)cache[pixOff];
                int green = (unsigned char)cache[pixOff+1];
                int blue = (unsigned char)cache[pixOff+2];
                
                
                data[pixOff] = red;
                data[pixOff+1] = green;
                data[pixOff+2] = blue;
            
                //NSLog(@"%lf,%d,%d \t",cache[pixOff],green,blue);
                
                pixOff += 4;
            }
            wOff += w * 4;
        }
        */
        
        CGImageRef finalimage = CGBitmapContextCreateImage(finalContext);
        
        CFMutableDataRef da = CFDataCreateMutable(CFAllocatorGetDefault(), 0);
        
        CGImageDestinationRef ref = CGImageDestinationCreateWithData(da, kUTTypeJPEG, 1, nil);
        
        CGImageDestinationAddImage(ref, finalimage, nil);
        
        CGImageDestinationFinalize(ref);
        
        NSData * dddd = (NSData *)CFBridgingRelease(da);
        
        [dddd writeToFile:finalPath atomically:YES];
    
        NSLog(@"DONE...");
        NSLog(@"The picture is saved to '%@'",finalPath);
    }
    return 0;
}
