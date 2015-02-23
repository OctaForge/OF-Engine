/* macutils.m - a collection of utilities for OS X
 *
 * tesseract launcher code used for reference
 */

#include <unistd.h>
#import <Cocoa/Cocoa.h>

extern const char *sethomedir(const char *dir);

#define BUNDLE_NAME @"OctaForge"
#define HOME_FALLBACK "$HOME/.octaforge"

void mac_set_homedir() {
    NSArray *supports = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    if ([supports count]) {
        NSString *path = [[supports objectAtIndex:0] path];
        path = [path stringByAppendingPathComponent:BUNDLE_NAME];
        if (![fm fileExistsAtPath:path]) [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]; // ensure it exists
        sethomedir([path UTF8String]);
    } else {
        sethomedir(HOME_FALLBACK);
    }
}

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
    return NULL;
}