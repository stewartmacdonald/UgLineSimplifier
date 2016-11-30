//
//  UgLineSimplifier.m
//  LineSimplify
//
//  Created by Stewart Macdonald on 27/11/2016.
//  Copyright © 2016 Ug Media. All rights reserved.
//

#import "UgLineSimplifier.h"

@implementation UgLineSimplifier {
	
	
}

- (NSArray*)simplifyPoints:(NSArray*)points withTolerance:(CGFloat)tolerance andHighQuality:(BOOL)highestQuality {
	
	NSArray *newPoints = nil;
	
	if (points.count < 2) {
		NSLog(@"[UgLS simplifyPoints] fewer than 2 points");
		return points;
	} else {
		
		if (highestQuality == NO) {
			// quickly discard some points to reduce complexity
			newPoints = [self simplifyRadialDistanceForPoints:points withTolerance:(tolerance*tolerance)];
		}
		
		newPoints = [self simplifyDouglasPeuckerForPoints:points withTolerance:(tolerance*tolerance)];
		
	}	
	
	NSLog(@"[UgLS simplifyPoints] %d points simplified to %d points", points.count, newPoints.count);
	
	return newPoints;
	
}

/*
 function simplify($points, $tolerance = 1, $highestQuality = false) {
	if (count($points) < 2) return $points;
	
	$sqTolerance = $tolerance * $tolerance;
	if (!$highestQuality) {
 $points = simplifyRadialDistance($points, $sqTolerance);
	}
	$points = simplifyDouglasPeucker($points, $sqTolerance);
	return $points;
 }
*/

- (CGFloat)squareDistanceFromPoint:(CLLocationCoordinate2D)point1 toPoint:(CLLocationCoordinate2D)point2 {
	
	CGFloat dx = point1.longitude - point2.longitude;
	CGFloat dy = point1.latitude - point2.latitude;
	
	return dx * dx + dy + dy;
}

/*
 function getSquareDistance($p1, $p2) {
	$dx = $p1['x'] - $p2['x'];
	$dy = $p1['y'] - $p2['y'];
	return $dx * $dx + $dy * $dy;
 }
*/


- (CGFloat)getSquareSegmentDistanceBetweenPoint1:(CLLocationCoordinate2D)p
										  point2:(CLLocationCoordinate2D)p1
									   andPoint3:(CLLocationCoordinate2D)p2 {
	
	CGFloat x = p1.longitude;
	CGFloat y = p1.latitude;
	
	CGFloat dx = p2.longitude - x;
	CGFloat dy = p2.latitude - y;
	
	if (dx != 0 || dy != 0) {
		
		CGFloat t = ((p.longitude - x) * dx + (p.latitude - y) * dy) / (dx * dx + dy * dy);
		if (t > 1) {
			x = p2.longitude;
			y = p2.latitude;
		} else if (t > 0) {
			x += dx * t;
			y += dy * t;
		}
		
	}
	dx = p.longitude - x;
	dy = p.latitude - y;
	
	return dx * dx + dy * dy;
}

/*
function getSquareSegmentDistance($p, $p1, $p2) {
	$x = $p1['x'];
	$y = $p1['y'];
	$dx = $p2['x'] - $x;
	$dy = $p2['y'] - $y;
	if ($dx !== 0 || $dy !== 0) {
		$t = (($p['x'] - $x) * $dx + ($p['y'] - $y) * $dy) / ($dx * $dx + $dy * $dy);
		if ($t > 1) {
			$x = $p2['x'];
			$y = $p2['y'];
		} else if ($t > 0) {
			$x += $dx * $t;
			$y += $dy * $t;
		}
	}
	$dx = $p['x'] - $x;
	$dy = $p['y'] - $y;
	return $dx * $dx + $dy * $dy;
}
*/


- (NSArray*)simplifyRadialDistanceForPoints:(NSArray<CLLocation *>*)points withTolerance:(CGFloat)sqTolerance {
	
	NSInteger len = points.count;
	CLLocation *prevPoint = [points firstObject];
	NSMutableArray *newPoints = [NSMutableArray arrayWithObject:prevPoint];
	CLLocation *point = nil;
	
	for (int i = 1; i < len; i++) {
		point = [points objectAtIndex:i];
		if ([self squareDistanceFromPoint:point.coordinate toPoint:prevPoint.coordinate] > sqTolerance) {
			[newPoints addObject:point];
			prevPoint = point;
		}
	}
	if (prevPoint != point) {
		[newPoints addObject:point];
	}
	
	return [NSArray arrayWithArray:newPoints];
}
/*
function simplifyRadialDistance($points, $sqTolerance) { // distance-based simplification
	
	$len = count($points);
	$prevPoint = $points[0];
	$newPoints = array($prevPoint);
	$point = null;
	
	for ($i = 1; $i < $len; $i++) {
		$point = $points[$i];
		if (getSquareDistance($point, $prevPoint) > $sqTolerance) {
			array_push($newPoints, $point);
			$prevPoint = $point;
		}
	}
	if ($prevPoint !== $point) {
		array_push($newPoints, $point);
	}
	return $newPoints;
}
 */



