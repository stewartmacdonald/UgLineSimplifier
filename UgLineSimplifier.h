//
//  UgLineSimplifier.h
//  LineSimplify
//
//  Created by Stewart Macdonald on 27/11/2016.
//  Copyright © 2016 Ug Media. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MapKit;

@interface UgLineSimplifier : NSObject {
	
	
}

- (NSArray*)simplifyPoints:(NSArray*)points withTolerance:(CGFloat)tolerance andHighQuality:(BOOL)highestQuality;


@end
