//
// Preferences.m
// Terminal

#import "Preferences.h"

#import <UIKit/UIKit.h>

#import <UIKit/UISimpleTableCell.h>
#import <UIKit/UIFieldEditor.h>

#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UIOldSliderControl.h>
/* XXX: I hate this codebase */
#define UIInterfaceOrientation int
#import <UIKit/UIPickerView.h>
#import <UIKit/UIPickerTableCell.h>

#import "MobileTerminal.h"
#import "Settings.h"
#import "PTYTextView.h"
#import "Constants.h"
#import "Color.h"
#import "Menu.h"
#import "PieView.h"
#import "Log.h"

#import "ColorWidgets.h"
#import "PreferencesGroup.h"
#import "PreferencesDataSource.h"


#if 0
@interface UITable(PickerTableExtensions)
@end

@implementation UITable(PickerTableExtensions)

- (void)_selectRow:(int)row byExtendingSelection:(BOOL)extend withFade:(BOOL)fade scrollingToVisible:(BOOL)scroll withSelectionNotifications:(BOOL)notify
{
    if (row >= 0) {
        [[[self selectedTableCell] iconImageView] setFrame:CGRectMake(0,0,0,0)];
        [super _selectRow:row byExtendingSelection:extend withFade:fade scrollingToVisible:scroll withSelectionNotifications:notify];
        [[[self selectedTableCell] iconImageView] setFrame:CGRectMake(0,0,0,0)];
    }
}

@end
#endif

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface UIPickerView (PickerViewExtensions)
@end

@implementation UIPickerView (PickerViewExtensions)

- (float)tableRowHeight
{
    return 22.0f;
}

- (void)_sendSelectionChanged
{
    for (int c = 0; c < [self numberOfColumns]; c++) {
        UITable *table = [self tableForColumn:c];
        for (int r = 0; r < [table numberOfRows]; r++)
            [[[table cellAtRow:r column:0] iconImageView] setFrame:CGRectMake(0,0,0,0)];
    }

    if ([self delegate])
        if ([[self delegate] respondsToSelector:@selector(fontSelectionDidChange)])
               [[self delegate] performSelector:@selector(fontSelectionDidChange)];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface FontChooser : UIView
{
    id delegate;

    NSArray *fontNames;

    UIPickerView *fontPicker;
    UITable *pickerTable;

    NSString *selectedFont;
}

- (id)initWithFrame:(struct CGRect)rect;
- (void)selectFont:(NSString *)font;
- (void)createFontList;
- (void)setDelegate:(id)delegate;

@end

@implementation FontChooser

- (id)initWithFrame:(struct CGRect)rect
{
    self = [super initWithFrame:rect];
    if (self) {
        [self createFontList];

        fontPicker = [[UIPickerView alloc] initWithFrame:[self bounds]];
        [fontPicker setDelegate:self];

        //pickerTable = [fontPicker createTableWithFrame:[self bounds]];
        //[pickerTable setAllowsMultipleSelection:FALSE];

        UITableColumn *fontColumn = [[UITableColumn alloc] initWithTitle: @"Font" identifier:@"font" width:rect.size.width];

        [fontPicker columnForTable:fontColumn];

        [self addSubview:fontPicker];
    }

    return self;
}

- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (id)delegate
{
    return delegate;
}

- (void)createFontList
{
    NSFileManager *fm = [NSFileManager defaultManager];

    // hack to make compiler happy
    // what could have been easy like:
    // fontNames = [[fm directoryContentsAtPath:@"/var/Fonts" matchingExtension:@"ttf" options:0 keepExtension:NO] retain];
    // now becomes:
    SEL sel = @selector(directoryContentsAtPath:matchingExtension:options:keepExtension:);
    NSMethodSignature *sig = [[fm class] instanceMethodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    NSString *path = @"/System/Library/Fonts/Cache";
    NSString *ext = @"ttf";
    int options = 0;
    BOOL keep = NO;
    [invocation setArgument:&path atIndex:2];
    [invocation setArgument:&ext atIndex:3];
    [invocation setArgument:&options atIndex:4];
    [invocation setArgument:&keep atIndex:5];
    [invocation setTarget:fm];
    [invocation setSelector:sel];
    [invocation invoke];
    [invocation getReturnValue:&fontNames];
    [fontNames retain];
    // hack ends here
}

- (int)numberOfColumnsInPickerView:(UIPickerView *)picker
{
    return 1;
}

- (int)pickerView:(UIPickerView *)picker numberOfRowsInColumn:(int)col
{
    return [fontNames count];
}

- (UIPickerTableCell *)pickerView:(UIPickerView *)picker tableCellForRow:(int)row inColumn:(int)col
{
    UIPickerTableCell *cell = [[UIPickerTableCell alloc] init];

    if (col == 0) {
        [cell setTitle:[fontNames objectAtIndex:row]];
    }

    [[cell titleTextLabel] setFont:[UISimpleTableCell defaultFont]];
    [cell setSelectionStyle:0];
    [cell setShowSelection:YES];
    [[cell iconImageView] setFrame:CGRectMake(0,0,0,0)];

    return cell;
}

- (float)pickerView:(UIPickerView *)picker tableWidthForColumn:(int)col
{
    return [self bounds].size.width-40.0f;
}

- (int)rowForFont:(NSString *)fontName
{
    int i;
    for (i = 0; i < [fontNames count]; i++) {
        if ([[fontNames objectAtIndex:i] isEqualToString:fontName]) {
            return i;
        }
    }
    return 0;
}

- (void)selectFont:(NSString *)fontName
{
    selectedFont = fontName;
    int row = [self rowForFont:fontName];
    [fontPicker selectRow:row inColumn:0 animated:NO];
    [[fontPicker tableForColumn:0] _selectRow:row byExtendingSelection:NO withFade:NO scrollingToVisible:YES withSelectionNotifications:YES];
}

- (NSString *)selectedFont
{
    int row = [fontPicker selectedRowForColumn:0];
    return [fontNames objectAtIndex:row];
}

- (void)fontSelectionDidChange
{
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(setFont:)])
                              [[self delegate] performSelector:@selector(setFont:) withObject:[self selectedFont]];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface FontPage : UIViewController
{
    UIPreferencesTable *table;

    FontChooser *fontChooser;
    UIOldSliderControl *sizeSlider;
    UIOldSliderControl *widthSlider;
}

- (FontChooser *)fontChooser;
- (void)selectFont:(NSString *)font size:(int)size width:(float)width;
- (void)sizeSelected:(UIOldSliderControl *)control;
- (void)widthSelected:(UIOldSliderControl *)control;

@end

@implementation FontPage

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"Font"];
    }
    return self;
}

