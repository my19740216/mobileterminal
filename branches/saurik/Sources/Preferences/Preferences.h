//
//  Preferences.h
//  Terminal

#import <UIKit/UIKit.h>
#import <UIKit/UIFontChooser.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UISlider.h>
/* XXX: I hate this codebase*/
#define UIInterfaceOrientation int
#import <UIKit/UINavigationController.h>
#import <UIKit/UIPickerView.h>
#import <UIKit/UIPickerTableCell.h>
#import "Color.h"

@class MobileTerminal;
@class TerminalConfig;
@class ColorButton;
@class ColorTableCell;
@class PreferencesGroup;
@class PieView;
@class PieButton;
@class MenuView;
@class MenuButton;

//_______________________________________________________________________________

@interface UITable (PickerTableExtensions)
@end

@interface UIPickerView (PickerViewExtensions)
@end

//_______________________________________________________________________________

@interface FontChooser : UIView
{
	id delegate;
	
	NSArray * fontNames;
	
	UIPickerView * fontPicker;
	UITable * pickerTable;
	
	NSString * selectedFont;
}

- (id) initWithFrame: (struct CGRect)rect;
- (void) selectFont: (NSString*)font;
- (void) createFontList;
- (void) setDelegate:(id)delegate;

@end

//_______________________________________________________________________________

@interface FontView : UIPreferencesTable
{
	FontChooser * fontChooser;
	UISlider * sizeSlider;
	UISlider * widthSlider;
}

-(FontChooser*) fontChooser;
-(id) initWithFrame:(CGRect)frame;
-(void) selectFont:(NSString*)font size:(int)size width:(float)width;
-(void) sizeSelected:(UISlider*)control;
-(void) widthSelected:(UISlider*)control;

@end

//_______________________________________________________________________________

@interface ColorView : UIPreferencesTable
{
  id delegate;
  
  UIColor *color;
  
  ColorTableCell  * colorField;
  UISlider * redSlider;
  UISlider * greenSlider;
  UISlider * blueSlider;
  UISlider * alphaSlider;
}	

-(UIColor *) color;
-(void) setColor:(UIColor *)color;
-(void) setDelegate:(id)delegate;

@end

//_______________________________________________________________________________

@interface TerminalPreferences : UIPreferencesTable
{
	id                  fontButton;
  UITextField       * argumentField;
	UISlider   * widthSlider;
	UISlider   * autosizeSwitch;
	PreferencesGroup  * sizeGroup;
	UIPreferencesControlTableCell * widthCell;

  ColorButton * color0;
  ColorButton * color1;
  ColorButton * color2;
  ColorButton * color3;
  ColorButton * color4;

	TerminalConfig * config;
	int							 terminalIndex;
}

-(void) fontChanged;
-(id) initWithFrame:(CGRect)frame;
-(void) setTerminalIndex:(int)terminal;
-(void) autosizeSwitched:(UISlider*)control;
-(void) widthSelected:(UISlider*)control;

@end

//_______________________________________________________________________________

@interface GestureTableCell : UIPreferencesTableCell
{
  PieView * pieView;
}

- (id) initWithFrame:(CGRect)frame;
- (float) getHeight;

@end

//_______________________________________________________________________________

@interface GesturePreferences : UIPreferencesTable
{
  PreferencesGroup  * menuGroup;
  PieButton         * editButton;
  UITextField       * commandField;
  PieView           * pieView; 
  
  int swipes;
}

- (id) initWithFrame:(CGRect)frame swipes:(int)swipes;
- (void) pieButtonPressed:(PieButton*)button;
- (void) update;
- (PieView*) pieView;

@end

//_______________________________________________________________________________

@interface MenuTableCell : UIPreferencesTableCell
{
  MenuView * menu;
}

- (id) initWithFrame:(CGRect)frame;
- (float) getHeight;

@end

//_______________________________________________________________________________

@interface MenuPreferences : UIPreferencesTable
{
  PreferencesGroup  * menuGroup;
  MenuButton        * editButton;
  UITextField       * titleField;
  UITextField       * commandField;
  UIPreferencesControlTableCell * submenuControl;
  UISlider   * submenuSwitch;
  UIPushButton      * openSubmenu;
  MenuView          * menuView; 
}

- (id) initWithFrame:(CGRect)frame;
- (void) menuButtonPressed:(MenuButton*)button;
- (void) selectButtonAtIndex:(int)index;
- (void) update;
- (MenuView*) menuView;

@end

//_______________________________________________________________________________

@interface PreferencesController : UINavigationController 
{
	MobileTerminal			* application;
	
	UIPreferencesTable	* settingsView;
	UIView							* aboutView;
	FontView						* fontView;
	ColorView           * colorView;
  MenuPreferences     * menuView;
  GesturePreferences  * gestureView;
  GesturePreferences	* longSwipeView;
  GesturePreferences	* twoFingerSwipeView;
  
	TerminalPreferences				* terminalView;

	UIPreferencesTextTableCell * terminalButton1;
	UIPreferencesTextTableCell * terminalButton2;
	UIPreferencesTextTableCell * terminalButton3;
	UIPreferencesTextTableCell * terminalButton4;
		
	PreferencesGroup * terminalGroup;

	int terminalIndex;
}

+(PreferencesController*) sharedInstance;

-(id) init;
-(void) initViewStack;

-(FontView*) fontView;
-(ColorView*) colorView;
-(TerminalPreferences*) terminalView;
-(MenuPreferences*) menuView;
-(GesturePreferences*) gestureView;
-(GesturePreferences*) longSwipeView;
-(GesturePreferences*) twoFingerSwipeView;
-(UIPreferencesTable*) settingsView;

-(void) setFontSize:(int)size;
-(void) setFontWidth:(float)width;
-(void) setFont:(NSString*)font;

-(id) aboutView;

@end

