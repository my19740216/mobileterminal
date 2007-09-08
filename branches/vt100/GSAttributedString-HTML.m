#import <Foundation/Foundation.h>
#import "GSAttributedString-HTML.h"
#import "TextStorageTerminal.h"
#import "Debug.h"

@implementation GSAttributedString (HTML)

NSString * cssForAttributes(NSDictionary *attr) {
    NSEnumerator *keyEnum = [attr keyEnumerator];
    NSString *key;
    id o;
    NSString *display = @"", *underline = @"", *background = @"", *foreground = @"", *bold = @"", *blink = @"";
    while ((key = [keyEnum nextObject]))
    {
        o = [attr objectForKey: key];
        if ([key isEqualToString: TSTInvisibleAttribute] && o && [(NSNumber*)o intValue])
            display = @"display: none;";
        else if ([key isEqualToString: GSUnderlineStyleAttributeName] && o && [(NSNumber*)o intValue])
            underline = @"text-decoration: underline;";
        else if ([key isEqualToString: GSBackgroundColorAttributeName]) {
            // don't paint the background if it's black 'cause it will cover up our shiny background graphic!
            if (![o isEqualToString: @"000000"])
                background = [NSString stringWithFormat: @"background-color: #%@;", o];
        }
        else if ([key isEqualToString: GSForegroundColorAttributeName])
            foreground = [NSString stringWithFormat: @"color: #%@;", o];
        else if ([key isEqualToString: TSTBoldAttribute] && o && [(NSNumber*)o intValue])
            bold = @"font-weight: bold;";
        else if ([key isEqualToString: TSTBlinkingAttribute] && o && [(NSNumber*)o intValue])
            blink = @"text-decoration: blink;";
    }
    return [NSString stringWithFormat: @"%@%@%@%@%@%@", display, underline, background, foreground, bold, blink];
}

-(NSString *)html {
    NSRange attrRange;
    NSDictionary *attr;
    NSString *plainstring = [self string];
    unsigned c = [plainstring length];
    NSMutableString *s = [NSMutableString stringWithString: @""], *substring;
    unsigned i = 0;
    while (i < c)
    {
//      DEBUG("range: start %d length %d\n", attrRange.location, attrRange.length);
        attr = [self attributesAtIndex:i effectiveRange:&attrRange];
        substring = [NSMutableString stringWithString: [plainstring substringWithRange: attrRange]];
        [substring replaceOccurrencesOfString: @"\n" withString: @"<br/>" options: 0 range: NSMakeRange(0, [substring length])];
        //[substring replaceOccurrencesOfString: @"\r" withString: @"<br/>" options: 0 range: NSMakeRange(0, [substring length])];
        [substring replaceOccurrencesOfString: @" " withString: @"&nbsp;" options: 0 range: NSMakeRange(0, [substring length])];
        [s appendFormat: @"<span style=\"%@\">%@</span>", cssForAttributes(attr), substring];
        i = NSMaxRange(attrRange);
    }
    [s appendString: @""];
    return s;// [self string];;
}
@end
