#import "PreferencesGroup.h"

#import <UIKit/UIControl-UIControlPrivate.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIOldSliderControl.h>
#import <UIKit/UISwitch.h>

#import "Color.h"
#import "ColorWidgets.h"

@implementation PreferencesGroup

@synthesize title;
@synthesize titleHeight;

+ (id)groupWithTitle:(NSString *)title icon:(UIImage *)icon
{
    return [[PreferencesGroup alloc] initWithTitle:title icon:icon];
}

- (id)initWithTitle:(NSString *)title_ icon:(UIImage *)icon
{
    if ((self = [super init])) {
        title = [[[UIPreferencesTableCell alloc] init] retain];
        [title setTitle:title_];
        if (icon) [title setIcon:icon];
        titleHeight = ([title_ length] > 0) ? 40.0f : 14.0f;
        cells = [[NSMutableArray arrayWithCapacity:1] retain];
    }

    return self;
}

- (void)removeCell:(id)cell
{
    if ([cells containsObject:cell])
          [cells removeObject:cell];
}

- (void)addCell:(id)cell
{
    if (![cells containsObject:cell])
              [cells addObject:cell];
}

- (id)addSwitch:(NSString *)label
{
    return [self addSwitch:label on:NO target:nil action:nil];
}

- (id)addSwitch:(NSString *)label target:(id)target action:(SEL)action
{
    return [self addSwitch:label on:NO target:target action:action];
}

- (id)addSwitch:(NSString *)label on:(BOOL)on
{
    return [self addSwitch:label on:on target:nil action:nil];
}

- (id)addSwitch:(NSString *)label on:(BOOL)on target:(id)target action:(SEL)action
{
    UIPreferencesControlTableCell *cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setTitle:label];
    [cell setShowSelection:NO];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(206.0f, 9.0f, 96.0f, 48.0f)];
    [sw setOn:on];
    [sw addTarget:target action:action forEvents:64];
    [cell setControl:sw];
    [cells addObject:cell];
    return cell;
}

- (id)addMenuSwitch:(NSString *)label target:(id)target action:(SEL)action
{
    UIPreferencesControlTableCell *cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setTitle:label];
    [cell setShowSelection:NO];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(206.0f, 9.0f, 96.0f, 48.0f)];
    [sw setOn:NO];
    [sw addTarget:target action:action forEvents:64];
    [cell setControl:sw];
    [cells addObject:cell];
    return cell;
}

- (id)addIntValueSlider:(NSString *)label range:(NSRange)range target:(id)target action:(SEL)action
{
    UIPreferencesControlTableCell *cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setTitle:label];
    [cell setShowSelection:NO];
    UIOldSliderControl *sc = [[UIOldSliderControl alloc] initWithFrame:CGRectMake(100.0f, 1.0f, 200.0f, 40.0f)];
    [sc addTarget:target action:action forEvents:7|64];

    [sc setAllowsTickMarkValuesOnly:YES];
    [sc setNumberOfTickMarks:range.length+1];
    [sc setMinValue:range.location];
    [sc setMaxValue:NSMaxRange(range)];
    [sc setValue:range.location];
    [sc setShowValue:YES];
    [sc setContinuous:NO];

    [cell setControl:sc];
    [cells addObject:cell];
    return cell;
}

- (id)addFloatValueSlider:(NSString *)label minValue:(float)minValue maxValue:(float)maxValue target:(id)target action:(SEL)action
{
    UIPreferencesControlTableCell *cell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setTitle:label];
    [cell setShowSelection:NO];
    UIOldSliderControl *sc = [[UIOldSliderControl alloc] initWithFrame:CGRectMake(100.0f, 1.0f, 200.0f, 40.0f)];
    [sc addTarget:target action:action forEvents:7|64];

    [sc setAllowsTickMarkValuesOnly:NO];
    [sc setMinValue:minValue];
    [sc setMaxValue:maxValue];
    [sc setValue:minValue];
    [sc setShowValue:YES];
    [sc setContinuous:YES];

    [cell setControl:sc];
    [cells addObject:cell];
    return cell;
}

- (id)addPageButton:(NSString *)label
{
    return [self addPageButton:label value:nil];
}

- (id)addPageButton:(NSString *)label value:(NSString *)value
{
    UIPreferencesTextTableCell *cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setTitle:label];
    [cell setValue:value];
    [cell setShowDisclosure:YES];
    [cell setDisclosureClickable:NO];
    [cell setDisclosureStyle: 2];
    [[cell textField] setEnabled:NO];
    [cells addObject:cell];

#if 0 // FIXME
    [[cell textField] setTapDelegate:[PreferencesController sharedInstance]];
    [cell setTapDelegate:[PreferencesController sharedInstance]];
#endif

    return cell;
}

- (id)addColorPageButton:(NSString *)label colorRef:(UIColor **)color
{
    UIPreferencesTextTableCell *cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setTitle:label];
    [cell setShowDisclosure:YES];
    [cell setDisclosureClickable:NO];
    [cell setDisclosureStyle: 2];
    [[cell textField] setEnabled:NO];
    [cells addObject:cell];

    ColorButton *colorButton = [[ColorButton alloc] initWithFrame:CGRectMake(240,3,39,39) colorRef:color];
    [cell addSubview:colorButton];

    [colorButton setTapDelegate:colorButton];
    [[cell textField] setTapDelegate:colorButton];
    [cell setTapDelegate:colorButton];

    return colorButton;
}

- (id)addValueField:(NSString *)label value:(NSString *)value
{
    UIPreferencesTextTableCell *cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setTitle:label];
    [cell setValue:value];
    [[cell textField] setTextCentersHorizontally:YES];
    [[cell textField] setEnabled:NO];
    [cells addObject:cell];
    return cell;
}

- (id)addTextField:(NSString *)label value:(NSString *)value
{
    UIPreferencesTextTableCell *cell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setTitle:label];
    [cell setValue:value];
    [[cell textField] setTextCentersHorizontally:NO];
    [[cell textField] setEnabled:YES];
    [cells addObject:cell];
    return cell;
}

- (id)addColorField
{
    ColorTableCell *cell = [[ColorTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 48.0f)];
    [cell setDrawsBackground:NO];
    [cells addObject:cell];
    return cell;
}

- (int)rows
{
    return [cells count];
}

- (UIPreferencesTableCell *)row:(int)row
{
    if (row == -1) {
        return nil;
    } else {
        return [cells objectAtIndex:row];
    }
}

- (NSString *)stringValueForRow:(int)row
{
    UIPreferencesTextTableCell *cell = (UIPreferencesTextTableCell *)[self row:row];
    return [[cell textField] text];
}

- (BOOL)boolValueForRow:(int)row
{
    UIPreferencesControlTableCell *cell = (UIPreferencesControlTableCell *)[self row:row];
    UISwitch *sw = [cell control];
    return [sw isOn];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