- (void)loadView
{
    PreferencesDataSource *prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *group;

    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    group.titleHeight = 220;
    [prefSource addGroup:group];

    CGSize screenSize = [UIHardware mainScreenSize];
    CGRect chooserRect = CGRectMake(0, 0, screenSize.width, 210);
    fontChooser = [[FontChooser alloc] initWithFrame:chooserRect];
    [fontChooser setDelegate:self];

    UIPreferencesControlTableCell *cell;
    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    cell = [group addIntValueSlider:@"Size" range:NSMakeRange(7, 13) target:self action:@selector(sizeSelected:)];
    sizeSlider = [cell control];
    cell = [group addFloatValueSlider:@"Width" minValue:0.5f maxValue:1.0f target:self action:@selector(widthSelected:)];
    widthSlider = [cell control];
    [prefSource addGroup:group];

    table = [[UIPreferencesTable alloc]
        initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];

    [table addSubview:fontChooser];
    [table setDataSource:prefSource];
    [table reloadData];
    [self setView:table];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];

    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    TerminalConfig *config = [[[Settings sharedInstance] terminalConfigs]
        objectAtIndex:[PreferencesController sharedInstance].terminalIndex];

    [self selectFont:[config font]
                size:[config fontSize] width:[config fontWidth]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    int index = [PreferencesController sharedInstance].terminalIndex;
    MobileTerminal *app = [MobileTerminal application];

    if (index < [[app textviews] count])
        [[[app textviews] objectAtIndex:index] resetFont];
}

#pragma mark Other

- (void)selectFont:(NSString *)font size:(int)size width:(float)width
{
    [fontChooser selectFont:font];
    [sizeSlider setValue:(float)size];
    [widthSlider setValue:width];
}

- (void)sizeSelected:(UIOldSliderControl *)control
{
    [control setValue:floor([control value])];
    [self setFontSize:(int)[control value]];
}

- (void)widthSelected:(UIOldSliderControl *)control
{
    [self setFontWidth:[control value]];
}

- (FontChooser *)fontChooser { return fontChooser; };

#pragma mark FontChooser delegate methods

- (void)setFontSize:(int)size
{
    TerminalConfig *config = [[[Settings sharedInstance] terminalConfigs]
        objectAtIndex:[PreferencesController sharedInstance].terminalIndex];
    [config setFontSize:size];
}

- (void)setFontWidth:(float)width
{
    TerminalConfig *config = [[[Settings sharedInstance] terminalConfigs]
        objectAtIndex:[PreferencesController sharedInstance].terminalIndex];
    [config setFontWidth:width];
}

