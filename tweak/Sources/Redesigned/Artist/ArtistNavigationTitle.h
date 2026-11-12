#import <Foundation/Foundation.h>

// UIKit 27 removes the title row when the string becomes empty. Spotify also
// changes the artist header's collapse progress when that row changes height.
// A non-drawing title keeps its layout slot; native title-attribute alpha still
// owns the fade. Never cache an artist's name or change a supplied nonempty title.
static inline NSString *SGRArtistStableNavigationTitle(NSString *title) {
    return title.length ? title : @"\u00a0";
}
