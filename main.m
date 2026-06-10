#import <Cocoa/Cocoa.h>

@interface TimerView : NSView
@property NSInteger currentSeconds;
@property NSInteger targetSeconds;
@property NSString *timerName;
@property BOOL paused;
@property NSTimer *timer;
@property NSMutableArray *sessionLogs; 
@end

@implementation TimerView

// Central method to append any text line to ~/Documents/TimerLogs.txt
- (void)appendLogToFile:(NSString *)logMessage
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"TimerLogs.txt"];
    
    NSString *entryWithNewline = [NSString stringWithFormat:@"%@\n", logMessage];
    NSData *data = [entryWithNewline dataUsingEncoding:NSUTF8StringEncoding];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:filePath]) {
        [data writeToFile:filePath atomically:YES];
    } else {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }
}

// Replicates the exact look of macOS NSLog and commits it to the file
- (void)logLiveEvent:(NSString *)eventDescription
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    long threadId = (long)[[NSThread currentThread] hash]; // Generates a consistent thread token
    
    NSString *formattedLog = [NSString stringWithFormat:@"%@ Timer[%d:%ld] %@", 
                              dateString, pid, threadId, eventDescription];
    
    [self appendLogToFile:formattedLog];
    printf("%s\n", [formattedLog UTF8String]); // Echo to terminal
}

- (void)recordSession
{
    if (_currentSeconds == 0) return;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];

    NSString *logEntry = [NSString stringWithFormat:@"📝 SAVED: [%@] [%@] Target: %lds | Actual: %lds", 
                          dateString,
                          _timerName,
                          (long)_targetSeconds, 
                          (long)_currentSeconds];
    
    [_sessionLogs addObject:logEntry];
    [self appendLogToFile:logEntry];
    
    printf("%s\n", [logEntry UTF8String]);
}

- (void)printFinalLogsAndQuit
{
    [self recordSession];
    
    printf("\n=== SESSION COMPLETE ===\n");
    printf("Your logs have been saved to: ~/Documents/TimerLogs.txt\n");
    printf("========================\n\n");
    
    [NSApp terminate:nil];
}

- (void)mouseDown:(NSEvent *)event
{
    _paused = !_paused;
    [self logLiveEvent:_paused ? @"Timer PAUSED" : @"Timer RUNNING"];
    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event
{
    NSAlert *alert = [[NSAlert alloc] init];

    [alert setMessageText:@"Quit Timer?"];
    [alert setInformativeText:@"Are you sure you want to quit?"];

    [alert addButtonWithTitle:@"Quit"];
    [alert addButtonWithTitle:@"Cancel"];

    NSInteger result = [alert runModal];

    if (result == NSAlertFirstButtonReturn)
    {
        [self printFinalLogsAndQuit];
    }
}

- (instancetype)initWithFrame:(NSRect)frame target:(NSInteger)target name:(NSString *)name
{
    self = [super initWithFrame:frame];

    _targetSeconds = target;
    _timerName = name;
    _currentSeconds = 0; 
    _paused = NO;
    _sessionLogs = [[NSMutableArray alloc] init]; 
    
    self.wantsLayer = YES;

    // Log the startup event directly to the file immediately upon initialization
    NSString *startLine = [NSString stringWithFormat:@"[%@] Timer", _timerName];
    [self appendLogToFile:startLine];
    printf("%s\n", [startLine UTF8String]);

    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(tick)
                                            userInfo:nil
                                             repeats:YES];

    return self;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)tick
{
    if (!_paused)
    {
        _currentSeconds++;
    }

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithWhite:0.95 alpha:1.0] setFill];
    NSRectFill(self.bounds);

    NSInteger min = _currentSeconds / 60;
    NSInteger sec = _currentSeconds % 60;

    NSString *time =
        [NSString stringWithFormat:@"%02ld:%02ld%s",
        (long)min,
        (long)sec,
        _paused ? "*" : ""];

    NSMutableParagraphStyle *style =
        [[NSMutableParagraphStyle alloc] init];

    style.alignment = NSTextAlignmentCenter;

    NSColor *textColor = (_currentSeconds > _targetSeconds) ? 
                         [NSColor systemRedColor] : [NSColor darkGrayColor];

    NSDictionary *attrs =
    @{
        NSFontAttributeName :
            [NSFont fontWithName:@"Menlo"
                            size:self.bounds.size.height * 0.55],

        NSForegroundColorAttributeName :
            textColor,

        NSParagraphStyleAttributeName :
            style
    };

    NSSize size = [time sizeWithAttributes:attrs];

    NSRect textRect = NSMakeRect(
        0,
        (self.bounds.size.height - size.height)/2,
        self.bounds.size.width,
        size.height
    );

    [time drawInRect:textRect withAttributes:attrs];
}

