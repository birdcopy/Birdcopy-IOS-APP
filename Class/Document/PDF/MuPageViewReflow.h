#import <UIKit/UIKit.h>
#import "MuDocRef.h"
#import "MuPageView.h"

@interface MuPageViewReflow : UIWebView <UIWebViewDelegate,MuPageView>

-(id) initWithFrame:(CGRect)frame document:(MuDocRef *)aDoc page:(NSInteger)aNumber;

@property(nonatomic,assign) id  messagerDelegate;

@end
