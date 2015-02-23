/* macutils.m - a collection of utilities for OS X
 *
 * tesseract launcher code used for reference
 */

#include <stdio.h>
#include <string.h>

char *mac_get_homedir(const char *projname) {
    NSArray *supports = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    if ([supports count]) {
        NSString *path = [[supports objectAtIndex:0] path];
        path = [path stringByAppendingPathComponent:projname];
        if (![fm fileExistsAtPath:path]) [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]; // ensure it exists
        return strdup([path UTF8String])
    }
    return NULL;
}