- (void)keyDown:(NSEvent *)event
{
    NSString *chars = event.charactersIgnoringModifiers;

    if ([chars isEqualToString:@" "])
    {
        _paused = !_paused;
        [self logLiveEvent:_paused ? @"Timer PAUSED" : @"Timer RUNNING"];
    }
    else if ([[chars lowercaseString] isEqualToString:@"r"])
    {
        [self recordSession];
        _currentSeconds = 0;
        _paused = NO;
        [self logLiveEvent:@"Timer RESET & RESTARTED"];
    }
    else if ([[chars lowercaseString] isEqualToString:@"f"])
    {
        [[self window] toggleFullScreen:nil];
    }
    else if ([[chars lowercaseString] isEqualToString:@"q"])
    {
        [self printFinalLogsAndQuit];
    }
    else if (event.keyCode == 53) 
    {
        if ((self.window.styleMask &
             NSWindowStyleMaskFullScreen) != 0)
        {
            [self.window toggleFullScreen:nil];
        }
    }

    [self setNeedsDisplay:YES];
}
@end

@interface DraggableWindow : NSWindow
@end

@implementation DraggableWindow
- (BOOL)canBecomeKeyWindow
{
    return YES;
}
@end

int main(int argc, const char *argv[])
{
    @autoreleasepool
    {
        int inputSeconds = 0;
        printf("Enter timer length (in seconds): ");
        
        if (scanf("%d", &inputSeconds) != 1 || inputSeconds <= 0) {
            printf("Invalid input. Defaulting to 3600 seconds (1 hour).\n");
            inputSeconds = 3600;
        }

        int c;
        while ((c = getchar()) != '\n' && c != EOF);

        char nameBuffer[256];
        printf("Enter timer name (e.g., Work, Break): ");
        if (fgets(nameBuffer, sizeof(nameBuffer), stdin) != NULL) {
            nameBuffer[strcspn(nameBuffer, "\n")] = 0; 
        } else {
            strcpy(nameBuffer, "Timer");
        }

        NSString *timerName = [NSString stringWithUTF8String:nameBuffer];
        if (timerName.length == 0) {
            timerName = @"Timer";
        }

        [NSApplication sharedApplication];

        NSRect frame = NSMakeRect(200, 200, 140, 50);

        DraggableWindow *window =
            [[DraggableWindow alloc]
                initWithContentRect:frame
                          styleMask:NSWindowStyleMaskBorderless
                            backing:NSBackingStoreBuffered
                              defer:NO];

        [window setLevel:NSStatusWindowLevel];
        [window setCollectionBehavior:
             NSWindowCollectionBehaviorCanJoinAllSpaces |
            NSWindowCollectionBehaviorFullScreenAuxiliary];

        [window setHidesOnDeactivate:NO];
        [window setOpaque:YES];
        [window setMovableByWindowBackground:YES];
        [window setTitleVisibility:NSWindowTitleHidden];
        [window makeKeyAndOrderFront:nil];

        TimerView *view =
            [[TimerView alloc] initWithFrame:frame target:inputSeconds name:timerName];

        [window setContentView:view];
        [window setOpaque:NO];
        [window setBackgroundColor:[NSColor clearColor]];
        [window makeFirstResponder:view];
        [window setReleasedWhenClosed:NO];
        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
    }

    return 0;
}