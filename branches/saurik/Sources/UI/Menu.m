//
// Menu.m
// Terminal

#import "Menu.h"

#import <UIKit/UIControl-UIControlPrivate.h>
#import <UIKit/UIGradient.h>

#import "GestureView.h"
#import "Log.h"
#import "MobileTerminal.h"
#import "Settings.h"

@implementation MenuItem

- (id)initWithMenu:(Menu *)menu_
{
    self = [super init];
    menu = menu_;
    title = @"";
    command = @"";
    submenu = nil;

    return self;
}

- (int)index
{
    return [menu indexOfItem:self];
}

- (NSDictionary *)getDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];

    [dict setObject:title forKey:MENU_TITLE];
    [dict setObject:command forKey:MENU_CMD];
    if (submenu)
        [dict setObject:[submenu getArray] forKey:MENU_SUBMENU];

    return dict;
}

- (NSString *)commandString
{
    NSMutableString *str = [NSMutableString stringWithCapacity:64];
    [str setString:[self command]];
    int i = 0;
    while (STRG_CTRL_MAP[i].str) {
        int toLength = 0;
        while (STRG_CTRL_MAP[i].chars[toLength]) toLength++;
        NSString *from = [menu dotStringWithCommand:STRG_CTRL_MAP[i].str];
        NSString *to = [NSString stringWithCharacters:STRG_CTRL_MAP[i].chars length:toLength];

        [str replaceOccurrencesOfString:to withString:from options:0 range:NSMakeRange(0, [str length])];

        i++;
    }
    return str;
}

- (void)setCommandString:(NSString *)cmdString
{
    NSMutableString *cmd = [NSMutableString stringWithCapacity:64];
    [cmd setString:cmdString];

    int i = 0;
    while (STRG_CTRL_MAP[i].str) {
        int toLength = 0;
        while (STRG_CTRL_MAP[i].chars[toLength]) toLength++;
        NSString *from = [menu dotStringWithCommand:STRG_CTRL_MAP[i].str];
        NSString *to = [NSString stringWithCharacters:STRG_CTRL_MAP[i].chars length:toLength];

        [cmd replaceOccurrencesOfString:from withString:to options:0 range:NSMakeRange(0, [cmd length])];

        i++;
    }
    [self setCommand:cmd];
}

- (Menu *)menu { return menu; }
- (BOOL)hasSubmenu { return (submenu != nil); }
- (Menu *)submenu { return submenu; }

- (void)setSubmenu:(Menu *)submenu_
{
    [submenu release];
    submenu = [submenu_ retain];
}

- (NSString *)title { return title; }
- (void)setTitle:(NSString *)title_
{
    [title release];
    title = [title_ copy];
}

- (NSString *)command { return command; }
- (void)setCommand:(NSString *)command_
{
    [command release];
    command = [command_ copy];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation Menu

+ (Menu *)menuWithArray:(NSArray *)array
{
    int i;
    Menu *menu = [[[Menu alloc] init] autorelease];
    for (i = 0; i < 12; i++) {
        MenuItem *item = [[menu items] objectAtIndex:i];
        NSDictionary *dict = [array objectAtIndex:i];
        [item setTitle:[dict objectForKey:MENU_TITLE]];
        [item setCommand:[dict objectForKey:MENU_CMD]];
        NSArray *submenu = [dict objectForKey:MENU_SUBMENU];
        if (submenu) [item setSubmenu:[Menu menuWithArray:submenu]];
    }
    return menu;
}

+ (Menu *)menuWithItem:(MenuItem *)item
{
    Menu *menu = [Menu create];
    [item setSubmenu:menu];

    return menu;
}

+ (Menu *)create
{
    Menu *menu = [[Menu alloc] init];
    return menu;
}

- (id)init
{
    int i;
    self = [super init];
    items = [[NSMutableArray arrayWithCapacity:12] retain];
    for (i = 0; i < 12; i++) {
        [items addObject:[[MenuItem alloc] initWithMenu:self]];
    }

    unichar dotChar[1] = {0x2022};
    dot = [[NSString stringWithCharacters:dotChar length:1] retain];

    return self;
}

- (NSArray *)getArray
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:12];
    for (MenuItem *item in items) {
        [array addObject:[item getDict]];
    }
    return array;
}

- (NSString *)dotStringWithCommand:(NSString *)cmd
{
    return [NSString stringWithFormat:@"%@%@", dot, cmd];
}

- (NSArray *)items { return items; }
- (MenuItem *)itemAtIndex:(int)index { return [items objectAtIndex:index]; }
- (int)indexOfItem:(MenuItem *)item { return [items indexOfObjectIdenticalTo:item]; }

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation MenuButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    item = nil;
    CDAnonymousStruct10 buttonPieces = {
        .left = { .origin = { .x = 0.0f, .y = 0.0f }, .size = { .width = 12.0f, .height = MENU_BUTTON_HEIGHT } },
        .middle = { .origin = { .x = 12.0f, .y = 0.0f }, .size = { .width = 20.0f, .height = MENU_BUTTON_HEIGHT } },
        .right = { .origin = { .x = 32.0f, .y = 0.0f }, .size = { .width = 12.0f, .height = MENU_BUTTON_HEIGHT } },
    };

    [self setDrawContentsCentered: YES];
    [self setBackgroundSlices: buttonPieces];
    [self setAutosizesToFit:NO];
    [self setEnabled: YES];
    [self setOpaque:NO];

    [self setTitleColor:[UIColor blackColor] forState:0]; // normal
    [self setTitleColor:[UIColor whiteColor] forState:1]; // pressed
    [self setTitleColor:[UIColor whiteColor] forState:4]; // selected

    return self;
}

