#import <Cocoa/Cocoa.h>

@interface TimerView : NSView
@property NSInteger currentSeconds;
@property NSInteger targetSeconds;
@property BOOL paused;
@property NSTimer *timer;
@end

@implementation TimerView
- (void)mouseDown:(NSEvent *)event
{
    _paused = !_paused;
    NSLog(@"Timer %s", _paused ? "PAUSED" : "RUNNING");
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
        [NSApp terminate:nil];
    }
}

// Updated Initializer to accept the target time
- (instancetype)initWithFrame:(NSRect)frame target:(NSInteger)target
{
    self = [super initWithFrame:frame];

    _targetSeconds = target;
    _currentSeconds = 0; // Start at 0 to count UP
    _paused = NO;
    
    self.wantsLayer = YES;

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
    // Count UP until we hit the target
    if (!_paused && _currentSeconds < _targetSeconds)
    {
        _currentSeconds++;
    }

    NSLog(@"paused=%d elapsed=%ld target=%ld",
          _paused,
          (long)_currentSeconds,
          (long)_targetSeconds);

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithWhite:0.95 alpha:1.0] setFill];
    NSRectFill(self.bounds);

    // Calculate minutes and seconds from the elapsed time
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

    NSDictionary *attrs =
    @{
        NSFontAttributeName :
            [NSFont fontWithName:@"Menlo"
                            size:self.bounds.size.height * 0.55],

        NSForegroundColorAttributeName :
            [NSColor darkGrayColor],

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
        NSLog(@"Timer %s", _paused ? "PAUSED" : "RUNNING");
    }
    else if ([[chars lowercaseString] isEqualToString:@"r"])
    {
        // Reset back to 0
        _currentSeconds = 0;
        _paused = NO;
    }
    else if ([[chars lowercaseString] isEqualToString:@"f"])
    {
        [[self window] toggleFullScreen:nil];
    }
    else if ([[chars lowercaseString] isEqualToString:@"q"])
    {
        [NSApp terminate:nil];
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
        // 1. Prompt the user for input in the terminal
        int inputSeconds = 0;
        printf("Enter timer length (in seconds): ");
        
        // 2. Read the input with basic validation
        if (scanf("%d", &inputSeconds) != 1 || inputSeconds <= 0) {
            printf("Invalid input. Defaulting to 3600 seconds (1 hour).\n");
            inputSeconds = 3600;
        }

        // 3. Now launch the GUI
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

        // 4. Pass the user's input into our custom view
        TimerView *view =
            [[TimerView alloc] initWithFrame:frame target:inputSeconds];

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