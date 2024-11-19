#include "pch.h"
#include "qcocoabutton_p.h"
#include "qcocoabutton.h"

@interface QCocoaButtonTarget : NSObject
{
@public
    std::function<void(void)> clickedPtr;
}
-(void)clicked;
- (id)initWithFunction:(std::function<void(void)>)f;
@end

@implementation QCocoaButtonTarget
- (id)initWithFunction:(std::function<void(void)>)f
{
    self = [super init];
    self->clickedPtr = f;

    return self;
}
-(void)clicked {
    Q_ASSERT(clickedPtr);
    if (clickedPtr)
        clickedPtr();
}
@end

CocoaButtonPrivate::CocoaButtonPrivate(QCocoaButton *parent, NSButton *customBtn)
    : _cocoaButton(parent)
{
    if (!customBtn)
        _nsButton = [[NSButton alloc] init];
    else
        _nsButton = customBtn;

    QCocoaButtonTarget *target = [[QCocoaButtonTarget alloc] initWithFunction:
        std::bind(&CocoaButtonPrivate::clicked, this) ];

    [_nsButton setTarget:target];
    [_nsButton setAction:@selector(clicked)];
}

CocoaButtonPrivate::~CocoaButtonPrivate()
{
    [[_nsButton target] release];
    [_nsButton setTarget:nil];

    [_nsButton release];
}

void CocoaButtonPrivate::setImage(NSImage *img)
{
    [_nsButton setImage: img];
}

void CocoaButtonPrivate::clicked()
{
    emit _cocoaButton->clicked(_cocoaButton->isChecked());
}

bool CocoaButtonPrivate::isSpecialButton() // no title and icon
{
    return (_cocoaButton->_bezelStyle == QCocoaButton::HelpButton ||
            _cocoaButton->_bezelStyle == QCocoaButton::Disclosure ||
            _cocoaButton->_bezelStyle == QCocoaButton::RoundedDisclosure);
}

void CocoaButtonPrivate::updateSize()
{
    [_nsButton sizeToFit];

    NSRect frame = [_nsButton frame];

    [_nsButton setFrame:frame];

    _cocoaButton->setFixedSize(NSWidth(frame), NSHeight(frame)); // on Mac buttons cannot be stretchable, it looks bad
}