- (BOOL)isMenuButton
{
    return ([self submenu] != nil);
}

- (BOOL)isNavigationButton
{
    return ([self isMenuButton] || [[item command] isEqualToString:[[item menu] dotStringWithCommand:@"back"]]);
}

- (void)update
{
    if ([self isNavigationButton]) {
        NSString *normalImage = @"menu_button_gray.png";
        NSString *selectedImage = @"menu_button_darkgray.png";
        [self setPressedBackgroundImage: [UIImage imageNamed:selectedImage]];
        [self setBackground: [UIImage imageNamed:selectedImage] forState:4];
        [self setBackgroundImage: [UIImage imageNamed:normalImage]];
    } else {
        NSString *normalImage = @"menu_button_white.png";
        NSString *selectedImage = @"menu_button_blue.png";
        [self setPressedBackgroundImage: [UIImage imageNamed:selectedImage]];
        [self setBackground: [UIImage imageNamed:selectedImage] forState:4];
        [self setBackgroundImage: [UIImage imageNamed:normalImage]];
    }

    NSString *title = [item title];
    if (title == nil) title = [item command];
    if (title != nil) [super setTitle:title];
}

- (NSString *)command { return (item != nil) ? [item command] : nil; }
- (NSString *)commandString { return (item != nil) ? [item commandString] : nil; }
- (void)setCommandString:(NSString *)commandString
{
    if (item != nil) {
        [item setCommandString:commandString];
        [self update];
    }
}

- (NSString *)title { return (item != nil) ? [item title] : nil; }
- (void)setTitle:(NSString *)title
{
    if (item != nil) {
        [item setTitle:title];
        [self update];
    }
}

- (Menu *)submenu { return (item != nil) ? [item submenu] : nil; }

- (MenuItem *)item { return item; }
- (void)setItem:(MenuItem *)item_
{
    item = item_;
    [self update];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation MenuView

@synthesize visible;

+ (MenuView *)sharedInstance
{
    static MenuView *instance = nil;
    if (instance == nil) {
        instance = [[MenuView alloc] init];
        [instance loadMenu];
    }
    return instance;
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 4 *MENU_BUTTON_HEIGHT+4, 3 *MENU_BUTTON_WIDTH-4)];

    visible = YES;
    history = [[NSMutableArray arrayWithCapacity:5] retain];

    timer = nil;
    showsEmptyButtons = NO;
    activeButton = nil;

    [self setOpaque:NO];

    return self;
}

- (void)loadMenu:(Menu *)menu
{
    activeButton = nil;

    float x = 0.0f, y = 0.0f;

    while ([[self subviews] count]) [[[self subviews] lastObject] removeFromSuperview];

    for (MenuItem *item in [menu items]) {
        MenuButton *button = nil;

        NSString *command = [item command];

        if (showsEmptyButtons || [item hasSubmenu] || (command != nil && [command length] > 0)) {
            CGRect buttonFrame = CGRectMake(x, y, MENU_BUTTON_WIDTH, MENU_BUTTON_HEIGHT);
            button = [[[MenuButton alloc] initWithFrame:buttonFrame] autorelease];

            [button setItem:item];

            [button addTarget:self action:@selector(buttonPressed:) forEvents:64];

            [self addSubview:button];
        }

        if ([item index] % 3 == 2) {
            x = 0.0f;
            y += MENU_BUTTON_HEIGHT;
        } else {
            x += MENU_BUTTON_WIDTH;
        }
    }
}

- (void)clearHistory
{
    [history removeAllObjects];
}

- (void)popMenu
{
    if ([history count] > 1) [history removeLastObject];
    [self loadMenu:[history lastObject]];
}

- (void)pushMenu:(Menu *)menu
{
    [history addObject:menu];
    [self loadMenu:menu];
}

- (void)loadMenu
{
    [self clearHistory];
    [self pushMenu:[MobileTerminal menu]];
}

- (void)buttonPressed:(id)button
{
    if (button != activeButton) {
        //if (activeButton && (![activeButton isMenuButton] || [button isMenuButton]))
        [activeButton setSelected:NO];

        activeButton = button;
        [activeButton setSelected:YES];

        if ([self delegate] && [[self delegate] respondsToSelector:@selector(menuButtonPressed:)])
                                  [[self delegate] performSelector:@selector(menuButtonPressed:) withObject:activeButton];

        if ([activeButton isMenuButton]) {
            if ([self delegate] && [[self delegate] respondsToSelector:@selector(shouldLoadMenuWithButton:)])
                                 if (![[self delegate] performSelector:@selector(shouldLoadMenuWithButton:) withObject:activeButton])
                                     return;
            [self pushMenu:[activeButton submenu]];
        }
    }
}

