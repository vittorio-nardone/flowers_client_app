//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"
#import <camera/CameraPlugin.h>
#import <flutter_native_image/FlutterNativeImagePlugin.h>
#import <path_provider/PathProviderPlugin.h>

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [CameraPlugin registerWithRegistrar:[registry registrarForPlugin:@"CameraPlugin"]];
  [FlutterNativeImagePlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterNativeImagePlugin"]];
  [FLTPathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTPathProviderPlugin"]];
}

@end
