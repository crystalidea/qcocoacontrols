/* you can use this code to extend QCocoaSlider functionality by modifying the existing class (QCocoaSlider)
we do not include animateToValue (and Quartz framework dependency) in QCocoaSlider at the moment
*/

#import <Quartz/Quartz.h>

@interface NSSlider (Extension)

+ (id)defaultAnimationForKey:(NSString *)key;

@end

@implementation NSSlider (Extension)

/* This method is part of the NSAnimatablePropertyContainer which is adopted by NSView (and hence all its
 * subclasses.  It is used to retrieve the default animation that should be performed to animate a given
 * property. If no default animation is provided, the property is not considered implicitly animatable.
 *
 * By default NSSlider does not provide an implicit animation for its "intValue" property.  So, we will
 * provide one with this category thus making the "intValue" animatable.
 */
+ (id)defaultAnimationForKey:(NSString *)key
{
    if ([key isEqualToString:@"intValue"]) {
        // By default, use simple linear interpolation.
        return [CABasicAnimation animation];
    }
    /* You may wish to add handlers here for the other many properties that can affect a slider's value
     * such as intValue, doubleValue, ... */
    else {
        // Defer to super's implementation for any keys we don't specifically handle.
        return [super defaultAnimationForKey:key];
    }
}

@end


void QCocoaSlider::animateToValue(int value)
{
    // create a new animation context so we can adjust the duration
    [NSAnimationContext beginGrouping];

    [[NSAnimationContext currentContext] setDuration:1.0];

    /* Core Animation is unaware of the slider's min and max value and will
    * setup the animation timing as if it were going to be able to
    * move the slider the full way.  If the user enters a value such as
    * 1000 in the text field, the resulting animation will be much faster
    * than if the user entered 100.
    * To work around this we enforce the min/max values ourself before
    * passing them to Core Animation. */
    value = (value > [pimpl->nsSlider maxValue]) ? [pimpl->nsSlider maxValue] : value;
    value = (value < [pimpl->nsSlider minValue]) ? [pimpl->nsSlider minValue] : value;

    // available on 10.7 and later
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        setValue(value);
    }];

    // set the new value on the animator proxy, triggering the animation
    [[pimpl->nsSlider animator] setIntValue:value ];

    [NSAnimationContext endGrouping];
}
