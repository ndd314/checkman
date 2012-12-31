#import "Settings.h"
#import "FSChangesNotifier.h"

@interface Settings () <FSChangesNotifierDelegate>
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) FSChangesNotifier *fsChangesNotifier;
@end

@implementation Settings

@synthesize
    delegate = _delegate,
    userDefaults = _userDefaults,
    fsChangesNotifier = _fsChangesNotifier;

// http://stackoverflow.com/questions/2199106/thread-safe-instantiation-of-a-singleton
+ (Settings *)userSettings {
    static Settings *userSettings = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        userSettings = [Settings alloc];
        userSettings = [userSettings initWithUserDefaults:userDefaults];
    });
    return userSettings;
}

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults {
    if (self = [super init]) {
        self.userDefaults = userDefaults;
        self.fsChangesNotifier = [[FSChangesNotifier alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.fsChangesNotifier stopNotifying:self];
}

#pragma mark -

- (void)trackChanges {
    NSString *tildeFilePath = F(@"~/Library/Preferences/%@.plist", NSBundle.mainBundle.bundleIdentifier);
    NSString *filePath = [tildeFilePath stringByExpandingTildeInPath];

    [self.fsChangesNotifier startNotifying:self forFilePath:filePath.stringByDeletingLastPathComponent];
    [self.fsChangesNotifier startNotifying:self forFilePath:filePath];
}

- (void)fsChangesNotifier:(FSChangesNotifier *)notifier filePathDidChange:(NSString *)filePath {
    [self.userDefaults synchronize];
    [self.delegate settingsDidChange:self];
}

#pragma mark - Check specific

- (NSUInteger)runIntervalForCheckWithName:(NSString *)name
                      inCheckfileWithName:(NSString *)checkfileName {
    static NSString *key = @"checks.%@.%@.runInterval";

    NSInteger runInterval = [self.userDefaults integerForKey:F(key, checkfileName, name)];
    return runInterval > 0 ? (NSUInteger)runInterval : self._checkRunInterval;
}

- (BOOL)isCheckWithNameDisabled:(NSString *)name
            inCheckfileWithName:(NSString *)checkfileName {
    static NSString *key = @"checks.%@.%@.disabled";
    return [self.userDefaults boolForKey:F(key, checkfileName, name)];
}

#pragma mark -

- (NSUInteger)_checkRunInterval {
    static NSString *key = @"checkRunInterval";
    static NSUInteger defaultValue = 10;

    NSNumber *value = [self.userDefaults objectForKey:key];
    return value.unsignedIntegerValue > 0 ? value.unsignedIntegerValue : defaultValue;
}
@end
