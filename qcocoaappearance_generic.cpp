#include "pch.h"
#include "qcocoaappearance.h"

QCocoaAppearance::Design QCocoaAppearance::design()
{
    return Design::Classic;
}

void QCocoaAppearance::installWindowContrast()
{
    // the window background contrast is a Liquid Glass matter, there's nothing to do here
}