- (void)setFont:(NSString *)font
{
    TerminalConfig *config = [[[Settings sharedInstance] terminalConfigs]
        objectAtIndex:[PreferencesController sharedInstance].terminalIndex];
    [config setFont:font];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface ColorPage : UIViewController
{
    UIPreferencesTable *table;

    id delegate;

    UIColor *color;

    ColorTableCell *colorField;
    UIOldSliderControl *redSlider;
    UIOldSliderControl *greenSlider;
    UIOldSliderControl *blueSlider;
    UIOldSliderControl *alphaSlider;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, retain) UIColor *color;

@end

@implementation ColorPage

@synthesize color;

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"Colors"];
    }
    return self;
}

- (void)loadView
{
    PreferencesDataSource *prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *group;

    group = [PreferencesGroup groupWithTitle:@"Color" icon:nil];
    colorField = [group addColorField];
    [prefSource addGroup:group];

    group = [PreferencesGroup groupWithTitle:@"Values" icon:nil];
    redSlider = [[group addFloatValueSlider:@"Red" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
    greenSlider = [[group addFloatValueSlider:@"Green" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
    blueSlider = [[group addFloatValueSlider:@"Blue" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
    [prefSource addGroup:group];

    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    alphaSlider = [[group addFloatValueSlider:@"Alpha" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
    [prefSource addGroup:group];

    // -------------------------------------------------------- the table itself

    CGSize screenSize = [UIHardware mainScreenSize];
    table = [[UIPreferencesTable alloc]
        initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [table setDataSource:prefSource];
    [table reloadData];
    [self setView:table];
}

- (void)dealloc
{
    [color release];
    [super dealloc];
}

- (void)sliderChanged:(id)slider
{
    UIColor *c = colorWithRGBA([redSlider value], [greenSlider value], [blueSlider value], [alphaSlider value]);
    if (color != c) {
        [color release];
        color = [c retain];

        [colorField setColor:color];

        if ([self delegate] && [[self delegate] respondsToSelector:@selector(colorChanged:)]) {
                     NSArray *colorArray = [NSArray arrayWithColor:color];
                     [[self delegate] performSelector:@selector(colorChanged:) withObject:colorArray];
        }
    }
}

#pragma mark Properties

- (id)delegate
{
    return [table delegate];
}

- (void)setDelegate:(id)delegate
{
    [table setDelegate:delegate];
}

- (void)setColor:(UIColor *)color_
{
    if (color != color_) {
        [color release];
        color = [color_ retain];
        [colorField setColor:color];

        const CGFloat *rgba = CGColorGetComponents([color CGColor]);
        [redSlider setValue:rgba[0]];
        [greenSlider setValue:rgba[1]];
        [blueSlider setValue:rgba[2]];
        [alphaSlider setValue:rgba[3]];
    }
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface TerminalPrefsPage : UIViewController
{
    UIPreferencesTable *table;

    id fontButton;
    UITextField *argumentField;
    UIOldSliderControl *widthSlider;
    UISwitch *autosizeSwitch;
    PreferencesGroup *sizeGroup;
    UIPreferencesControlTableCell *widthCell;

    ColorButton *color0;
    ColorButton *color1;
    ColorButton *color2;
    ColorButton *color3;
    ColorButton *color4;

    TerminalConfig *config;
    int terminalIndex;
}

- (void)setTerminalIndex:(int)terminal;
- (void)autosizeSwitched:(UIOldSliderControl *)control;
- (void)widthSelected:(UIOldSliderControl *)control;

@end

@implementation TerminalPrefsPage

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"Terminal"];
    }
    return self;
}

- (void)loadView
{
    PreferencesDataSource *prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *group;

#if 0
    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    fontButton = [group addPageButton:@"Font"];
    [prefSource addGroup:group];

    sizeGroup = [PreferencesGroup groupWithTitle:@"Size" icon:nil];
    autosizeSwitch = [[sizeGroup addSwitch:@"Auto Adjust" target:self action:@selector(autosizeSwitched:)] control];
    widthCell = [sizeGroup addIntValueSlider:@"Width" range:NSMakeRange(40, 60) target:self action:@selector(widthSelected:)];
    widthSlider = [widthCell control];
    [prefSource addGroup:sizeGroup];

    group = [PreferencesGroup groupWithTitle:@"Arguments" icon:nil];
    argumentField = [[group addTextField:nil value:nil] textField];
    //[argumentField setEditingDelegate:self];
    [prefSource addGroup:group];

    group = [PreferencesGroup groupWithTitle:@"Colors" icon:nil];
    color0 = [group addColorPageButton:@"Background" colorRef:nil];
    color1 = [group addColorPageButton:@"Normal Text" colorRef:nil];
    color2 = [group addColorPageButton:@"Bold Text" colorRef:nil];
    color3 = [group addColorPageButton:@"Cursor Text" colorRef:nil];
    color4 = [group addColorPageButton:@"Cursor Background" colorRef:nil];
    [prefSource addGroup:group];
#endif

    // -------------------------------------------------------- the table itself

    CGSize screenSize = [UIHardware mainScreenSize];
    table = [[UIPreferencesTable alloc]
        initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [table enableRowDeletion:YES animated:YES];
    [self setView:table];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
#if 0
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
    [fontButton setValue:[config fontDescription]];
#endif
}

#pragma mark Other

- (BOOL)keyboardInput:(id)fieldEditor shouldInsertText:(NSString *)text isMarkedText:(BOOL)marked
{
    if ([text isEqualToString:@"\n"]) {
              [config setArgs:[argumentField text]];
              if ([table keyboard])
                  [table setKeyboardVisible:NO animated:YES];
    }
    return YES;
}

- (void)setTerminalIndex:(int)index
{
    [PreferencesController sharedInstance].terminalIndex = index;
    config = [[[Settings sharedInstance] terminalConfigs] objectAtIndex:index];

    [fontButton setValue:[config fontDescription]];
    [argumentField setText:[config args]];
    [autosizeSwitch setOn:[config autosize]];
    [widthSlider setValue:[config width]];
    if ([config autosize])
        [sizeGroup removeCell:widthCell];
    else if (![config autosize])
        [sizeGroup addCell:widthCell];

    [color0 setColorRef:&config.colors[0]];
    [color1 setColorRef:&config.colors[1]];
    [color2 setColorRef:&config.colors[2]];
    [color3 setColorRef:&config.colors[3]];
    [color4 setColorRef:&config.colors[4]];

    [table reloadData];
}

- (void)autosizeSwitched:(UIOldSliderControl *)control
{
    BOOL autosize = ([control value] == 1.0f);
    [config setAutosize:autosize];
    if (autosize)
        [sizeGroup removeCell:widthCell];
    else
        [sizeGroup addCell:widthCell];
    [table reloadData];
}

- (void)widthSelected:(UIOldSliderControl *)control
{
    [control setValue:floor([control value])];
    [config setWidth:(int)[control value]];
    [config setWidth:(int)[control value]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ([table keyboard])
        [table setKeyboardVisible:NO animated:NO];
}

#pragma mark Delegate methods

- (void)tableRowSelected:(NSNotification *)notification
{
#if 0
    int row = [[notification object] selectedRow];
    UIPreferencesTableCell *cell = [table cellAtRow:row column:0];
    if (cell == fontButton)
        [[self navigationController] pushViewController:[[[FontPage alloc]
                                        initWithNibName:nil bundle:nil] autorelease] animated:YES];
    else if (cell == color0) {
        ColorPage *cp = [[ColorPage alloc] initWithNib:nil bundle:nil];
        //[cp setColor:[color0
    }

    //[[self navigationController] pushViewController:newMenuPrefs animated:YES];
#if 0
    else if (cell == color1)
    else if (cell == color2)
    else if (cell == color3)
    else if (cell == color4)
#endif
#endif
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface MenuTableCell : UIPreferencesTableCell
{
    MenuView *menu;
}

@property(nonatomic, readonly) MenuView *menu;

@end

@implementation MenuTableCell

@synthesize menu;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setShowSelection:NO];
        menu = [[MenuView alloc] init];
        [menu setShowsEmptyButtons:YES];
        [menu loadMenu];
        [menu setOrigin:CGPointMake(70,30)];
        [self addSubview:menu];
    }
    return self;
}

- (void)dealloc
{
    [menu release];
    [super dealloc];
}

- (void)drawBackgroundInRect:(struct CGRect)fp8 withFade:(float)fp24
{
    [super drawBackgroundInRect: fp8 withFade: fp24];
    CGContextRef context = UICurrentContext();
    CGContextSaveGState(context);
    CGContextAddPath(context, [_fillPath _pathRef]);
    CGContextClip(context);
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextFillRect(context, fp8);
    CGContextRestoreGState(context);
}

#pragma mark UIPreferencesTableCell delegate methods

- (float)getHeight
{
    return [self frame].size.height;
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface MenuPrefsPage : UIViewController
{
    UIPreferencesTable *table;
    PreferencesDataSource *prefSource;

    Menu *menu;
    MenuView *menuView;
    MenuButton *editButton;

    UITextField *titleField;
    UIPreferencesTextTableCell *commandFieldCell;
    UIPreferencesControlTableCell *submenuSwitchCell;
    UISwitch *submenuSwitch;

    UIPushButton *openSubmenu;
}

@property(nonatomic, readonly) MenuView *menuView;

- (id)initWithMenu:(Menu *)menu_ title:(NSString *)title;
//- (void)menuButtonPressed:(MenuButton *)button;
//- (void)selectButtonAtIndex:(int)index;
//- (void)update;

@end

@implementation MenuPrefsPage

@synthesize menuView;

- (id)initWithMenu:(Menu *)menu_ title:(NSString *)title
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        menu = menu_;
        [self setTitle:(title ? title : @"Menu")];
    }
    return self;
}

- (void)loadView
{
    prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *menuGroup = [PreferencesGroup groupWithTitle:nil icon:nil];

    // ---------------------------------------------------- the menu button grid
 
    MenuTableCell *cell = [[MenuTableCell alloc] initWithFrame:CGRectMake(0, 0, 300, 235)];
    menuView = [cell menu];
    if (menu)
        [menuView loadMenu:menu];
    [menuView setDelegate:self];
    [menuGroup addCell:cell];

    // ------------------------------------------------- button title text field
 
    UIPreferencesTextTableCell *titleFieldCell = [menuGroup addTextField:@"Title" value:nil];
    [titleFieldCell setTarget:self];
    [titleFieldCell setReturnAction:@selector(onTextReturn)];
    [titleFieldCell setTextChangedAction:@selector(onTextChanged:)];
    titleField = [titleFieldCell textField];
    [titleField setPlaceholder:@"<button label>"];

    // ------------------------------------------------------ command text field
 
    commandFieldCell = [menuGroup addTextField:@"Command" value:nil];
    [commandFieldCell setTarget:self];
    [commandFieldCell setReturnAction:@selector(onCommandReturn)];
    UITextField *commandField = [commandFieldCell textField];
    [commandField setPlaceholder:@"<command to run>"];
    [commandField setReturnKeyType:9];

    // --------------------------------------------------- toggle submenu button
 
    submenuSwitchCell = [menuGroup addSwitch:@"Submenu" target:self action:@selector(submenuSwitched:)];
    [submenuSwitchCell setShowDisclosure:NO];
    [submenuSwitchCell setUsesBlueDisclosureCircle:YES];
    [submenuSwitchCell setDisclosureClickable:YES];
    submenuSwitch = [submenuSwitchCell control];

    [prefSource addGroup:menuGroup];

    // -------------------------------------------------------- the table itself
 
    CGSize screenSize = [UIHardware mainScreenSize];
    table = [[UIPreferencesTable alloc]
        initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [table setScrollingEnabled:NO];
    [self setView:table];

    // Select the first button in the button grid
#if 0
    [menuView selectButton:[menuView buttonAtIndex:0]];
    [self menuButtonPressed:[menuView buttonAtIndex:0]];
#endif
    [self selectButtonAtIndex:0];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];
    [prefSource release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Though this keyboard is not used for input, it still shows up
    [table setKeyboardVisible:NO animated:NO];
}

#pragma mark Other

- (void)selectButtonAtIndex:(int)index
{
    editButton = [[self menuView] buttonAtIndex:index];
    [menuView selectButton:editButton];
    [self update];
}

- (void)update
{
    BOOL isMenu = [editButton isMenuButton];
    BOOL isNavi = [editButton isNavigationButton];

    [titleField setText:[editButton title]];
    [commandFieldCell setUserInteractionEnabled:!isMenu];
    [[commandFieldCell textField] setText:[editButton commandString]];
    [submenuSwitch setOn:isMenu];
    [submenuSwitchCell setShowDisclosure:isNavi animated:YES];

    // Animate the enabling/disabling of the Submenu switch
    [UIView beginAnimations:@"slideSwitch"];
    if (isNavi) {
        [[submenuSwitchCell _disclosureView] addTarget:self action:@selector(openSubmenuAction) forEvents:64];
        [submenuSwitch setOrigin:CGPointMake(156.0f, 9.0f)];
    } else {
        [submenuSwitch setOrigin:CGPointMake(206.0f, 9.0f)];
    }
    [UIView endAnimations];

    [table reloadData];
}

# pragma mark MenuView delegate methods

- (BOOL)shouldLoadMenuWithButton:(MenuButton *)button
{
    return NO;
}

- (void)menuButtonPressed:(MenuButton *)button
{
    editButton = button;
    [self update];
}

#pragma mark TextTableCell delegate methods

- (void)onTextChanged:(NSString *)text
{
    [editButton setTitle:text];
}

- (void)onTextReturn
{
    // Manually hide the table's keyboard if command field is disabled
    if ([editButton isMenuButton])
        [table setKeyboardVisible:NO animated:YES];
}

- (void)onCommandReturn
{
    // Manually hide the table's keyboard
    // NOTE: while the table's keyboard is not used for input (UITextField has
    //       its own), it is needed for making the table view auto-scroll
    [table setKeyboardVisible:NO animated:YES];

    NSString *text = [[commandFieldCell textField] text];
    [editButton setCommandString:[NSString stringWithString:text]];
    if ([editButton title] == nil || [[editButton title] length] == 0) {
        [editButton setTitle:text];
        [titleField setText:text];
    }

    [self update];
}

#pragma mark Submenu methods

- (void)submenuSwitched:(UISwitch *)control
{
    if ([control isOn])
        [Menu menuWithItem:[editButton item]];
    else
        [[editButton item] setSubmenu:nil];

    [editButton update];
    [self update];
}

- (void)openSubmenuAction
{
    MenuItem *item = [editButton item];
    MenuPrefsPage *newMenuPrefs = [[MenuPrefsPage alloc]
        initWithMenu:[item submenu] title:[item title]];
    [[self navigationController] pushViewController:newMenuPrefs animated:YES];
    [newMenuPrefs release];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface GestureTableCell : UIPreferencesTableCell
{
    PieView *pieView;
}

@property(nonatomic, readonly) PieView *pieView;

@end

@implementation GestureTableCell

@synthesize pieView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setShowSelection:NO];
        pieView = [[PieView alloc] initWithFrame:frame];
        [pieView setOrigin:CGPointMake(57, 10)];
        [self addSubview:pieView];
    }
    return self;
}

- (void)dealloc
{
    [pieView release];
    [super dealloc];
}

- (void)drawBackgroundInRect:(struct CGRect)fp8 withFade:(float)fp24
{
    [super drawBackgroundInRect: fp8 withFade: fp24];
    CGContextRef context = UICurrentContext();
    CGContextSaveGState(context);
    CGContextAddPath(context, [_fillPath _pathRef]);
    CGContextClip(context);
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextFillRect(context, fp8);
    CGContextRestoreGState(context);
}

#pragma mark UIPreferencesTableCell delegate methods

- (float)getHeight
{
    return [self frame].size.height;
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface GesturePrefsPage : UIViewController
{
    UIPreferencesTable *table;
    PreferencesDataSource *prefSource;

    PieView *pieView;
    PieButton *editButton;
    UITextField *commandField;

    int swipes;
}

@property(nonatomic, readonly) PieView *pieView;

- (id)initWithSwipes:(int)swipes_;

@end

@implementation GesturePrefsPage

@synthesize pieView;

- (id)initWithSwipes:(int)swipes_
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"Gestures"];
        swipes = swipes_;
    }
    return self;
}

- (void)loadView
{
    prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *menuGroup = [PreferencesGroup groupWithTitle:nil icon:nil];

    // --------------------------------------------------------- the gesture pie
 
    GestureTableCell *cell = [[GestureTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 235.0f)];
    pieView = [cell pieView];
    NSMutableDictionary * sg = [[Settings sharedInstance] swipeGestures];
    for (int i = 0; i < 8; i++) {
        NSString *command = [sg objectForKey:ZONE_KEYS[(i + 8 - 2) % 8 + swipes * 8]];
        if (command != nil)
            [[pieView buttonAtIndex:i] setCommand:command];
    }
    [pieView setDelegate:self];
    [menuGroup addCell:cell];

    // ------------------------------------------------------ command text field
 
    UIPreferencesTextTableCell *commandFieldCell = [menuGroup addTextField:@"Command" value:nil];
    [commandFieldCell setTarget:self];
    [commandFieldCell setTextChangedAction:@selector(onCommandChanged:)];
    [commandFieldCell setReturnAction:@selector(onCommandReturn)];
    commandField = [commandFieldCell textField];
    [commandField setPlaceholder:@"<command to run>"];
    [commandField setReturnKeyType:9];
    [prefSource addGroup:menuGroup];

    // ---------------------------------------------------------------- submenus
 
#if 0 // FIXME
    if (swipes == 0) {
        PreferencesGroup *group = [PreferencesGroup groupWithTitle:nil icon:nil];
        [group addPageButton:@"Long Swipes"];
        [group addPageButton:@"Two Finger Swipes"];
        [prefSource addGroup:group];

        group = [PreferencesGroup groupWithTitle:nil icon:nil];
        [group addColorPageButton:@"Gesture Frame Color" colorRef:[[Settings sharedInstance] gestureFrameColorRef]];
        [prefSource addGroup:group];
    }
#endif

    // -------------------------------------------------------- the table itself

    CGSize screenSize = [UIHardware mainScreenSize];
    table = [[UIPreferencesTable alloc]
        initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [self setView:table];

    [pieView selectButton:[pieView buttonAtIndex:2]];
    [self pieButtonPressed:[pieView buttonAtIndex:2]];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];
    [prefSource release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Though this keyboard is not used for input, it still shows up
    if ([table keyboard])
        [table setKeyboardVisible:NO animated:NO];

    Settings *settings = [Settings sharedInstance];
    for (int i = 0; i < 8; i++) {
        NSString *command = [[pieView buttonAtIndex:i] command];
        NSString *zone = ZONE_KEYS[(i + 8 - 2) % 8 + swipes * 8];
        [settings setCommand:command forGesture:zone];
    }
}

#pragma mark Other

- (void)update
{
    [commandField setText:[editButton commandString]];
    [table reloadData];
}

# pragma mark PieView delegate methods

- (void)pieButtonPressed:(PieButton *)button
{
    editButton = button;
    [self update];
}

#pragma mark TextTableCell delegate methods

- (void)onCommandChanged:(NSString *)text
{
    [editButton setTitle:text];
}

- (void)onCommandReturn
{
    // Manually hide the table's keyboard
    // NOTE: while the table's keyboard is not used for input (UITextField has
    //       its own), it is needed for making the table view auto-scroll
    [table setKeyboardVisible:NO animated:YES];

    NSString *text = [commandField text];
    [editButton setCommandString:[NSString stringWithString:text]];
    if ([editButton title] == nil || [[editButton title] length] == 0)
        [editButton setTitle:text];

    [self update];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface AboutPage : UIViewController
{
    UIPreferencesTable *table;
}
@end

@implementation AboutPage

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"About"];
    }
    return self;
}

- (void)loadView
{
    PreferencesDataSource *prefSource = [[[PreferencesDataSource alloc] init] retain];
    PreferencesGroup *group;

    group = [PreferencesGroup groupWithTitle:@"MobileTerminal" icon:nil];
    [group addValueField:@"Version" value:[NSString stringWithFormat:@"1.0 (%@)", SVN_VERSION]];
    [prefSource addGroup:group];

    group = [PreferencesGroup groupWithTitle:@"Homepage" icon:nil];
    [group addPageButton:@"code.google.com/p/mobileterminal"];
    [prefSource addGroup:group];

    group = [PreferencesGroup groupWithTitle:@"Contributors" icon:nil];
    [group addValueField:nil value:@"allen.porter"];
    [group addValueField:nil value:@"craigcbrunner"];
    [group addValueField:nil value:@"vaumnou"];
    [group addValueField:nil value:@"andrebragareis"];
    [group addValueField:nil value:@"aaron.krill"];
    [group addValueField:nil value:@"kai.cherry"];
    [group addValueField:nil value:@"elliot.kroo"];
    [group addValueField:nil value:@"validus"];
    [group addValueField:nil value:@"DylanRoss"];
    [group addValueField:nil value:@"lednerk"];
    [group addValueField:nil value:@"tsangk"];
    [group addValueField:nil value:@"joseph.jameson"];
    [group addValueField:nil value:@"gabe.schine"];
    [group addValueField:nil value:@"syngrease"];
    [group addValueField:nil value:@"maball"];
    [group addValueField:nil value:@"lennart"];
    [group addValueField:nil value:@"monsterkodi"];
    [group addValueField:nil value:@"saurik"];
    [group addValueField:nil value:@"ashikase"];
    [prefSource addGroup:group];

    CGSize screenSize = [UIHardware mainScreenSize];
    table = [[UIPreferencesTable alloc]
        initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [self setView:table];
    [table release];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
}

#pragma mark Delegate methods

- (void)tableRowSelected:(NSNotification *)notification
{
    if ( [[self view] selectedRow] == 3 )
        [[MobileTerminal application] openURL:
                         [NSURL URLWithString:@"http://code.google.com/p/mobileterminal/"]];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@interface PreferencesPage : UIViewController
{
    UIPreferencesTable *table;

    PreferencesGroup *terminalGroup;

    int terminalIndex;
    UIPreferencesTextTableCell *terminalButton1;
    UIPreferencesTextTableCell *terminalButton2;
    UIPreferencesTextTableCell *terminalButton3;
    UIPreferencesTextTableCell *terminalButton4;
}

@end

@implementation PreferencesPage

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"Preferences"];
        [[self navigationItem] setLeftBarButtonItem:
             [[UIBarButtonItem alloc] initWithTitle:@"Done" style:5
                target:[MobileTerminal application]
                action:@selector(togglePreferences)]];
    }
    return self;
}

- (void)loadView
{
    PreferencesDataSource *prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *group;

    // --------------------------------------------------------- menu & gestures

    group = [PreferencesGroup groupWithTitle:@"Menu & Gestures" icon:nil];
    [group addPageButton:@"Menu"];
    [group addPageButton:@"Gestures"];
    [prefSource addGroup:group];

    // --------------------------------------------------------------- terminals

    terminalGroup = [PreferencesGroup groupWithTitle:@"Terminals" icon:nil];

    BOOL multi = [[Settings sharedInstance] multipleTerminals];

    if (MULTIPLE_TERMINALS) {
        [terminalGroup addSwitch:@"Multiple Terminals"
                              on:multi
                          target:self
                          action:@selector(multipleTerminalsSwitched:)];
    }

    terminalButton1 = [terminalGroup addPageButton:@"Terminal 1"];

    if (MULTIPLE_TERMINALS) {
        terminalButton2 = [terminalGroup addPageButton:@"Terminal 2"];
        terminalButton3 = [terminalGroup addPageButton:@"Terminal 3"];
        terminalButton4 = [terminalGroup addPageButton:@"Terminal 4"];

        if (!multi) {
            [terminalGroup removeCell:terminalButton2];
            [terminalGroup removeCell:terminalButton3];
            [terminalGroup removeCell:terminalButton4];
        }
    }

    [prefSource addGroup:terminalGroup];

    // ------------------------------------------------------------------- about

    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    [group addPageButton:@"About"];
    [prefSource addGroup:group];

    // -------------------------------------------------------- the table itself

    CGSize screenSize = [UIHardware mainScreenSize];
    table = [[UIPreferencesTable alloc]
        initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [table enableRowDeletion:YES animated:YES];
    [self setView:table];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
}

#pragma mark Other

- (void)multipleTerminalsSwitched:(UISwitch *)control
{
    BOOL multi = [control isOn];
    [[Settings sharedInstance] setMultipleTerminals:multi];

    if (!multi) {
        [terminalGroup removeCell:terminalButton2];
        [terminalGroup removeCell:terminalButton3];
        [terminalGroup removeCell:terminalButton4];
    } else {
        [terminalGroup addCell:terminalButton2];
        [terminalGroup addCell:terminalButton3];
        [terminalGroup addCell:terminalButton4];
    }
    [table reloadData];
}

#pragma mark Delegate methods

- (void)tableRowSelected:(NSNotification *)notification
{
    int row = [[notification object] selectedRow];
    UIPreferencesTableCell *cell = [table cellAtRow:row column:0];
    if (cell) {
        NSString *title = [cell title];
        UIViewController *vc = nil;

        if ([title isEqualToString:@"Menu"])
            vc = [[MenuPrefsPage alloc] initWithMenu:nil title:nil];
        else if ([title isEqualToString:@"Gestures"])
            vc = [[GesturePrefsPage alloc] initWithSwipes:0];
        else if ([title isEqualToString:@"Long Swipes"])
            vc = [[GesturePrefsPage alloc]initWithSwipes:1];
        else if ([title isEqualToString:@"Two Finger Swipes"])
            vc = [[GesturePrefsPage alloc]initWithSwipes:2];
        else if ([title isEqualToString:@"About"])
            vc = [[AboutPage alloc] init];
        else {
            //terminalIndex = [[title substringFromIndex:9] intValue] - 1;
            //[[self terminalView] setTerminalIndex:terminalIndex];
            vc = [[TerminalPrefsPage alloc] init];
        }

        if (vc) {
            [[self navigationController] pushViewController:vc animated:YES];
            [vc release];
        }
    }
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

#if 0
- (void)_didFinishPoppingViewController
{
    UIView *topView = [[self topViewController] view];
    if (topView == menuView) {
        [menuView removeFromSuperview];
        [menuView autorelease];
        menuView = nil;
    } else if (topView == terminalView) {
        [terminalView removeFromSuperview];
        [terminalView autorelease];
        terminalView = nil;
    } else if (topView == gestureView) {
        [gestureView removeFromSuperview];
        [gestureView autorelease];
        gestureView = nil;
    } else if (topView == longSwipeView) {
        [longSwipeView removeFromSuperview];
        [longSwipeView autorelease];
        longSwipeView = nil;
    } else if (topView == twoFingerSwipeView) {
        [twoFingerSwipeView removeFromSuperview];
        [twoFingerSwipeView autorelease];
        twoFingerSwipeView = nil;
    }

    [super _didFinishPoppingViewController];
}

#endif

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation PreferencesController
@synthesize terminalIndex;

+ (PreferencesController *)sharedInstance
{
    static PreferencesController *instance = nil;
    if (instance == nil)
        instance = [[PreferencesController alloc] init];
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[self navigationBar] setBarStyle:1];

        UIViewController *prefsPage = [[PreferencesPage alloc] init];
        [self pushViewController:prefsPage animated:NO];
        [prefsPage release];
    }
    return self;
}

- (void)navigationBar:(id)bar buttonClicked:(int)button
{
    switch (button) {
        case 1: // Done
            [[MobileTerminal application] togglePreferences];
            break;
    }
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