- (void)deselectButton:(MenuButton *)button
{
    [button setSelected:NO];
    if (button == activeButton) activeButton = nil;
}

- (void)selectButton:(MenuButton *)button
{
    if (activeButton) [activeButton setSelected:NO];
    [button setSelected:YES];
    activeButton = button;
}

- (MenuButton *)buttonAtIndex:(int)index
{
    return [[self subviews] objectAtIndex:index];
}

- (void)handleTrackingAt:(CGPoint)point
{
    int i;
    for (i = 0; i < [[self subviews] count]; i++) {
        if (CGRectContainsPoint([[[self subviews] objectAtIndex:i] frame], point)) {
                                            [self buttonPressed:[[self subviews] objectAtIndex:i]];
                                            return;
        }
    }
    if (activeButton && ![activeButton isMenuButton]) {
        [activeButton setSelected:NO];
        activeButton = nil;
    }
}

- (NSString *)handleTrackingEnd
{
    [self hide];
    if (activeButton && ![activeButton isMenuButton]) {
        NSMutableString *command = [NSMutableString stringWithCapacity:32];
        [command setString:[activeButton command]];
        [command removeSubstring:[[MobileTerminal menu] dotStringWithCommand:@"keepmenu"]];
        [command removeSubstring:[[MobileTerminal menu] dotStringWithCommand:@"back"]];
        return command;
    }
    return nil;
}

- (void)showAtPoint:(CGPoint)p
{
    [self showAtPoint:p delay:MENU_DELAY];
}

- (void)showAtPoint:(CGPoint)p delay:(float)delay
{
    if (!visible) {
        [self stopTimer];
        location.x = p.x;
        location.y = p.y;
        timer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(fadeIn) userInfo:nil repeats:NO];
    }
}

- (void)fadeInAtPoint:(CGPoint)p
{
    [self stopTimer];
    location.x = p.x;
    location.y = p.y;
    [self fadeIn];
}

- (void)stopTimer
{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)fadeIn
{
    [self stopTimer];

    if (visible) return;

    activeButton = nil;
    [self loadMenu];

    CGRect frame = [[self superview] frame];

    float lx = MIN(frame.size.width - 3.0 * MENU_BUTTON_WIDTH, MAX(0, location.x - 1.5 * MENU_BUTTON_WIDTH));
    float ly = MIN(frame.size.height - 3.0 * MENU_BUTTON_HEIGHT, MAX(0, location.y - 1.5 * MENU_BUTTON_HEIGHT));

    visible = YES;
    tapMode = NO;
    [self setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
    [self setOrigin:CGPointMake(lx, ly)];
    [self setAlpha: 0.0f];

    [UIView beginAnimations:@"fadeIn"];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:MENU_FADE_IN_TIME];
    [self setAlpha:1.0f];
    [UIView endAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if ([animationID isEqualToString:@"fadeIn"] && [finished boolValue] == YES) {
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(menuFadedIn)]) {
                              [[self delegate] performSelector:@selector(menuFadedIn)];
    }
    }
}

- (void)hide
{
    [self hideSlow:NO];
    [self setDelegate:nil];
}

- (void)hideSlow:(BOOL)slow
{
    [self stopTimer];

    if (!visible) return;

    [UIView beginAnimations:@"fadeOut"];
    [UIView setAnimationDuration: slow ? MENU_SLOW_FADE_OUT_TIME : MENU_FADE_OUT_TIME];
    [self setTransform:CGAffineTransformMakeScale(0.01f, 0.01f)];
    [self setOrigin:CGPointMake([self frame].origin.x + [self frame].size.width/2, [self frame].origin.y + [self frame].size.height/2)];
    [self setAlpha:0.0f];
    [UIView endAnimations];

    visible = NO;
}

- (void)setTapMode:(BOOL)tapMode_
{
    tapMode = tapMode_;
}

- (void)drawRect:(struct CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    float w = rect.size.width;
    float h = rect.size.height;
    CGContextBeginPath (context);
    CGContextMoveToPoint(context,w/2, 0);
    CGContextAddArcToPoint(context, w, 0, w, h/2, 7);
    CGContextAddArcToPoint(context, w, h, w/2, h, 7);
    CGContextAddArcToPoint(context, 0, h, 0, h/2, 7);
    CGContextAddArcToPoint(context, 0, 0, w/2, 0, 7);
    CGContextClosePath (context);
    CGContextClip (context);

    float components[11] = { 0.5647f, 0.6f, 0.6275f, 1.0f, 0.0f,
        0.29f, 0.321f, 0.3651f, 1.0f, 1.0f, 0 };
    UIGradient *gradient = [[UIGradient alloc] initVerticalWithValues:(CDAnonymousStruct11 *)components];
    [gradient fillRect:rect];

    CGContextFlush(context);
}

- (id)delegate { return delegate; }
- (void)setDelegate:(id)delegate_ { delegate = delegate_; }

- (void)setShowsEmptyButtons:(BOOL)aBool { showsEmptyButtons = aBool; }

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