- (NSArray*)simplifyDouglasPeuckerForPoints:(NSArray<CLLocation *>*)points withTolerance:(CGFloat)sqTolerance {
	
	NSInteger len = points.count;
	NSMutableArray *markers = [[NSMutableArray alloc] initWithCapacity:len];
	
	for (NSInteger i = 0; i < len; ++i) {
		[markers addObject:[NSNull null]];
	}
	
	NSInteger first = 0;
	NSInteger last = len - 1;
	
	NSMutableArray *firstStack = [[NSMutableArray alloc] init];
	NSMutableArray *lastStack = [[NSMutableArray alloc] init];
	NSMutableArray *newPoints = [[NSMutableArray alloc] init];
	[markers replaceObjectAtIndex:first withObject:@1];
	[markers replaceObjectAtIndex:last withObject:@1];
	
	//NSLog(@"markers: %@", markers);
	
	NSInteger index = 0;
	
	while (last) {
		CGFloat maxSqDist = 0;
		for (int i = first + 1; i < last; i++) {
			CGFloat sqDist = [self getSquareSegmentDistanceBetweenPoint1:[points objectAtIndex:i].coordinate
																  point2:[points objectAtIndex:first].coordinate
															   andPoint3:[points objectAtIndex:last].coordinate
			];
			
			//sqDist *= 1000000000;
			
			//NSLog(@"sqDist = %0.20f", sqDist);
			
			if (sqDist > maxSqDist) {
				index = i;
				maxSqDist = sqDist;
			}
		}
		
		
		
		if (maxSqDist > sqTolerance) {
			
			//NSLog(@"GREATER maxSqDist = %0.15f; sqTolerance = %0.15f", maxSqDist, sqTolerance);
			
			[markers replaceObjectAtIndex:index withObject:@1];
			
			[firstStack addObject:[NSNumber numberWithInteger:first]];
			[lastStack addObject:[NSNumber numberWithInteger:index]];
			[firstStack addObject:[NSNumber numberWithInteger:index]];
			[lastStack addObject:[NSNumber numberWithInteger:last]];
			
		} else {
			//NSLog(@"LOWER maxSqDist = %0.15f; sqTolerance = %0.15f", maxSqDist, sqTolerance);
		}
		//NSLog(@"firstStack: %@", firstStack);
		first = [[firstStack lastObject] integerValue];
		[firstStack removeLastObject];
		
		//NSLog(@"lastStack: %@", lastStack);
		last = [[lastStack lastObject] integerValue];
		[lastStack removeLastObject];
		
	}
	
	//NSLog(@"[UgSL simplifyDouglasPeuckerForPoints] markers: %@", markers);
	
	for (int i = 0; i < len; i++) {
		if (![[markers objectAtIndex:i] isKindOfClass:[NSNull class]]) {
			[newPoints addObject:[points objectAtIndex:i]];
		}
	}
	
	//NSLog(@"[UgSL simplifyDouglasPeuckerForPoints] newPoints.count: %d", newPoints.count);
	
	return [NSArray arrayWithArray:newPoints];

}

// simplification using optimized Douglas-Peucker algorithm with recursion elimination
/*
function simplifyDouglasPeucker($points, $sqTolerance) {
	$len = count($points);
	$markers = array_fill ( 0 , $len - 1, null);
	$first = 0;
	$last = $len - 1;
	$firstStack = array();
	$lastStack  = array();
	$newPoints  = array();
	$markers[$first] = $markers[$last] = 1;
	
    while ($last) {
		$maxSqDist = 0;
		for ($i = $first + 1; $i < $last; $i++) {
			$sqDist = getSquareSegmentDistance($points[$i], $points[$first], $points[$last]);
			if ($sqDist > $maxSqDist) {
				$index = $i;
				$maxSqDist = $sqDist;
			}
		}
		if ($maxSqDist > $sqTolerance) {
			$markers[$index] = 1;
			array_push($firstStack, $first);
			array_push($lastStack, $index);
			array_push($firstStack, $index);
			array_push($lastStack, $last);
		}
		$first = array_pop($firstStack);
		$last = array_pop($lastStack);
	}
	for ($i = 0; $i < $len; $i++) {
		if ($markers[$i]) {
			array_push($newPoints, $points[$i]);
		}
	}
	return $newPoints;
}
 */



@end
