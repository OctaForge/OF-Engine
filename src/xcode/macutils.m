/* macutils.m - a collection of utilities for OS X
 *
 * tesseract launcher code used for reference
 */

#include <stdio.h>
#include <unistd.h>
#import <Cocoa/Cocoa.h>

#define BUNDLE_NAME @"OctaForge"

void mac_set_datapath() {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    /* makefile + command line setups */
    NSString *dpath = [path stringByDeletingLastPathComponent];
    if ([fm fileExistsAtPath:[dpath stringByAppendingPathComponent:@"media"]]) {
        chdir([dpath UTF8String]);
        return;
    }
    /* release app bundle */
    dpath = [path stringByAppendingPathComponent:@"Contents/gamedata"];
    if ([fm fileExistsAtPath:dpath]) {
        chdir([dpath UTF8String]);
        return;
    }
    /* development bundle setup - nasty */
    NSString *paths[] = {
        [path stringByDeletingLastPathComponent], /* relative to the binary */
        [NSString stringWithUTF8String:__FILE__]  /* relative to the source code - xcode 4+ */
    };
    for (size_t i = 0; i < 2; i++) {
        NSString *dpath = paths[i];
        while ([dpath length] > 1) {
            dpath = [dpath stringByDeletingLastPathComponent];
            /* FIXME: get rid of bundle name here */
            NSString *probe = [dpath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.app/Contents/gamedata", BUNDLE_NAME]];
            if ([fm fileExistsAtPath:[probe stringByAppendingPathComponent:@"media"]]) {
                chdir([probe UTF8String]);
                return;
            } else if ([fm fileExistsAtPath:[dpath stringByAppendingPathComponent:@"media"]]) {
                chdir([dpath UTF8String]);
                return;
            }
        }
    }
}